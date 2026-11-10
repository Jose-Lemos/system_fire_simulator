extends PanelContainer

# Enlazamos las etiquetas visuales desde el editor
@onready var lbl_title: Label = $VBoxContainer/Title
@onready var lbl_especie: Label = $VBoxContainer/Label_Especie
@onready var lbl_temp: Label = $VBoxContainer/Label_Temp
@onready var lbl_carga: Label = $VBoxContainer/Label_Carga
@onready var lbl_velocidad: Label = $VBoxContainer/Label_Velocidad
@onready var lbl_humedad: Label = $VBoxContainer/Label_Humedad
@onready var lbl_elevation: Label = $VBoxContainer/Label_Elev

# Función para actualizar el panel con los datos de un recurso CellData
func actualizar(datos_celda: CellData) -> void:
	if not datos_celda:
		# Si no hay datos (ej. seleccionamos fuera del mapa), ocultamos o limpiamos
		visible = false
		return
	
	visible = true
	#print("Actualizando panel con especie: ", datos_celda.species_name)
	
	# Actualizamos el texto de cada etiqueta formateando los valores
	lbl_title.text = "Info de Celda: ID(" + str(datos_celda.q) + "," + str(datos_celda.r) + ")"
	lbl_especie.text = "Especie: " + str(datos_celda.species_name)
	lbl_temp.text = "Temp. Ignición: " + "%.1f" % datos_celda.ignition_temp + "°C"
	lbl_carga.text = "Carga Combustible: " + "%.2f" % datos_celda.fuel_load + " Tn/ha"
	lbl_velocidad.text = "Vel. Quema: " + "%.2f" % datos_celda.burn_speed + " m/min"
	lbl_humedad.text = "Humedad: " + "%.1f" % (datos_celda.humidity * 100) + "%"
	lbl_elevation.text = "Elevación: " + "%.1f" % (datos_celda.elevation) + " msnm"

func limpiar() -> void:
	actualizar(null) # Oculta el panel
