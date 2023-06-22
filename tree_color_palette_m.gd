extends Sprite2D

var color = ColorPalleteAutoload.green_colors


func _ready():
	randomize()
	var random_color = color[randi() % color.size()]
	modulate = random_color
