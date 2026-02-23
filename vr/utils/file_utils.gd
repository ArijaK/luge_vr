class_name FileUtils extends Node

static func load_config(path: String) -> ConfigFile:
	var cfg = ConfigFile.new()
	var result = cfg.load(path)
	if result == OK:
		return cfg
	else:
		push_error("Cannot open file " + path)
		return

static func parse_json(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open file " + path)
		return
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		var data = json.data
		if typeof(data) == TYPE_DICTIONARY:
			return data
		else:
			push_error("Unexpected data format")
			return
	else:
		push_error("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
		return
