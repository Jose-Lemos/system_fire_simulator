extends PanelContainer

signal foco_agregado_manual(q: int, r: int)
signal foco_eliminado_lista(index: int)
signal modo_selector_toggled(toggled_on: bool)
signal guardar_focos_solicitado()
signal modo_borrador_toggled(toggled_on: bool)

@onready var spin_q: SpinBox = $VBoxContainer/HBoxContainer/SpinBox_Q
@onready var spin_r: SpinBox = $VBoxContainer/HBoxContainer/SpinBox_R
@onready var btn_agregar: Button = $VBoxContainer/HBoxContainer/Btn_Agregar
@onready var btn_selector: Button = $VBoxContainer/Btn_SelectorFocoInicial
@onready var item_list: ItemList = $VBoxContainer/ItemList
@onready var btn_guardar: Button = $VBoxContainer/Btn_GuardarFocos
@onready var btn_borrador: Button = $VBoxContainer/Btn_Toggle_Borrador_Foco

func _ready() -> void:
	item_list.select_mode = ItemList.SELECT_SINGLE
	
	# Conectar los botones del panel a sus respectivas señales
	if btn_agregar:
		btn_agregar.pressed.connect(func(): emit_signal("foco_agregado_manual", int(spin_q.value), int(spin_r.value)))
	if btn_selector:
		btn_selector.toggled.connect(func(toggled): emit_signal("modo_selector_toggled", toggled))
	if btn_guardar:
		btn_guardar.pressed.connect(func(): emit_signal("guardar_focos_solicitado"))
	if item_list:
		item_list.item_activated.connect(func(index): emit_signal("foco_eliminado_lista", index))
	if btn_borrador:
		btn_borrador.toggled.connect(func(toggled): emit_signal("modo_borrador_toggled", toggled))
	
# Función para que el MapLoader pueda actualizar visualmente la lista en el ItemList
func refrescar_item_list(focos: Array[Vector2i]) -> void:
	item_list.clear()
	for coord in focos:
		item_list.add_item("Foco en Q: %d, R: %d" % [coord.x, coord.y])
