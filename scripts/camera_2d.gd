extends Camera2D

@export var velocidad_movimiento: float = 800.0
@export var margen_borde: float = 30.0 # Píxeles desde el borde de la pantalla para activar el movimiento
@export var zoom_vel: float = 0.05
@export var zoom_min: float = 0.06
@export var zoom_max: float = 2.0

var arrastrando: bool = false
var limite_inferior_derecho: Vector2 = Vector2.ZERO
var limite_superior_izquierdo: Vector2 = Vector2.ZERO

# --- PROTECCIÓN PARA EVITAR EL ERROR DEL VIEWPORT ---
func _init() -> void:
	# Desactivamos los inputs no manejados al nacer para que el Viewport 
	# no intente enviarle eventos mientras la escena está cargando o cambiando.
	set_process_unhandled_input(false)
	
func _ready() -> void:
	# Una vez que la cámara ya está dentro del árbol y posicionada, 
	# reactivamos la escucha de la rueda del ratón y el zoom.
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	# 1. Zoom con la rueda del ratón
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(zoom_vel, zoom_vel)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= Vector2(zoom_vel, zoom_vel)
		
		#zoom = zoom.clamp(Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))
		# IMPORTANTE: Evitamos que el zoom llegue a 0 o sea negativo, 
		# y respetamos estrictamente los límites configurados.
		zoom.x = clamp(zoom.x, zoom_min, zoom_max)
		zoom.y = clamp(zoom.y, zoom_min, zoom_max)
		
		# 2. Arrastrar el mapa con el clic central
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			arrastrando = event.pressed

	# 3. Mover la cámara arrastrando el ratón
	if event is InputEventMouseMotion and arrastrando:
		position -= event.relative / zoom
		restringir_a_limites()

func _process(delta: float) -> void:
	var direccion = Vector2.ZERO
	
	# --- MOVIMIENTO POR BORDES DE LA PANTALLA ---
	var mouse_pos = get_viewport().get_mouse_position()
	var tam_pantalla = get_viewport().get_visible_rect().size
	
	if mouse_pos.x <= margen_borde:
		direccion.x -= 1
	elif mouse_pos.x >= tam_pantalla.x - margen_borde:
		direccion.x += 1
		
	if mouse_pos.y <= margen_borde:
		direccion.y -= 1
	elif mouse_pos.y >= tam_pantalla.y - margen_borde:
		direccion.y += 1
		
	# Si no se mueve por los bordes, permitimos las flechas del teclado como alternativa
	if direccion == Vector2.ZERO:
		direccion = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
	if direccion != Vector2.ZERO:
		position += direccion.normalized() * velocidad_movimiento * delta / zoom.x
		restringir_a_limites()

# Función para configurar los límites físicos de la cámara en base al tamaño del mapa
func establecer_limites_desde_rect(rect_celdas: Rect2i, tile_map_layer: TileMapLayer) -> void:
	# Convertimos las coordenadas de la cuadrícula de celdas a píxeles globales
	var pos_min_local = tile_map_layer.map_to_local(rect_celdas.position)
	var pos_max_local = tile_map_layer.map_to_local(rect_celdas.position + rect_celdas.size)
	
	limite_superior_izquierdo = tile_map_layer.to_global(pos_min_local)
	limite_inferior_derecho = tile_map_layer.to_global(pos_max_local)

func restringir_a_limites() -> void:
	# Evita que la posición de la cámara rebase los extremos del mapa
	if limite_superior_izquierdo != limite_inferior_derecho:
		position.x = clamp(position.x, limite_superior_izquierdo.x, limite_inferior_derecho.x)
		position.y = clamp(position.y, limite_superior_izquierdo.y, limite_inferior_derecho.y)

func centrar_en_posicion(posicion_global: Vector2) -> void:
	global_position = posicion_global
	restringir_a_limites()
