# GameManager.gd (Autoload)
extends Node

const ESCENA_MAPA_RESERVA = preload("res://scenes/Mapa-Reserva.tscn")
const ESCENA_EDITOR_MAPA = preload("res://scenes/EditorMapa.tscn")
const ESCENA_MENU_PRINCIPAL = preload("res://scenes/menu_principal.tscn")

var ruta_json_pendiente: String = ""
var es_importacion: bool = false
var mapa_a_cargar_ruta: String = ""

func ir_a_mapa_reserva(path: String) -> void:
	ruta_json_pendiente = path
	_cambiar_escena_deferred(ESCENA_MAPA_RESERVA)

func ir_a_jugar_mapa_guardado(ruta_tres: String) -> void:
	mapa_a_cargar_ruta = ruta_tres
	es_importacion = false
	_cambiar_escena_deferred(ESCENA_MAPA_RESERVA)

func ir_a_crear_mapa_nuevo() -> void:
	_cambiar_escena_deferred(ESCENA_EDITOR_MAPA)

# --- FUNCIÓN CENTRALIZADA Y SEGURA PARA CAMBIAR DE ESCENA ---
func _cambiar_escena_deferred(escena_packed: PackedScene) -> void:
	get_tree().call_deferred("change_scene_to_packed", escena_packed)
