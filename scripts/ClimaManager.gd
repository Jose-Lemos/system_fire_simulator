class_name ClimaManagerClass
extends Node

signal clima_guardado(datos_clima: Dictionary)

# Referencias a los selectores de fecha de inicio y fin
@onready var spin_ini_dia: SpinBox = $VBoxContainer/HBoxContainer_Fechas_ini/SpinBox_Dia_ini
@onready var spin_ini_mes: SpinBox = $VBoxContainer/HBoxContainer_Fechas_ini/SpinBox_Mes_ini
@onready var spin_ini_anio: SpinBox = $"VBoxContainer/HBoxContainer_Fechas_ini/SpinBox_Año_ini"

@onready var spin_fin_dia: SpinBox = $VBoxContainer/HBoxContainer_Fechas_fin/SpinBox_Dia_fin
@onready var spin_fin_mes: SpinBox = $VBoxContainer/HBoxContainer_Fechas_fin/SpinBox_Mes_fin
@onready var spin_fin_anio: SpinBox = $"VBoxContainer/HBoxContainer_Fechas_fin/SpinBox_Año_fin"

# Contenedor desplazable para listar los días
@onready var scroll_container_dias: ScrollContainer = $VBoxContainer/ScrollContainer_Dias
@onready var vbox_lista_dias: VBoxContainer = $VBoxContainer/ScrollContainer_Dias/VBoxContainer_Dias

@onready var btn_cargar_csv: Button = $VBoxContainer/Btn_CSV
@onready var btn_guardar: Button = $VBoxContainer/Btn_Guardar_Clima

# Referencia al FileDialog que agregaste en la escena
@onready var file_dialog_csv: FileDialog = $VBoxContainer/Btn_CSV/FileDialog

# Estructura local en memoria de los días de clima
var clima_en_memoria: Dictionary = {}

func _ready() -> void:
	_conectar_senales()

func _conectar_senales() -> void:
	if btn_cargar_csv:
		# Al hacer clic en el botón, mostramos el explorador de archivos
		btn_cargar_csv.pressed.connect(_on_btn_cargar_csv_pressed)
	if btn_guardar:
		btn_guardar.pressed.connect(_on_guardar_pressed)
	if file_dialog_csv:
		# Conectamos la señal cuando el usuario selecciona un archivo y pulsa "Abrir"
		file_dialog_csv.file_selected.connect(_on_archivo_csv_seleccionado)

# --- 1. ABRIR EL FILEDIALOG ---
func _on_btn_cargar_csv_pressed() -> void:
	if file_dialog_csv:
		file_dialog_csv.popup_centered(Vector2i(700, 500)) # Muestra la ventana centrada con tamaño cómodo

# --- 2. LEER Y PARSEAR EL ARCHIVO SELECCIONADO ---
func _on_archivo_csv_seleccionado(ruta_archivo: String) -> void:
	if not FileAccess.file_exists(ruta_archivo):
		print("Error: El archivo seleccionado no existe o no es accesible: ", ruta_archivo)
		return
		
	var archivo = FileAccess.open(ruta_archivo, FileAccess.READ)
	clima_en_memoria.clear()
	
	var primer_dia = {}
	var ultimo_dia = {}
	
	while not archivo.eof_reached():
		var linea = archivo.get_line().strip_edges()
		if linea.is_empty():
			continue
			
		var partes = linea.split(";")
		if partes.size() >= 8:
			var d = partes[0].to_int()
			var m = partes[1].to_int()
			var a = partes[2].to_int()
			var temp = partes[3].replace(",", ".").to_float()
			var hum = partes[4].replace(",", ".").to_float()
			var viento = partes[5].replace(",", ".").to_float()
			var dir = partes[6]
			var precip = partes[7].replace(",", ".").to_float()
			
			var datos_dia = {
				"dia": d, "mes": m, "anio": a,
				"temp": temp, "hum": hum, "viento": viento, "dir": dir, "precip": precip
			}
			
			var clave_fecha = "%02d-%02d-%d" % [d, m, a]
			clima_en_memoria[clave_fecha] = datos_dia
			
			# Guardamos el primero que leemos como referencia inicial
			if primer_dia.is_empty():
				primer_dia = datos_dia
			# El último que leemos (o iteramos) será el final
			ultimo_dia = datos_dia
			
	print("CSV de clima cargado con éxito. Total de días: ", clima_en_memoria.size())
	
	# ---> AQUÍ ESTABLECEMOS AUTOMÁTICAMENTE LAS FECHAS DE INICIO Y FIN SEGÚN EL CSV <---
	if not primer_dia.is_empty():
		spin_ini_dia.value = primer_dia["dia"]
		spin_ini_mes.value = primer_dia["mes"]
		spin_ini_anio.value = primer_dia["anio"]
		
	if not ultimo_dia.is_empty():
		spin_fin_dia.value = ultimo_dia["dia"]
		spin_fin_mes.value = ultimo_dia["mes"]
		spin_fin_anio.value = ultimo_dia["anio"]
		
	print("Rango de fechas ajustado automáticamente: Inicio (%02d/%02d/%d) - Fin (%02d/%02d/%d)" % [
		spin_ini_dia.value, spin_ini_mes.value, spin_ini_anio.value,
		spin_fin_dia.value, spin_fin_mes.value, spin_fin_anio.value
	])
	
	_refrescar_interfaz_dias()

# --- RENDERIZAR LOS DÍAS EN EL UI (ScrollContainer) ---
func _refrescar_interfaz_dias() -> void:
	for child in vbox_lista_dias.get_children():
		child.queue_free()
		
	# Lista de opciones posibles para la dirección del viento
	var direcciones_posibles = ["N", "S", "E", "W", "NE", "NW", "SE", "SW", "NNE", "ENE", "ESE", "SSE", "SSW", "WSW", "WNW", "NNW"]
		
	for clave in clima_en_memoria.keys():
		var datos = clima_en_memoria[clave]
		var fila = HBoxContainer.new()
		
		# 1. Etiqueta principal con la Fecha
		var lbl_fecha = Label.new()
		lbl_fecha.text = "%02d/%02d/%d:" % [datos["dia"], datos["mes"], datos["anio"]]
		lbl_fecha.custom_minimum_size = Vector2(90, 0)
		fila.add_child(lbl_fecha)
		
		# 2. Temperatura (Label + SpinBox)
		var lbl_t = Label.new()
		lbl_t.text = "Temp (°C):"
		fila.add_child(lbl_t)
		
		var spin_t = SpinBox.new()
		spin_t.min_value = -30; spin_t.max_value = 50; spin_t.step = 0.1
		spin_t.value = datos["temp"]
		spin_t.value_changed.connect(func(val): datos["temp"] = val)
		fila.add_child(spin_t)
		
		# 3. Humedad (Label + SpinBox)
		var lbl_h = Label.new()
		lbl_h.text = "Hum (%):"
		fila.add_child(lbl_h)
		
		var spin_h = SpinBox.new()
		spin_h.min_value = 0.0; spin_h.max_value = 1.0; spin_h.step = 0.01
		spin_h.value = datos["hum"]
		spin_h.value_changed.connect(func(val): datos["hum"] = val)
		fila.add_child(spin_h)
		
		# 4. Viento (Label + SpinBox)
		var lbl_v = Label.new()
		lbl_v.text = "Viento (Km/h):"
		fila.add_child(lbl_v)
		
		var spin_v = SpinBox.new()
		spin_v.min_value = 0; spin_v.max_value = 150
		spin_v.value = datos["viento"]
		spin_v.value_changed.connect(func(val): datos["viento"] = val)
		fila.add_child(spin_v)
		
		# 5. Dirección del Viento (Label + OptionButton desplegable)
		var lbl_dir = Label.new()
		lbl_dir.text = "Dir:"
		fila.add_child(lbl_dir)
		
		var option_dir = OptionButton.new()
		for i in range(direcciones_posibles.size()):
			var dir_nombre = direcciones_posibles[i]
			option_dir.add_item(dir_nombre)
			# Si coincide con el valor guardado en el CSV/memoria, lo seleccionamos por defecto
			if dir_nombre == datos["dir"]:
				option_dir.select(i)
				
		# Actualizar el valor en memoria cuando el usuario cambie la opción en el menú
		option_dir.item_selected.connect(func(index): 
			datos["dir"] = option_dir.get_item_text(index)
		)
		fila.add_child(option_dir)
		
		# 6. Precipitación (Label + SpinBox)
		var lbl_p = Label.new()
		lbl_p.text = "Precip (mm):"
		fila.add_child(lbl_p)
		
		var spin_p = SpinBox.new()
		spin_p.min_value = 0; spin_p.max_value = 200; spin_p.step = 0.5
		spin_p.value = datos["precip"]
		spin_p.value_changed.connect(func(val): datos["precip"] = val)
		fila.add_child(spin_p)
		
		vbox_lista_dias.add_child(fila)

# --- 4. GUARDAR CAMBIOS ---
func _on_guardar_pressed() -> void:
	var paquete_clima = {
		"fecha_inicio": { 
			"dia": int(spin_ini_dia.value), 
			"mes": int(spin_ini_mes.value), 
			"anio": int(spin_ini_anio.value) 
		},
		"fecha_fin": { 
			"dia": int(spin_fin_dia.value), 
			"mes": int(spin_fin_mes.value), 
			"anio": int(spin_fin_anio.value) 
		},
		"dias": clima_en_memoria
	}
	emit_signal("clima_guardado", paquete_clima)
	print("Señal de clima y fechas emitida con éxito al MapLoader.")

# Cargar datos iniciales desde el GameMapData al abrir el panel
func cargar_datos_desde_mapa(mapa_datos: GameMapData) -> void:
	if not mapa_datos: 
		print("Aviso: No hay GameMapData para cargar en el panel de clima.")
		return
	
	# 1. Verificar que los SpinBoxes estén listos y no sean nulos
	if not spin_ini_dia or not spin_ini_mes or not spin_ini_anio:
		print("ERROR CRITICO: Algún SpinBox de inicio es NULL. Revisa las rutas @onready.")
		return
		
	if not spin_fin_dia or not spin_fin_mes or not spin_fin_anio:
		print("ERROR CRITICO: Algún SpinBox de fin es NULL. Revisa las rutas @onready.")
		return

		
	# 1. Cargar fecha de inicio usando el operador 'in' en lugar de .has()
	if "fecha_inicio" in mapa_datos and mapa_datos.fecha_inicio:
		var f_ini = mapa_datos.fecha_inicio
		spin_ini_dia.value = f_ini.get("dia", 28)
		spin_ini_mes.value = f_ini.get("mes", 11)
		spin_ini_anio.value = f_ini.get("anio", 2022)
		
	# 2. Cargar fecha de fin
	if "fecha_fin" in mapa_datos and mapa_datos.fecha_fin:
		var f_fin = mapa_datos.fecha_fin
		spin_fin_dia.value = f_fin.get("dia", 28)
		spin_fin_mes.value = f_fin.get("mes", 2)
		spin_fin_anio.value = f_fin.get("anio", 2023)
		
	# 3. Cargar los días climáticos diarios en memoria y refrescar la lista
	if "datos_clima_diario" in mapa_datos and not mapa_datos.datos_clima_diario.is_empty():
		clima_en_memoria = mapa_datos.datos_clima_diario.duplicate(true)
		_refrescar_interfaz_dias()
		print("Datos climáticos del recurso cargados en el panel con éxito.")
