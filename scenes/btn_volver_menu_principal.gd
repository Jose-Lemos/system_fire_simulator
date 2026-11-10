extends Button

# En el botón "Crear Nuevo Mapa":
func _on_btn_volver_menu_pressed() -> void:
	GameManager._cambiar_escena_deferred(GameManager.ESCENA_MENU_PRINCIPAL)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
