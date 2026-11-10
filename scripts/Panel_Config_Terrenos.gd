extends PanelContainer

signal configuracion_guardada(nuevos_valores: Dictionary)

# Referencia al VBox contenedor principal que ahora abarca todo
@onready var vbox_principal: VBoxContainer = $VBox_Principal
@onready var contenedor_filas: VBoxContainer = $VBox_Principal/ScrollContainer/VBox_Filas
@onready var btn_guardar: Button = $VBox_Principal/Btn_Guardar

var inputs_por_id: Dictionary = {}

func _ready() -> void:
	if btn_guardar:
		btn_guardar.pressed.connect(_on_guardar_pressed)
	
	_crear_encabezados()
	poblar_panel()

func _crear_encabezados() -> void:
	# 1. Etiqueta de título superior
	var lbl_titulo = Label.new()
	lbl_titulo.text = "⚙️ Configuración de Parámetros del Mapa"
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 16)
	vbox_principal.add_child(lbl_titulo)
	vbox_principal.move_child(lbl_titulo, 0) # Lo colocamos al tope
	
	var separador = HSeparator.new()
	vbox_principal.add_child(separador)
	vbox_principal.move_child(separador, 1)

	# 2. Fila con los nombres de las columnas
	var hbox_headers = HBoxContainer.new()
	hbox_headers.custom_minimum_size = Vector2(0, 30)
	
	var col_especie = Label.new()
	col_especie.text = "Terreno / Especie"
	col_especie.custom_minimum_size = Vector2(200, 0)
	hbox_headers.add_child(col_especie)
	
	var col_temp = Label.new()
	col_temp.text = "Temp (°C)"
	col_temp.custom_minimum_size = Vector2(100, 0)
	col_temp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox_headers.add_child(col_temp)
	
	var col_hum = Label.new()
	col_hum.text = "Humedad"
	col_hum.custom_minimum_size = Vector2(100, 0)
	col_hum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox_headers.add_child(col_hum)
	
	var col_fuel = Label.new()
	col_fuel.text = "Combust."
	col_fuel.custom_minimum_size = Vector2(100, 0)
	col_fuel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox_headers.add_child(col_fuel)
	
	var col_speed = Label.new()
	col_speed.text = "Velocidad"
	col_speed.custom_minimum_size = Vector2(100, 0)
	col_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox_headers.add_child(col_speed)
	
	# Insertamos las cabeceras justo antes del ScrollContainer (en la posición 2)
	vbox_principal.add_child(hbox_headers)
	vbox_principal.move_child(hbox_headers, 2)

func poblar_panel() -> void:
	for child in contenedor_filas.get_children():
		child.queue_free()
	inputs_por_id.clear()

	for id_cat in CellData.CONFIG_TERRENO.keys():
		var config = CellData.CONFIG_TERRENO[id_cat]
		
		var fila = HBoxContainer.new()
		fila.custom_minimum_size = Vector2(0, 40)
		
		var lbl_nombre = Label.new()
		lbl_nombre.text = "%s (ID: %d)" % [config.name, id_cat]
		lbl_nombre.custom_minimum_size = Vector2(200, 0)
		fila.add_child(lbl_nombre)
		
		var spin_temp = _crear_spin_box(config.temp, 0.0, 1000.0, 1.0, "Temperatura de Ignición")
		fila.add_child(spin_temp)
		
		var spin_hum = _crear_spin_box(config.hum, 0.0, 1.0, 0.05, "Humedad (0.0 a 1.0)")
		fila.add_child(spin_hum)
		
		var spin_fuel = _crear_spin_box(config.fuel, 0.0, 50.0, 0.5, "Carga de Combustible")
		fila.add_child(spin_fuel)
		
		var spin_speed = _crear_spin_box(config.speed, 0.0, 10.0, 0.1, "Velocidad de Quema")
		fila.add_child(spin_speed)
		
		inputs_por_id[id_cat] = {
			"temp": spin_temp,
			"hum": spin_hum,
			"fuel": spin_fuel,
			"speed": spin_speed
		}
		
		contenedor_filas.add_child(fila)

func _crear_spin_box(valor_inicial: float, min_val: float, max_val: float, step: float, tooltip: String) -> SpinBox:
	var sb = SpinBox.new()
	sb.min_value = min_val
	sb.max_value = max_val
	sb.step = step
	sb.value = valor_inicial
	sb.tooltip_text = tooltip
	sb.custom_minimum_size = Vector2(100, 0)
	return sb

func _on_guardar_pressed() -> void:
	var nuevos_datos = {}
	for id_cat in inputs_por_id.keys():
		nuevos_datos[id_cat] = {
			"temp": inputs_por_id[id_cat]["temp"].value,
			"hum": inputs_por_id[id_cat]["hum"].value,
			"fuel": inputs_por_id[id_cat]["fuel"].value,
			"speed": inputs_por_id[id_cat]["speed"].value
		}
	
	emit_signal("configuracion_guardada", nuevos_datos)
	#hide()
# Crea una función pública para refrescar los valores de los SpinBoxes si ya existen
func refrescar_valores() -> void:
	for id_cat in inputs_por_id.keys():
		if CellData.CONFIG_TERRENO.has(id_cat):
			var config = CellData.CONFIG_TERRENO[id_cat]
			inputs_por_id[id_cat]["temp"].value = config.temp
			inputs_por_id[id_cat]["hum"].value = config.hum
			inputs_por_id[id_cat]["fuel"].value = config.fuel
			inputs_por_id[id_cat]["speed"].value = config.speed
