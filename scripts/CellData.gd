# CellData.gd
class_name CellData
extends Resource

# Datos por defecto de la casilla
@export var q: int
@export var r: int
@export var id_categoria: int # El ID original del JSON (10, 20, 40, 50)
@export var species_name: String = "Desconocido"
@export var ignition_temp: float = 300.0
@export var fuel_load: float = 1.0
@export var burn_speed: float = 0.5
@export var humidity: float = 0.5
@export var elevation: float = 0.0

# Diccionario maestro de configuración de terrenos / especies con los valores de los datos de las variables
static var CONFIG_TERRENO = {
	# TERRENO DE SUELO POR DEFECTO
	10: { "name": "Arbustal", "temp": 25.0, "fuel": 2.0, "speed": 0.8, "hum": 0.4, "elev": 0 },
	11: { "name": "Bosques_abiertos -> Ñire", "temp": 30.0, "fuel": 4.0, "speed": 1.1, "hum": 0.3, "elev": 1 },
	12: { "name": "Bosques_cerrados -> Lenga", "temp": 35.0, "fuel": 5.0, "speed": 1.2, "hum": 0.3, "elev": 1 },
	13: { "name": "Herbaceas", "temp": 30.0, "fuel": 1.0, "speed": 1.3, "hum": 0.4, "elev": 0 },
	14: { "name": "Pastizal", "temp": 30.0, "fuel": 1.0, "speed": 1.4, "hum": 0.4, "elev": 0 },
	
	# TERRENO VEGETACIÓN POR DEFECTO
	20: { "name": "Lenga Pura", "temp": 35.0, "fuel": 5.0, "speed": 1.2, "hum": 0.3, "elev": 1 },
	21: { "name": "Ñire Puro", "temp": 30.0, "fuel": 4.0, "speed": 1.1, "hum": 0.3, "elev": 1 },
	22: { "name": "Bosque Mixto", "temp": 35.0, "fuel": 5.0, "speed": 1.2, "hum": 0.3, "elev": 1 },
	23: { "name": "Degradado de Lenga", "temp": 30.0, "fuel": 4.0, "speed": 1.1, "hum": 0.3, "elev": 1 },
	24: { "name": "Degradado de Ñire", "temp": 35.0, "fuel": 5.0, "speed": 1.2, "hum": 0.3, "elev": 1 },
	25: { "name": "Degradado Mixto", "temp": 30.0, "fuel": 4.0, "speed": 1.1, "hum": 0.3, "elev": 1 },
	
	# TERRENO AGUA POR DEFECTO
	40: { "name": "Agua", "temp": 0.0, "fuel": 0.0, "speed": 0.0, "hum": 1.0, "elev": 0 },
	
	# TERRENO CERRO POR DEFECTO
	50: { "name": "Cerro", "temp": 10.0, "fuel": 1.0, "speed": 0.3, "hum": 0.5, "elev": 10 },
}

# Función para inicializar los datos de la celda en base a su ID
func inicializar_por_id(coord_q: int, coord_r: int, id) -> void:
	q = coord_q
	r = coord_r
	id_categoria = int(id)
	#print("ID_CELL",id)
	
	if CONFIG_TERRENO.has(id_categoria):
		var config = CONFIG_TERRENO[id_categoria]
		species_name = config.name
		ignition_temp = config.temp
		fuel_load = config.fuel
		burn_speed = config.speed
		humidity = config.hum
		elevation = config.elev
	else:
		# Valores por defecto si el ID no está registrado en el diccionario
		species_name = "Desconocido (ID: %d)" % id
		print("¡Atención! ID sin configurar en el diccionario: ", id_categoria)
