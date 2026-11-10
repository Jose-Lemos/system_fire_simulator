extends Node

# Datos del guardado
var save_path = "user://game_data.dat"

var data: Dictionary = {
	"maps": {},
	"config_level": {},
	"wather": {}
}



func save_game():
	var archivo = FileAccess.open(save_path, FileAccess.WRITE)
	archivo.store_var(data)
	archivo = null
	
func load_game():
	if FileAccess.file_exists(save_path):
		var archivo = FileAccess.open(save_path, FileAccess.READ)
		data = archivo.get_var()
		archivo = null
