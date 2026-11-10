extends Control

# Referencias a los paneles
@onready var panel_principal: VBoxContainer = $Panel_Principal
@onready var panel_seleccion_mapa: VBoxContainer = $Panel_SeleccionMapa
@onready var panel_seleccion_nivel: VBoxContainer = $Panel_SeleccionNivel

# Referencias a las listas
@onready var lista_mapas: VBoxContainer = $Panel_SeleccionMapa/ScrollContainer/VBox_ListaMapas
@onready var lista_niveles: VBoxContainer = $Panel_SeleccionNivel/ScrollContainer/VBox_ListaNiveles

# Referencias a diálogos
@onready var file_dialog: FileDialog = $FileDialog_Json
@onready var window_mapa_manual: Window = $Window_CrearMapaManual

# --- CORRECCIÓN AQUÍ ---
# ¡Cambia "mapas.tscn" por el nombre de tu escena donde está el MapLoader!
const SCENA_JUEGO = preload("res://scenes/Mapa-Reserva.tscn") 

# Variables de estado
var mapa_seleccionado_ruta: String = ""

func _ready() -> void:
	_conectar_botones()
	_ir_a_panel_principal()
	# Conectamos una sola vez la señal del diálogo
	if not file_dialog.file_selected.is_connected(_on_archivo_seleccionado):
		file_dialog.file_selected.connect(_on_archivo_seleccionado)

func _conectar_botones() -> void:
	# Panel Principal
	$Panel_Principal/Btn_Jugar.pressed.connect(_on_jugar_pressed)
	$Panel_Principal/Btn_CargarExterno.pressed.connect(_on_cargar_externo_pressed)
	
	# Panel Selección Mapa
	$Panel_SeleccionMapa/Btn_NuevoMapaManual.pressed.connect(_on_nuevo_mapa_manual_pressed)
	$Panel_SeleccionMapa/Btn_VolverPrincipal.pressed.connect(_ir_a_panel_principal)
	
	# Panel Selección Nivel
	$Panel_SeleccionNivel/Btn_VolverMapas.pressed.connect(_ir_a_panel_seleccion_mapa)
	# $Panel_SeleccionNivel/Btn_NuevaSimulacion ... (lógica similar)

func _resetear_paneles() -> void:
	panel_principal.hide()
	panel_seleccion_mapa.hide()
	panel_seleccion_nivel.hide()

# --- MÁQUINA DE ESTADOS ---

func _ir_a_panel_principal() -> void:
	_resetear_paneles()
	panel_principal.show()

func _ir_a_panel_seleccion_mapa() -> void:
	_resetear_paneles()
	panel_seleccion_mapa.show()
	_poblar_lista_mapas()

func _ir_a_panel_seleccion_nivel(nombre_mapa: String) -> void:
	_resetear_paneles()
	panel_seleccion_nivel.show()
	$Panel_SeleccionNivel/Label.text = "Simulaciones para: " + nombre_mapa
	_poblar_lista_niveles(nombre_mapa)

# --- LÓGICA DE BOTONES PRINCIPALES ---

func _on_jugar_pressed() -> void:
	# Si no hay mapas guardados internamente, ir directo a buscar uno externo
	if DataManager.mapas_disponibles.is_empty():
		_on_cargar_externo_pressed() 
	else:
		_ir_a_panel_seleccion_mapa()

func _on_cargar_externo_pressed() -> void:
	# Configuramos el diálogo para abrir archivos
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered()

# --- POBLAR LISTAS (Creación dinámica de botones) ---

func _poblar_lista_mapas() -> void:
	# Limpiar lista anterior
	for btn in lista_mapas.get_children():
		btn.queue_free()
		
	for info_mapa in DataManager.mapas_disponibles:
		var btn = Button.new()
		btn.text = info_mapa.nombre
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# Usamos una función anónima para conectar pasando los datos
		btn.pressed.connect(func(): _on_mapa_interno_seleccionado(info_mapa.ruta, info_mapa.nombre))
		lista_mapas.add_child(btn)

func _poblar_lista_niveles(nombre_mapa: String) -> void:
	# Limpiar lista anterior
	for btn in lista_niveles.get_children():
		btn.queue_free()
		
	# NOTA: Esta parte requiere que tu recurso SaveData tenga la lista de simulaciones
	var mapa_data = DataManager.cargar_mapa_recurso(mapa_seleccionado_ruta)
	if mapa_data and "lista_simulaciones" in mapa_data:
		for nombre_sim in mapa_data.lista_simulaciones:
			var btn = Button.new()
			btn.text = nombre_sim
			# Al hacer clic, cargamos el mapa Y la simulación específica
			btn.pressed.connect(func(): _iniciar_juego(mapa_seleccionado_ruta, nombre_sim))
			lista_niveles.add_child(btn)
	
	# Opción siempre presente: Crear nueva simulación
	var btn_nuevo = Button.new()
	btn_nuevo.text = "+ Crear Nueva Simulación"
	btn_nuevo.add_theme_color_override("font_color", Color.GOLD)
	btn_nuevo.pressed.connect(func(): _iniciar_juego(mapa_seleccionado_ruta, "")) 
	lista_niveles.add_child(btn_nuevo)

# --- UNIFICADOR DE CARGA ---

# Esta es la única función que conecta el FileDialog
func _on_archivo_seleccionado(path: String) -> void:
	print("Archivo seleccionado: ", path)
	
	# Aquí decides si es un JSON para importar o un .tres para cargar directamente.
	# Asumimos por ahora que si viene del FileDialog es externo (JSON)
	_gestionar_carga_mapa(path, true)

func _on_mapa_interno_seleccionado(ruta: String, _nombre: String) -> void:
	# Es un mapa interno (.tres), no necesita importarse
	_gestionar_carga_mapa(ruta, false)

func _gestionar_carga_mapa(ruta: String, es_externo: bool) -> void:
	# Guardamos la ruta globalmente para que la escena de juego la use
	GameManager.mapa_a_cargar_ruta = ruta
	GameManager.mapa_es_externo = es_externo
	
	# Cambiamos a la escena de juego
	get_tree().change_scene_to_packed(SCENA_JUEGO)
	
	# NOTA: Al cambiar la escena, este script se destruye, 
	# no es necesario llamar a queue_free() aquí.

# --- OTRAS FUNCIONES ---

func _iniciar_juego(_ruta_mapa: String, _nombre_simulacion: String) -> void:
	# Esta función ahora queda un poco redundante porque _gestionar_carga_mapa 
	# hace el cambio de escena. Si necesitas diferenciar niveles, 
	# usa una variable global extra en GameManager.
	pass 

func _on_nuevo_mapa_manual_pressed() -> void:
	# Muestra la ventana para crear mapa desde cero
	window_mapa_manual.popup_centered()
