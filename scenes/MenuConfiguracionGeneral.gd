class_name MenuConfiguracionGeneral
extends Control

# Referencias a los paneles desplegables
@onready var panel_terreno: Control = $VBox_MenuMaster/Panel_Config_Terrenos
@onready var panel_clima: Control = $VBox_MenuMaster/Panel_Config_Clima
@onready var panel_recursos: Control = $VBox_MenuMaster/Panel_Config_Recursos
@onready var panel_focos: Control = $VBox_MenuMaster/Panel_Config_Focos

# Referencias a los botones de cabecera
@onready var btn_terreno: Button = $VBox_MenuMaster/Btn_ToggleTerreno
@onready var btn_clima: Button = $VBox_MenuMaster/Btn_ToggleClima
@onready var btn_recursos: Button = $VBox_MenuMaster/Btn_ToggleRecursos
@onready var btn_focos: Button = $VBox_MenuMaster/Btn_ToggleFocos

func _ready() -> void:
	# Conectamos cada botón a su respectiva función de despliegue
	btn_terreno.pressed.connect(func(): _alternar_panel(panel_terreno))
	btn_clima.pressed.connect(func(): _alternar_panel(panel_clima))
	btn_recursos.pressed.connect(func(): _alternar_panel(panel_recursos))
	btn_focos.pressed.connect(func(): _alternar_panel(panel_focos))
	
	# Ocultamos todos al iniciar (o dejamos uno visible)
	_cerrar_todos()

func _alternar_panel(panel_a_modificar: Control) -> void:
	var estado_actual = panel_a_modificar.visible
	
	# Opcional: Si quieres comportamiento de acordeón estricto, 
	# descomenta la siguiente línea para cerrar los demás antes de abrir el nuevo:
	_cerrar_todos()
	
	# Invertimos el estado del panel seleccionado
	panel_a_modificar.visible = not estado_actual

func _cerrar_todos() -> void:
	panel_terreno.visible = false
	panel_clima.visible = false
	panel_recursos.visible = false
	panel_focos.visible = false
