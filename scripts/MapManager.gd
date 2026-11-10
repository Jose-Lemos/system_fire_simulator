# MapManager.gd (Autoload)
extends Node

# Tabla de configuración COMPLETA de valores por defecto según el ID
const CONFIG_TERRENO = {
	# TERRENO DE SUELO
	10: { "name": "Arbustal", "temp": 25.0, "fuel": 2.0, "speed": 0.8, "hum": 0.4, "elev": 0 },
	11: { "name": "Bosques_abiertos -> Ñire", "temp": 30.0, "fuel": 4.0, "speed": 1.1, "hum": 0.3, "elev": 1 },
	12: { "name": "Bosques_cerrados -> Lenga", "temp": 35.0, "fuel": 5.0, "speed": 1.2, "hum": 0.3, "elev": 1 },
	13: { "name": "Herbaceas", "temp": 30.0, "fuel": 1.0, "speed": 1.3, "hum": 0.4, "elev": 0 },
	14: { "name": "Pastizal", "temp": 30.0, "fuel": 1.0, "speed": 1.4, "hum": 0.4, "elev": 0 },
	
	# TERRENO VEGETACIÓN
	20: { "name": "Lenga Pura", "temp": 35.0, "fuel": 5.0, "speed": 1.2, "hum": 0.3, "elev": 1 },
	21: { "name": "Ñire Puro", "temp": 30.0, "fuel": 4.0, "speed": 1.1, "hum": 0.3, "elev": 1 },
	22: { "name": "Bosque Mixto", "temp": 35.0, "fuel": 5.0, "speed": 1.2, "hum": 0.3, "elev": 1 },
	23: { "name": "Degradado de Lenga", "temp": 30.0, "fuel": 4.0, "speed": 1.1, "hum": 0.3, "elev": 1 },
	24: { "name": "Degradado de Ñire", "temp": 35.0, "fuel": 5.0, "speed": 1.2, "hum": 0.3, "elev": 1 },
	25: { "name": "Degradado Mixto", "temp": 30.0, "fuel": 4.0, "speed": 1.1, "hum": 0.3, "elev": 1 },
	
	# TERRENO AGUA
	40: { "name": "Agua", "temp": 0.0, "fuel": 0.0, "speed": 0.0, "hum": 1.0, "elev": 0 },
	
	# TERRENO CERRO
	50: { "name": "Cerro", "temp": 10.0, "fuel": 1.0, "speed": 0.3, "hum": 0.5, "elev": 10 },
}

# --- FUNCIÓN PURA DE IMPORTACIÓN Y GUARDADO ---
func importar_json_y_guardar_recurso(path_json: String, path_salida_tres: String) -> GameMapData:
	print("Iniciando importación de datos desde: ", path_json)
	
	var nuevo_mapa = GameMapData.new()
	nuevo_mapa.map_name = path_json.get_file().get_basename()
	
	if not FileAccess.file_exists(path_json):
		printerr("Archivo JSON no encontrado: ", path_json)
		return null
		
	var file = FileAccess.open(path_json, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		printerr("Error al parsear JSON: ", json.get_error_message())
		return null
		
	var map_data = json.get_data()
	
	nuevo_mapa.map_width = map_data.get("width", 0)
	nuevo_mapa.map_height = map_data.get("height", 0)
	
	var cells_array = map_data.get("cells", [])
	for celda in cells_array:
		var q = int(celda.get("q", 0))
		var r = int(celda.get("r", 0))
		var id = int(celda.get("id", -1)) # <--- ¡Casting estricto a entero aquí!
		var coord_axial = Vector2i(q, r)
		var elev_json = celda.get("elevation", -999.0)
		
		# A. Crear y configurar el Recurso de datos LÓGICOS (CellData)
		var cell_res = CellData.new()
		cell_res.q = q
		cell_res.r = r
		cell_res.id_categoria = id
		
		# Asignar valores por defecto según la tabla completa
		if CONFIG_TERRENO.has(id):
			var config = CONFIG_TERRENO[id]
			cell_res.species_name = config.name
			cell_res.ignition_temp = config.temp
			cell_res.fuel_load = config.fuel
			cell_res.burn_speed = config.speed
			cell_res.humidity = config.hum
			#cell_res.elevation = config.elev
			
			if elev_json != -999.0 and elev_json != 0.0:
				cell_res.elevation = elev_json
		else:
			cell_res.species_name = "Desconocido (ID: %d)" % id
			printerr("ID de terreno desconocido en JSON: ", id)
		
		# Guardar el recurso lógico en el diccionario del mapa
		nuevo_mapa.cells_data[coord_axial] = cell_res
			
	# 4. GUARDAR EL MAPA COMPLETO COMO .TRES
	var save_error = ResourceSaver.save(nuevo_mapa, path_salida_tres)
	if save_error == OK:
		print("¡Recurso de mapa guardado exitosamente en: ", path_salida_tres)
		return nuevo_mapa
	else:
		printerr("Error al guardar recurso de mapa. Código: ", save_error)
		return null

# --- FUNCIÓN DE CARGA ---
func cargar_mapa_recurso(path_tres: String) -> GameMapData:
	if FileAccess.file_exists(path_tres):
		print("Cargando mapa desde recurso: ", path_tres)
		return ResourceLoader.load(path_tres) as GameMapData
	else:
		printerr("Archivo de recurso no encontrado: ", path_tres)
		return null
