# DataManager.gd (Autoload)
extends Node

# Definimos las rutas relativas a la carpeta de usuario (user://)
const CARPETA_DATOS_RAIZ = "user://data"
const CARPETA_MAPAS_OUT = CARPETA_DATOS_RAIZ + "/maps_out"
const CARPETA_MAPAS_IN = CARPETA_DATOS_RAIZ + "/maps_in"

var mapas_disponibles: Array[Dictionary] = [] 

func _ready() -> void:
	# Al iniciar, nos aseguramos de que existan las carpetas
	verificar_directorios()
	cargar_lista_mapas()

# Crea las carpetas si no existen
func verificar_directorios() -> void:
	var dir = DirAccess.open("user://")
	
	if not dir.dir_exists("data"):
		dir.make_dir("data")
		print("Carpeta 'data' creada en user://")
		
	if not dir.dir_exists("data/maps_in"):
		dir.make_dir("data/maps_in")
		print("Carpeta 'data/maps_in' creada. Por favor coloque sus .json aquí.")
		
	if not dir.dir_exists("data/maps_out"):
		dir.make_dir("data/maps_out")
		print("Carpeta 'data/maps_out' creada.")

# Carga la lista de mapas desde user://data/maps_out
func cargar_lista_mapas() -> void:
	mapas_disponibles.clear()
	
	var dir = DirAccess.open(CARPETA_MAPAS_OUT)
	if dir:
		dir.list_dir_begin()
		var archivo = dir.get_next()
		while archivo != "":
			if archivo.ends_with(".tres"):
				var nombre = archivo.trim_suffix(".tres")
				mapas_disponibles.append({
					"nombre": nombre,
					"ruta": CARPETA_MAPAS_OUT + "/" + archivo
				})
			archivo = dir.get_next()
		print("Mapas cargados: ", mapas_disponibles.size())
	else:
		printerr("No se pudo abrir la carpeta de mapas en: ", CARPETA_MAPAS_OUT)

# --- Funciones de Acceso ---

# Guarda un mapa convertido/creado como .tres en maps_out
func guardar_mapa(datos_mapa: SaveData, nombre: String) -> void:
	var ruta_completa = CARPETA_MAPAS_OUT + "/" + nombre + ".tres"
	var error = ResourceSaver.save(datos_mapa, ruta_completa)
	if error == OK:
		print("¡Mapa guardado correctamente en: ", ruta_completa)
		cargar_lista_mapas() # Actualizar la lista global
	else:
		printerr("Error al guardar mapa. Código: ", error)

# Carga un mapa específico desde su ruta (para jugar)
func cargar_mapa_recurso(ruta: String) -> SaveData:
	# Validamos que la ruta pertenezca a nuestra carpeta de mapas segura
	if not ruta.begins_with(CARPETA_MAPAS_OUT):
		printerr("Intento de carga de ruta inválida: ", ruta)
		return null
		
	if FileAccess.file_exists(ruta):
		return ResourceLoader.load(ruta) as SaveData
	return null

# --- Funciones para el flujo de Importación (maps_in) ---

# Retorna la ruta absoluta de la carpeta maps_in para usarla en el FileDialog del menú
func obtener_ruta_maps_in_absoluta() -> String:
	# Convertimos la ruta virtual user:// a ruta absoluta del OS para que la ventana de Windows la entienda
	return ProjectSettings.globalize_path(CARPETA_MAPAS_IN)

# Retorna una lista de archivos .json disponibles en maps_in
func listar_json_disponibles() -> Array[String]:
	var json_files: Array[String] = []
	var dir = DirAccess.open(CARPETA_MAPAS_IN)
	if dir:
		dir.list_dir_begin()
		var archivo = dir.get_next()
		while archivo != "":
			if archivo.ends_with(".json"):
				# Devolvemos ruta virtual user://
				json_files.append(CARPETA_MAPAS_IN + "/" + archivo)
			archivo = dir.get_next()
	return json_files

# Opcional: Mueve un JSON ya importado a una subcarpeta 'procesados' para no volver a leerlo
func marcar_json_como_procesado(ruta_json: String) -> void:
	var dir = DirAccess.open(CARPETA_MAPAS_IN)
	if dir:
		var nombre_archivo = ruta_json.get_file()
		if not dir.dir_exists("procesados"):
			dir.make_dir("procesados")
		dir.rename(nombre_archivo, "procesados/" + nombre_archivo)
		print("JSON movido a 'procesados': ", nombre_archivo)
