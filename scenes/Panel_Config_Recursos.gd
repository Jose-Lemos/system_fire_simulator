extends PanelContainer

signal recursos_guardados(nuevos_recursos: Dictionary)

@onready var spinbox_brigadistas = $VBoxContainer/HBoxContainer/SpinBox_Brigadistas
@onready var spinbox_camionetas = $VBoxContainer/HBoxContainer2/SpinBox_Camionetas
@onready var spinbox_autobombas = $VBoxContainer/HBoxContainer3/SpinBox_Camiones
@onready var spinbox_aereos = $VBoxContainer/HBoxContainer4/SpinBox_Helicoptero

@onready var btn_guardar: Button = $VBoxContainer/Btn_GuardarRecursos

# when the node enters the scene tree for the first time.
func _ready() -> void:
	if btn_guardar:
		btn_guardar.pressed.connect(_on_guardar_pressed)


func _on_guardar_pressed() -> void:
	# Recolectamos los valores de los SpinBoxes
	var datos = {
		"brigadistas": int(spinbox_brigadistas.value),
		"camionetas_4x4": int(spinbox_camionetas.value),
		"autobombas": int(spinbox_autobombas.value),
		"medios_aereos": int(spinbox_aereos.value)
	}
	
	# 2. EMITIR LA SEÑAL HACIA EL MAPLOADER
	emit_signal("recursos_guardados", datos)
	# O en Godot 4 también puedes usar: recursos_guardados.emit(datos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Dentro de tu Panel_Config_Recursos.gd
func refrescar_valores(recursos_guardados: Dictionary) -> void:
	if recursos_guardados.has("brigadistas"):
		spinbox_brigadistas.value = recursos_guardados["brigadistas"]
	if recursos_guardados.has("camionetas_4x4"):
		spinbox_camionetas.value = recursos_guardados["camionetas_4x4"]
	if recursos_guardados.has("autobombas"):
		spinbox_autobombas.value = recursos_guardados["autobombas"]
	if recursos_guardados.has("medios_aereos"):
		spinbox_aereos.value = recursos_guardados["medios_aereos"]
