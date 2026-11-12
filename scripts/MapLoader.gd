extends Node2D

class_name MapLoader

@export var camara: Camera2D # Arrastra tu nodo Camera2D aquí desde el inspector
@export var selection_layer: TileMapLayer
@export var ground_layer: TileMapLayer
@export var water_layer: TileMapLayer
@export var veg_layer: TileMapLayer
@export var focos_layer: TileMapLayer
@export var gui_panel: Control # Arrastra el nodo PanelInfo (el que tiene el script anterior) aquí

@onready var panel_menu_master: Control = $CanvasLayer2/PanelContainer

var celda_actual_hover: Vector2i = Vector2i(9999, 9999) # Para evitar recálculos innecesarios por fotograma

# Coordenadas base en el TileSet maestro para cada tipo de contenido
const ATLAS_GRASS = Vector2i(0, 0)
const ATLAS_WATER = Vector2i(1, 0)
const ATLAS_TREE = Vector2i(2, 0)
const ATLAS_FOCO_INICIAL = Vector2i(0, 0)

# Diccionario maestro que traduce cada ID de tu JSON a la coordenada Vector2i en el TileSet
# (Ajusta estos Vector2i según dónde tengas ubicado cada sprite exactamente en tu imagen)
const MAPEO_IDS_ATLAS = {
	# Categorías de Suelo
	10: Vector2i(7, 2), # Arbustal_abierto
	11: Vector2i(0, 1), # Bosques_abiertos
	12: Vector2i(1, 1), # Bosques_cerrados
	13: Vector2i(7, 1), # Herbaceas_cerradas
	14: Vector2i(6, 2), # Pastizal_abierto
	15: Vector2i(8, 0), # Rocas
	
	# Categorías de Vegetación (si vienen mezcladas o separadas)
	20: Vector2i(2, 1), # Bosques de Lenga Puros
	21: Vector2i(2, 2), # Bosques de Ñire Puros
	22: Vector2i(2, 1), # Bosque Mixto
	23: Vector2i(3, 1), # Degradado de Lenga
	24: Vector2i(4, 1), # Degradado de Ñire
	25: Vector2i(5, 1), # Degradado Mixto
	
	# Otros elementos especiales
	40: Vector2i(1, 0), # Agua
	50: Vector2i(7, 0)  # Cerro / Montaña
}

# Estructura: ID: { nombre, temp, combustible, velocidad, humedad, es_elevado }
const CONFIG_TERRENO = {
	10: { "name": "Arbustal", "temp": 25.0, "fuel": 2.0, "speed": 0.8, "hum": 0.4, "elev": 0 },
	20: { "name": "Lenga Pura", "temp": 35.0, "fuel": 5.0, "speed": 1.2, "hum": 0.3, "elev": 1 },
	21: { "name": "Ñire Puro", "temp": 30.0, "fuel": 4.0, "speed": 1.1, "hum": 0.3, "elev": 1 },
	40: { "name": "Agua", "temp": 0.0, "fuel": 0.0, "speed": 0.0, "hum": 1.0, "elev": 0 },
	50: { "name": "Cerro", "temp": 10.0, "fuel": 1.0, "speed": 0.3, "hum": 0.5, "elev": 10 },
	# ... completar el resto de IDs ...
}

# Variable para guardar la referencia a los datos lógicos actuales
var mapa_datos_actual: GameMapData

@onready var panel_config_terrenos: PanelContainer = $CanvasLayer2/PanelContainer/VBox_MenuMaster/Panel_Config_Terrenos
@onready var panel_config_recursos: Control = $CanvasLayer2/PanelContainer/VBox_MenuMaster/Panel_Config_Recursos
@onready var panel_config_clima : PanelContainer = $CanvasLayer2/PanelContainer/VBox_MenuMaster/Panel_Config_Clima
@onready var panel_config_focos: PanelContainer = $CanvasLayer2/PanelContainer/VBox_MenuMaster/Panel_Config_Focos

var modo_seleccion_foco_activo: bool = false
var modo_borrador_foco_activo: bool = false

# Referencias a los componentes del panel de focos (ajusta las rutas según tu escena)
@onready var spin_box_q: SpinBox = $CanvasLayer2/PanelContainer/VBox_MenuMaster/Panel_Config_Focos/VBoxContainer/HBoxContainer/SpinBox_Q
@onready var spin_box_r: SpinBox = $CanvasLayer2/PanelContainer/VBox_MenuMaster/Panel_Config_Focos/VBoxContainer/HBoxContainer/SpinBox_R
@onready var item_list_focos: ItemList = $CanvasLayer2/PanelContainer/VBox_MenuMaster/Panel_Config_Focos/VBoxContainer/ItemList


func _ready() -> void:
	# 1. Desactivamos el proceso temporalmente para evitar llamadas al mouse antes de tiempo
	#set_process(false)
	item_list_focos.select_mode = ItemList.SELECT_MULTI
	# Limpiamos capas por seguridad al iniciar la escena
	ground_layer.clear()
	water_layer.clear()
	veg_layer.clear()
	
	# 2. Verificamos si hay un mapa listo para cargar en el GameManager
	if GameManager.mapa_a_cargar_ruta != "":
		var ruta_tres = GameManager.mapa_a_cargar_ruta
		print("Cargando mapa desde recurso .tres: ", ruta_tres)
		
		# Llamamos directamente a la función que lee el .tres y pinta la vista
		cargar_y_pintar_mapa_desde_archivo(ruta_tres)
		
		# Limpiamos la variable global
		#GameManager.mapa_a_cargar_ruta = ""
	else:
		print("Advertencia: No hay ruta de mapa definida en GameManager.")
	
	# Conectamos la señal del panel de configuración
	if panel_config_terrenos and panel_config_terrenos.has_signal("configuracion_guardada"):
		if not panel_config_terrenos.is_connected("configuracion_guardada", _aplicar_nueva_configuracion_global):
			panel_config_terrenos.connect("configuracion_guardada", _aplicar_nueva_configuracion_global)
	
	# B. Panel de Recursos (Asumiendo que creaste una variable @onready var panel_config_recursos)
	if panel_config_recursos and not panel_config_recursos.is_connected("recursos_guardados", _aplicar_nueva_configuracion_recursos):
		panel_config_recursos.connect("recursos_guardados", _aplicar_nueva_configuracion_recursos)
		
	# C. Panel de Clima
	if panel_config_clima:
		if not panel_config_clima.is_connected("clima_guardado", _aplicar_nueva_configuracion_clima):
			panel_config_clima.clima_guardado.connect(_aplicar_nueva_configuracion_clima)
			print("Señal 'clima_guardado' conectada exitosamente al MapLoader.")
		else:
			print("La señal 'clima_guardado' ya estaba conectada.")
	else:
		print("ERROR: panel_config_clima es NULL en el MapLoader. Revisa la ruta del nodo en el inspector.")
		
	# Conectar las señales del panel de focos al MapLoader
	if panel_config_focos:
		panel_config_focos.foco_agregado_manual.connect(_on_panel_foco_agregado_manual)
		panel_config_focos.foco_eliminado_lista.connect(_on_panel_foco_eliminado)
		panel_config_focos.modo_selector_toggled.connect(_on_btn_toggle_modo_foco_toggled)
		panel_config_focos.guardar_focos_solicitado.connect(_on_panel_guardar_focos)	
		panel_config_focos.modo_borrador_toggled.connect(_on_btn_toggle_borrador_foco_toggled)
		
func _process(_delta: float) -> void:
	# 1. Obtener la posición global del mouse
	var mouse_pos_global = get_global_mouse_position()
	
	# 2. Convertir la posición a coordenadas locales y de mapa
	var mouse_pos_local = ground_layer.to_local(mouse_pos_global)
	var celda_bajo_cursor = ground_layer.local_to_map(mouse_pos_local)
	
	# 3. Si cambiamos de celda respecto al fotograma anterior
	if celda_bajo_cursor != celda_actual_hover:
		celda_actual_hover = celda_bajo_cursor # Actualizamos inmediatamente la celda activa
		selection_layer.clear()
		
		#var source_id = -1
		#var atlas_coord = Vector2i.ZERO
		#var alt_id = 0
		var encontrada = false
		
		# --- BUSCAR DE ARRIBA HACIA ABAJO EN LAS CAPAS ---
		
		# A. ¿Hay vegetación o cerros en esta celda?
		if veg_layer.get_cell_source_id(celda_bajo_cursor) != -1:
			#source_id = veg_layer.get_cell_source_id(celda_bajo_cursor)
			#atlas_coord = veg_layer.get_cell_atlas_coords(celda_bajo_cursor)
			#alt_id = veg_layer.get_cell_alternative_tile_id(celda_bajo_cursor)
			encontrada = true
			
		# B. Si no hay vegetación, ¿hay agua?
		elif water_layer.get_cell_source_id(celda_bajo_cursor) != -1:
			#source_id = water_layer.get_cell_source_id(celda_bajo_cursor)
			#atlas_coord = water_layer.get_cell_atlas_coords(celda_bajo_cursor)
			#alt_id = water_layer.get_cell_alternative_tile_id(celda_bajo_cursor)
			encontrada = true
			
		# C. Si no hay agua ni vegetación, buscamos en el suelo base
		elif ground_layer.get_cell_source_id(celda_bajo_cursor) != -1:
			#source_id = ground_layer.get_cell_source_id(celda_bajo_cursor)
			#atlas_coord = ground_layer.get_cell_atlas_coords(celda_bajo_cursor)
			#alt_id = ground_layer.get_cell_alternative_tile_id(celda_bajo_cursor)
			encontrada = true
			
		# 4. Si encontramos algo en alguna de las capas, aplicamos la selección con recuadro naranja
		if encontrada:
			#celda_actual_hover = celda_bajo_cursor
			# Usamos Source ID 1 (tu atlas con el borde naranja) manteniendo la forma exacta de lo que esté debajo
			selection_layer.set_cell(celda_actual_hover, 2, Vector2i(0,0))
			
			
			# Actualizar el panel con los datos lógicos de CellData
			if mapa_datos_actual and mapa_datos_actual.cells_data.has(celda_bajo_cursor):
				var datos_celda: CellData = mapa_datos_actual.cells_data[celda_bajo_cursor]
				if gui_panel:
					gui_panel.actualizar(datos_celda)
			else:
				if gui_panel:
					gui_panel.limpiar()
			
		else:
			celda_actual_hover = Vector2i(9999, 9999)
			if gui_panel:
					gui_panel.limpiar()
	
func load_map_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		printerr("El archivo JSON no existe.")
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		printerr("Error al parsear el JSON: ", json.get_error_message())
		return
		
	var map_data = json.get_data()
	
	# Recorremos cada celda definida en el JSON
	for cell in map_data["cells"]:
		var coord = Vector2i(cell["q"], cell["r"])
		
		# 1. Lógica para la capa de Suelo / Agua según el terreno
		if cell["terrain"] == "grass":
			ground_layer.set_cell(coord, 0, ATLAS_GRASS)
		elif cell["terrain"] == "water":
			water_layer.set_cell(coord, 0, ATLAS_WATER)
			
		# 2. Lógica para la capa de Vegetación
		if cell["veg"] == "tree_pine":
			# Aquí podrías usar alternative_tiles si tienes varios tipos de árboles
			veg_layer.set_cell(coord, 0, ATLAS_TREE)


# --- GUARDAR EL MAPA ACTUAL ---
func guardar_mapa(ruta_archivo: String) -> void:
	var datos_guardado = SaveData.new()
	datos_guardado.map_width = 300  # O el ancho real de tu mapa
	datos_guardado.map_height = 100 # O el alto real de tu mapa
	
	# Recorres las capas de Godot y guardas qué celdas están ocupadas y sus datos
	datos_guardado.saved_cells.clear()
	
	# Ejemplo recopilando celdas de la capa de suelo
	for coord in ground_layer.get_used_cells():
		var atlas_coord = ground_layer.get_cell_atlas_coords(coord)
		var source_id = ground_layer.get_cell_source_id(coord)
		var alt_id = ground_layer.get_cell_alternative_tile_id(coord)
		
		datos_guardado.saved_cells.append({
			"q": coord.x,
			"r": coord.y,
			"source": source_id,
			"atlas": atlas_coord,
			"alt": alt_id
		})
		
	# Guarda el recurso directamente en disco en formato de Godot (.tres o .res)
	ResourceSaver.save(datos_guardado, ruta_archivo)
	print("¡Mapa guardado exitosamente en: ", ruta_archivo)

# --- CARGAR EL MAPA DESDE EL ARCHIVO ---
func cargar_mapa(ruta_archivo: String) -> void:
	if not ResourceLoader.exists(ruta_archivo):
		printerr("El archivo de guardado no existe.")
		return #id_return
		
	# Cargamos el recurso en memoria
	var datos_guardado = ResourceLoader.load(ruta_archivo) as SaveData
	if not datos_guardado:
		return
		
	# Limpiamos las capas antes de pintar las nuevas
	ground_layer.clear()
	water_layer.clear()
	veg_layer.clear()
	
	# Pintamos el mapa usando los datos recuperados del recurso
	for celda_info in datos_guardado.saved_cells:
		var coord = Vector2i(celda_info["q"], celda_info["r"])
		var source_id = celda_info["source"]
		var atlas_coord = celda_info["atlas"]
		var alt_id = celda_info["alt"]
		
		# Aquí puedes distribuirlo a la capa que corresponda según tus IDs
		ground_layer.set_cell(coord, source_id, atlas_coord, alt_id)
				
	print("¡Mapa cargado con éxito!")
	

func obtener_coordenadas_atlas(id: int) -> Vector2i:
	# Si el ID existe en nuestro diccionario, devuelve su coordenada asignada
	if MAPEO_IDS_ATLAS.has(id):
		return MAPEO_IDS_ATLAS[id]
	
	# Si por algún motivo llega un ID desconocido, devolvemos una celda por defecto (ej. 0,0)
	print("Advertencia: ID no encontrado en el diccionario: ", id)
	return Vector2i(0, 0)
	
func pintar_mapa_desde_json(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	var map_data = json.get_data()
	
	for celda in map_data["cells"]:
		var coord_axial = Vector2i(celda["q"], celda["r"])
		var id = celda["id"]
		
		# Obtenemos la coordenada visual gracias a la función anterior
		var atlas_coord = obtener_coordenadas_atlas(id)
		const SOURCE_ID = 0 # El ID de la fuente de tu textura en el TileSet maestro
		
		# Clasificamos a qué TileMapLayer pertenece según el rango del ID
		if id >= 10 and id <= 15:
			# Es suelo -> va a la capa de suelo
			ground_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
			
		elif id >= 20 and id <= 25:
			# Es vegetación -> va a la capa de vegetación (se dibujará ENCIMA del suelo)
			veg_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
			
		elif id == 40:
			# Es agua -> va a la capa de agua
			water_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
			
		elif id == 50:
			# Es cerro -> puedes mandarlo a la capa de elevación
			veg_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
	_on_mapa_cargado()

func _on_mapa_cargado() -> void:
	var rect_limites = ground_layer.get_used_rect()
	
	if rect_limites.size != Vector2i.ZERO:
		# 1. Le pasamos los límites físicos a la cámara en píxeles
		if camara and camara.has_method("establecer_limites_desde_rect"):
			camara.establecer_limites_desde_rect(rect_limites, ground_layer)
			
		# 2. Calculamos el centro y centramos la cámara
		var centro_local = ground_layer.map_to_local(rect_limites.get_center())
		var centro_global = ground_layer.to_global(centro_local)
		
		if camara:
			camara.centrar_en_posicion(centro_global)

# Esta función será llamada por el menú principal o un autoload global
func cargar_mapa_desde_ruta(ruta_json: String) -> void:
	# Aquí va tu lógica de parseo de JSON que ya tienes
	# ... (leer archivo, parsear, iterar cells, hacer set_cell en capas correspondientes) ...
	print("Mapa cargado desde: ", ruta_json)
	
	# (Opcional) Una vez cargado, centras la cámara aquí o emites una señal
	call_deferred("centrar_camara_inicial")
	
	
func generar_mapa_nuevo(configuracion: Dictionary) -> void:
	# Lógica para crear un mapa proceduralmente basado en parámetros
	# (Ej. ancho, alto, semilla, % de agua)
	print("Generando mapa nuevo con config: ", configuracion)
	# ...

# --- NUEVA FUNCIÓN CON VALIDACIÓN DE ERRORES ---
func generar_y_guardar_mapa_recurso(path_json: String, path_salida_tres: String) -> void:
	print("Intentando abrir archivo JSON en: ", path_json)
	
	# 1. Verificar si el archivo realmente existe
	if not FileAccess.file_exists(path_json):
		printerr("¡Error crítico! El archivo JSON no existe en la ruta: ", path_json)
		return
	
	# 2. Abrir archivo
	var file = FileAccess.open(path_json, FileAccess.READ)
	if not file:
		printerr("¡Error crítico! No se pudo abrir el archivo para lectura.")
		return
		
	# 3. Parsear el texto JSON
	var json_text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		printerr("¡Error de sintaxis en el JSON! Línea ", json.get_error_line(), ": ", json.get_error_message())
		return
		
	var map_data = json.get_data()
	
	# 4. Validar que map_data sea realmente un Diccionario
	if typeof(map_data) != TYPE_DICTIONARY:
		printerr("¡Error crítico! El JSON no tiene un formato de diccionario válido.")
		return
		
	# 5. Crear el recurso contenedor del mapa
	var nuevo_mapa = GameMapData.new()
	nuevo_mapa.map_width = map_data.get("width", 0)
	nuevo_mapa.map_height = map_data.get("height", 0)
	
	# 6. Procesar celdas, crear datos LÓGICOS y pintar VISUALES
	var cells_array = map_data.get("cells", [])
	for celda in cells_array:
		var q = int(celda.get("q", 0))
		var r = int(celda.get("r", 0))
		var id = int(celda.get("id", 0))
		var coord_axial = Vector2i(q, r)
		
		# A. Crear y configurar el Recurso de datos LÓGICOS (CellData)
		var cell_res = CellData.new()
		cell_res.inicializar_por_id(q, r, id)
		
		# Guardar el recurso lógico en el diccionario del mapa principal
		nuevo_mapa.cells_data[coord_axial] = cell_res
		
		# B. Pintar los Sprites VISUALES
		var atlas_coord = obtener_coordenadas_atlas(id)
		const SOURCE_ID = 0
		
		if id >= 10 and id <= 15:
			ground_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
		elif id >= 20 and id <= 25:
			veg_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
		elif id == 40:
			water_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
		elif id == 50:
			veg_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
			
	# 7. GUARDAR EL MAPA COMPLETO COMO .TRES
	var save_error = ResourceSaver.save(nuevo_mapa, path_salida_tres)
	if save_error == OK:
		print("¡Mapa guardado exitosamente en: ", path_salida_tres)
		_on_mapa_cargado() # Notificar que el mapa visual está listo
	else:
		printerr("Error al guardar el archivo .tres. Código de error: ", save_error)

# --- FUNCIÓN DE PINTADO VISUAL ---
func cargar_y_pintar_mapa_desde_archivo(path_tres: String) -> void:
	var datos = MapManager.cargar_mapa_recurso(path_tres)
	if datos:
		pintar_mapa_desde_recurso(datos)
	else:
		printerr("No se pudo cargar el mapa para pintar.")

func pintar_mapa_desde_recurso(datos_mapa: GameMapData) -> void:
	print("Iniciando pintado visual del mapa: ", datos_mapa.map_name)
	mapa_datos_actual = datos_mapa
	
	# Si el mapa guardado tiene configuraciones personalizadas de terreno, las restauramos:
	if not datos_mapa.config_terrenos_mapa.is_empty():
		for id_cat in datos_mapa.config_terrenos_mapa.keys():
			if CellData.CONFIG_TERRENO.has(id_cat):
				var guardados = datos_mapa.config_terrenos_mapa[id_cat]
				CellData.CONFIG_TERRENO[id_cat].temp = guardados.temp
				CellData.CONFIG_TERRENO[id_cat].hum = guardados.hum
				CellData.CONFIG_TERRENO[id_cat].fuel = guardados.fuel
				CellData.CONFIG_TERRENO[id_cat].speed = guardados.speed
	
	# Limpiamos capas visuales antes de pintar
	ground_layer.clear()
	water_layer.clear()
	veg_layer.clear()
	
	const SOURCE_ID = 0 # ID de tu TileSet maestro
	
	# Iteramos sobre el diccionario de datos LÓGICOS
	# La clave es Vector2i(q, r), el valor es CellData
	for coord_axial in datos_mapa.cells_data:
		var cell_data = datos_mapa.cells_data[coord_axial]
		var id = cell_data.id_categoria
		
		# Obtenemos la coordenada visual del atlas (tu función original)
		var atlas_coord = obtener_coordenadas_atlas(id)
		
		# Clasificamos visualmente según el ID (igual que antes)
		if id >= 10 and id <= 15:
			ground_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
		elif id >= 20 and id <= 25:
			veg_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
		elif id == 40:
			water_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
		elif id == 50:
			veg_layer.set_cell(coord_axial, SOURCE_ID, atlas_coord)
			
	# --- RESTAURAR RECURSOS ---
	if not datos_mapa.recursos_configurados.is_empty():
		# Opcional: Actualizar un diccionario global de trabajo si lo usas
		# (Por ejemplo, alimentar al RecursosManager)
		print("Recursos cargados desde el mapa: ", datos_mapa.recursos_configurados)
		
		# Refrescamos el panel visual de recursos si ya está creado en la escena
		if panel_config_recursos and panel_config_recursos.has_method("refrescar_valores"):
			panel_config_recursos.refrescar_valores(datos_mapa.recursos_configurados)
	print("¡Pintado visual completado!")
	# Aquí podrías emitir una señal o llamar a una función para centrar la cámara
	_on_mapa_cargado() # Notificar que el mapa visual está listo
	if panel_config_terrenos and panel_config_terrenos.has_method("refrescar_valores"):
		panel_config_terrenos.refrescar_valores()
		
	refrescar_item_list_focos()
	actualizar_visualizacion_focos()
	
	# 2. Cargar los datos del clima y las fechas en el panel de clima
	if panel_config_clima and panel_config_clima.has_method("cargar_datos_desde_mapa"):
		panel_config_clima.cargar_datos_desde_mapa(mapa_datos_actual)
		print("Panel de clima actualizado con los datos del recurso cargado.")
	
	
# Conecta esta función a la señal del panel cuando este se cree o se muestre:
# panel_configuracion.configuracion_guardada.connect(_aplicar_nueva_configuracion_global)

func _aplicar_nueva_configuracion_global(nuevos_valores: Dictionary) -> void:
	if not mapa_datos_actual:
		_mostrar_dialogo_aviso("Error", "No hay un mapa activo cargado para actualizar.")
		return
	
	var hubo_cambios_reales = false
	var categorias_modificadas = [] # Guardaremos los IDs que realmente cambiaron
	
	# 1. Verificar cuáles categorías sufrieron modificaciones reales
	for id_cat in nuevos_valores.keys():
		if CellData.CONFIG_TERRENO.has(id_cat):
			var config = CellData.CONFIG_TERRENO[id_cat]
			var n_vals = nuevos_valores[id_cat]
			
			# Comparamos si algún atributo de esta categoría cambió
			if config.temp != n_vals.temp or config.hum != n_vals.hum or config.fuel != n_vals.fuel or config.speed != n_vals.speed:
				hubo_cambios_reales = true
				categorias_modificadas.append(id_cat) # Registramos este ID específico
				
				# Actualizamos la configuración global de la categoría
				config.temp = n_vals.temp
				config.hum = n_vals.hum
				config.fuel = n_vals.fuel
				config.speed = n_vals.speed
	
	# Si no se modificó ningún valor, salimos
	if not hubo_cambios_reales:
		_mostrar_dialogo_aviso("Aviso", "No se detectaron modificaciones en los parámetros. No se realizaron cambios.")
		return
	
	var contador_actualizadas = 0
	
	# 2. Recorrer el mapa actual actualizando SOLAMENTE las celdas de las categorías que cambiaron
	for coord in mapa_datos_actual.cells_data.keys():
		var cell_data: CellData = mapa_datos_actual.cells_data[coord]
		
		# Verificamos si la celda pertenece a una categoría que realmente fue modificada
		if cell_data.id_categoria in categorias_modificadas:
			var vals = nuevos_valores[cell_data.id_categoria]
			cell_data.ignition_temp = vals.temp
			cell_data.humidity = vals.hum
			cell_data.fuel_load = vals.fuel
			cell_data.burn_speed = vals.speed
			
			contador_actualizadas += 1
	
	# Dentro de _aplicar_nueva_configuracion_global, justo antes de ResourceSaver.save:
	mapa_datos_actual.config_terrenos_mapa = nuevos_valores
	# 3. Guardar permanentemente en el archivo .tres activo
	var ruta_actual = GameManager.mapa_a_cargar_ruta
	if ruta_actual != "":
		var error = ResourceSaver.save(mapa_datos_actual, ruta_actual)
		if error == OK:
			print("¡Configuración guardada con éxito! Celdas afectadas: ", contador_actualizadas)
			_mostrar_dialogo_aviso("¡Guardado Exitoso!", "Se actualizaron %d celdas de la categoría modificada y se guardaron los cambios." % contador_actualizadas)
		else:
			printerr("Error al guardar el recurso .tres. Código: ", error)
			_mostrar_dialogo_aviso("Error de Guardado", "Ocurrió un error al intentar guardar el archivo en disco (Código: %d)." % error)
	else:
		printerr("No se encontró la ruta del archivo .tres.")
		_mostrar_dialogo_aviso("Error", "No se encontró la ruta del archivo .tres activo para persistir los cambios.")


# Función auxiliar para crear y mostrar ventanas emergentes limpias
func _mostrar_dialogo_aviso(titulo: String, mensaje: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = titulo
	dialog.dialog_text = mensaje
	get_tree().root.add_child(dialog)
	
	# Godot centra automáticamente la ventana al usar este método
	dialog.popup_centered()
	
	# Destruimos el diálogo automáticamente al cerrarlo para evitar fugas de memoria
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	

# --- GUARDAR CONFIGURACIÓN DE RECURSOS ---
func _aplicar_nueva_configuracion_recursos(nuevos_recursos: Dictionary) -> void:
	if not mapa_datos_actual: return
	
	mapa_datos_actual.recursos_configurados = nuevos_recursos.duplicate()
	_guardar_cambios_en_disco("¡Recursos guardados con éxito!")

# --- GUARDAR CONFIGURACIÓN DE CLIMA ---
func _aplicar_nueva_configuracion_clima(paquete_clima: Dictionary) -> void:
	if mapa_datos_actual == null:
		return
		
	# Actualizar rango de fechas en el recurso
	mapa_datos_actual.fecha_inicio = paquete_clima["fecha_inicio"]
	mapa_datos_actual.fecha_fin = paquete_clima["fecha_fin"]
	mapa_datos_actual.datos_clima_diario = paquete_clima["dias"]
	
	# ---> FORZAR A GODOT A MARCAR EL RECURSO COMO MODIFICADO <---
	mapa_datos_actual.emit_changed()
	
	print("Clima asignado al recurso. Días totales a persistir: ", mapa_datos_actual.datos_clima_diario.size())
	
	# Guardar cambios en disco usando tu función estandarizada de ResourceSaver
	_guardar_cambios_en_disco("Datos del clima y rango de fechas guardados exitosamente.")

# Función auxiliar para centralizar el guardado en el .tres activo
func _guardar_cambios_en_disco(mensaje_exito: String) -> void:
	var ruta_actual = GameManager.mapa_a_cargar_ruta
	if ruta_actual != "":
		var error = ResourceSaver.save(mapa_datos_actual, ruta_actual)
		if error == OK:
			_mostrar_dialogo_aviso("Guardado Exitoso", mensaje_exito)
		else:
			_mostrar_dialogo_aviso("Error", "No se pudo guardar el archivo en disco. Código: %d" % error)

# 1. Activar / Desactivar el modo selección al presionar el botón Toggle
func _on_btn_toggle_modo_foco_toggled(toggled_on: bool) -> void:
	modo_seleccion_foco_activo = toggled_on
	if toggled_on:
		print("Modo selección de foco ACTIVADO. Haz clic en una celda del mapa.")
	else:
		print("Modo selección de foco DESACTIVADO.")

# 2. Capturar el clic del mouse en el mapa para agregar el foco
func _unhandled_input(event: InputEvent) -> void:
	# Si el mouse está sobre el panel de la interfaz, ignoramos por completo el input del mapa (zoom, clics, etc.)
	if panel_menu_master and panel_menu_master.get_global_rect().has_point(get_global_mouse_position()):
		return
	
	# 2. Lógica para el MODO BORRADOR EN EL MAPA
	if modo_borrador_foco_activo:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos_local = ground_layer.to_local(get_global_mouse_position())
			var celda_clicueada = ground_layer.local_to_map(mouse_pos_local)
			
			# Si la celda clicueada está en la lista de focos iniciales, la borramos
			if mapa_datos_actual and mapa_datos_actual.focos_iniciales.has(celda_clicueada):
				mapa_datos_actual.focos_iniciales.erase(celda_clicueada)
				refrescar_item_list_focos()
				actualizar_visualizacion_focos()
				_guardar_cambios_en_disco("Foco eliminado mediante el mapa.")
				print("Foco en coordenada ", celda_clicueada, " eliminado con borrador.")
			else:
				print("La celda seleccionada no es un foco inicial.")
				
			get_viewport().set_input_as_handled()
		return # Evita que procese otras acciones de clic mientras borras
		
		
	if not modo_seleccion_foco_activo: return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos_global = get_global_mouse_position()
		var mouse_pos_local = ground_layer.to_local(mouse_pos_global)
		var celda_clicueada = ground_layer.local_to_map(mouse_pos_local)
		
		# Intentar agregar pasando por todas las validaciones
		_intentar_agregar_foco(celda_clicueada)
		
		# Consumir evento para que no atraviese la UI
		get_viewport().set_input_as_handled()

# 3. Agregar manualmente mediante los SpinBox
func _on_btn_agregar_manual_pressed() -> void:
	var q = int(spin_box_q.value)
	var r = int(spin_box_r.value)
	var coordenada = Vector2i(q, r)
	
	_intentar_agregar_foco(coordenada)

# 4. FUNCIÓN CENTRAL DE VALIDACIÓN (NUEVA MEJORA)
func _intentar_agregar_foco(coord: Vector2i) -> void:
	if mapa_datos_actual == null:
		print("Error: No hay datos de mapa cargados.")
		return
		
	# A. Validar que la celda exista en el diccionario del mapa
	if not mapa_datos_actual.cells_data.has(coord):
		_mostrar_dialogo_aviso("Aviso", "La coordenada Q:%d, R:%d no existe en el mapa." % [coord.x, coord.y])
		return
		
	# B. Validar que no esté duplicada en la lista
	if mapa_datos_actual.focos_iniciales.has(coord):
		print("La coordenada Q:%d, R:%d ya está agregada como foco." % [coord.x, coord.y])
		return
		
	# C. Obtener los datos de la celda (CellData resource) usando las propiedades reales
	var datos_celda = mapa_datos_actual.cells_data[coord]
	
	var id_cat = datos_celda.id_categoria if "id_categoria" in datos_celda else -1
	var nombre_especie = datos_celda.species_name if "species_name" in datos_celda else ""
	var elevacion = datos_celda.elevation if "elevation" in datos_celda else 0
	
	# D. Validación de Tipo "Agua" (ID 40 o que el nombre de la especie sea "Agua")
	if id_cat == 40 or nombre_especie == "Agua":
		_mostrar_dialogo_aviso("Restricción", "No se puede colocar un foco en una casilla de tipo 'Agua'.")
		print("Validación fallida: Casilla de tipo Agua bloqueada correctamente.")
		return
		
	# E. Validación de Altitud (No puede ser igual o mayor a 400 msnm)
	if elevacion >= 400:
		_mostrar_dialogo_aviso("Restricción", "La altitud de la casilla (%.1f msnm) es igual o mayor a 400." % elevacion)
		print("Validación fallida: Altitud >= 400 msnm bloqueada.")
		return

	# F. Si pasa todas las reglas, se agrega y se actualiza
	mapa_datos_actual.focos_iniciales.append(coord)
	refrescar_item_list_focos()
	actualizar_visualizacion_focos()
	print("¡Foco validado y agregado con éxito en Q:%d, R:%d!" % [coord.x, coord.y])


# 5. Refrescar el componente ItemList visualmente
func refrescar_item_list_focos() -> void:
	if not item_list_focos: return
	item_list_focos.clear()
	
	if mapa_datos_actual:
		for coord in mapa_datos_actual.focos_iniciales:
			item_list_focos.add_item("Foco en Q: %d, R: %d" % [coord.x, coord.y])

# --- RECEPTORES DE LAS SEÑALES EN EL MAPLOADER ---

func _on_panel_foco_agregado_manual(q: int, r: int) -> void:
	var coordenada = Vector2i(q, r)
	_intentar_agregar_foco(coordenada)

func _on_panel_foco_eliminado(index: int) -> void:
	if mapa_datos_actual == null: return
	if index >= 0 and index < mapa_datos_actual.focos_iniciales.size():
		var eliminado = mapa_datos_actual.focos_iniciales[index]
		mapa_datos_actual.focos_iniciales.remove_at(index)
		refrescar_item_list_focos()
		actualizar_visualizacion_focos()
		_guardar_cambios_en_disco("Foco inicial eliminado correctamente.")
	

# Función para eliminar todos los elementos seleccionados en el ItemList de golpe
func eliminar_focos_seleccionados_lista() -> void:
	if mapa_datos_actual == null: return
	
	var indices_seleccionados = item_list_focos.get_selected_items()
	if indices_seleccionados.is_empty():
		return
		
	# IMPORTANTE: Ordenar los índices de mayor a menor para evitar errores 
	# de desplazamiento al remover elementos de un array dinámicamente.
	indices_seleccionados.sort()
	indices_seleccionados.reverse()
	
	for index in indices_seleccionados:
		if index >= 0 and index < mapa_datos_actual.focos_iniciales.size():
			mapa_datos_actual.focos_iniciales.remove_at(index)
			
	# Actualizamos la interfaz, el mapa visual y guardamos en disco
	refrescar_item_list_focos()
	actualizar_visualizacion_focos()
	_guardar_cambios_en_disco("Focos seleccionados eliminados correctamente.")

func _on_btn_toggle_borrador_foco_toggled(toggled_on: bool) -> void:
	modo_borrador_foco_activo = toggled_on
	if toggled_on:
		# Desactivamos el modo selección para que no se crucen las acciones
		modo_seleccion_foco_activo = false
		print("Modo borrador de focos ACTIVADO. Haz clic en un foco para eliminarlo.")
	else:
		print("Modo borrador de focos DESACTIVADO.")


func _on_panel_guardar_focos() -> void:
	_guardar_cambios_en_disco("Focos iniciales guardados exitosamente.")
	
func actualizar_visualizacion_focos() -> void:
	if not focos_layer: return
	focos_layer.clear()
	
	if mapa_datos_actual and not mapa_datos_actual.focos_iniciales.is_empty():
		for coord in mapa_datos_actual.focos_iniciales:
			# Dibuja el tile específico en la coordenada Q y R (Vector2i)
			focos_layer.set_cell(coord, 0, ATLAS_FOCO_INICIAL) # El '0' es el source_id de tu TileSet

func create_map():
	pass

func load_map():
	pass
	
func save_map():
	pass

func spawn_terrain():
	pass

func spawn_roads():
	pass

func spawn_buildings():
	pass
