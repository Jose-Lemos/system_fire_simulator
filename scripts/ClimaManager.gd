class_name ClimaManagerClass
extends Node

# Estructura final: { 1: { "maniana": {...}, "mediodia": {...}, "tarde": {...}, "noche": {...} }, ... }
var datos_clima_por_dia: Dictionary = {}

signal clima_guardado(datos_clima: Dictionary)

#@onready var btn_guardar: Button = $VBoxContainer/BtnGuardarClima

# Al presionar el botón "Cargar CSV de Clima" en tu panel:
func _on_btn_cargar_csv_pressed() -> void:
	$VBoxContainer/Btn_CSV/FileDialog.popup_centered()

# Cuando el usuario selecciona el archivo en la ventana emergente:
func _on_dialogo_csv_clima_file_selected(path: String) -> void:
	var archivo = FileAccess.open(path, FileAccess.READ)
	if not archivo:
		printerr("No se pudo abrir el archivo CSV.")
		return
		
	# Opcional: Guardamos la ruta del CSV en los datos del mapa para recordarla
	#if mapa_datos_actual:
		#mapa_datos_actual.clima_configurado["csv_path"] = path
		
	# Aquí llamas a tu función de parseo que lee línea por línea separando por ";"
	while not archivo.eof_reached():
		var linea = archivo.get_line().strip_edges()
		if linea.is_empty() or linea.begins_with("dia") or linea.begins_with("DIA"):
			continue
			
		var campos = linea.split(";")
		if campos.size() >= 8:
			var dia = campos[0].to_int()
			var mes = campos[1].to_int()
			var anio = campos[2].to_int()
			var temp = campos[3].replace(",", ".").to_float()
			var hum = campos[4].replace(",", ".").to_float()
			var viento = campos[5].replace(",", ".").to_float()
			var dir = campos[6]
			var precip = campos[7].replace(",", ".").to_float()
			
			# Guardas estos datos en tu ClimaManager o estructura global
			# ClimaManager.registrar_dato_diario(anio, mes, dia, temp, hum, viento, dir, precip)
			
	#_mostrar_dialogo_aviso("CSV Importado", "Los datos meteorológicos se cargaron correctamente.")
# Función matemática para desglosar el valor diario en 4 momentos realistas
func _generar_franjas_horarias(t_base: float, h_base: float, v_base: float, dir: String, p: float) -> Dictionary:
	return {
		"maniana": {
			"temp": clamp(t_base - 3.0, -10.0, 40.0),
			"hum": clamp(h_base + 15.0, 0.0, 100.0),
			"viento": max(0.0, v_base * 0.7),
			"dir": dir,
			"precip": p
		},
		"mediodia": {
			"temp": clamp(t_base + 4.0, -10.0, 40.0),
			"hum": clamp(h_base - 15.0, 0.0, 100.0),
			"viento": max(0.0, v_base * 1.1),
			"dir": dir,
			"precip": p
		},
		"tarde": {
			"temp": clamp(t_base + 2.0, -10.0, 40.0),
			"hum": clamp(h_base - 10.0, 0.0, 100.0),
			"viento": max(0.0, v_base * 1.3), # El viento pica fuerte a la tarde
			"dir": dir,
			"precip": p
		},
		"noche": {
			"temp": clamp(t_base - 4.0, -10.0, 40.0),
			"hum": clamp(h_base + 20.0, 0.0, 100.0),
			"viento": max(0.0, v_base * 0.5),
			"dir": dir,
			"precip": p
		}
	}

# Método para consultar el clima actual en la simulación
func obtener_clima(dia: int, franja: String) -> Dictionary:
	if datos_clima_por_dia.has(dia) and datos_clima_por_dia[dia].has(franja):
		return datos_clima_por_dia[dia][franja]
	# Valores por defecto de emergencia si falla la consulta
	return { "temp": 15.0, "hum": 50.0, "viento": 10.0, "dir": "NW", "precip": 0.0 }
