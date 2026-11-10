class_name GameMapData
extends Resource

@export var map_name: String = "Mapa Generado"
@export var map_width: int
@export var map_height: int
@export var cells_data: Dictionary = {}

# Agregamos esto para persistir los cambios de parámetros del panel en el propio archivo del mapa:
@export var config_terrenos_mapa: Dictionary = {}

# 2. NUEVO: Rango de Fechas de la Simulación
@export var fecha_inicio: Dictionary = { "dia": 28, "mes": 11, "anio": 2022 }
@export var fecha_fin: Dictionary = { "dia": 28, "mes": 2, "anio": 2023 }

# 3. NUEVO: Focos Iniciales de Incendio (Lista de coordenadas axiales)
@export var focos_iniciales: Array[Vector2i] = []

# 4. NUEVO: Recursos Tácticos Iniciales configurados para la misión
@export var recursos_configurados: Dictionary = {
	"brigadistas": 15,
	"camionetas_4x4": 4,
	"autobombas": 2,
	"medios_aereos": 1
}
