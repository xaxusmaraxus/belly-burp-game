extends Label

export(String, FILE, "*.txt") var label_file 

func _ready():
	if label_file:
		var file = File.new()
		file.open(label_file, File.READ)
		var content = file.get_as_text()
		file.close()
		
		text = content
