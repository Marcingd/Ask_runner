extends Node2D


func _process(delta):
	$CanvasLayer7/Label.text = str(Engine.get_frames_per_second())
	print(str(Engine.get_frames_per_second()))

