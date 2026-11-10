extends Button


# En el botón "Crear Nuevo Mapa":
func _on_btn_crear_nuevo_pressed() -> void:
	GameManager.ir_a_crear_mapa_nuevo()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
