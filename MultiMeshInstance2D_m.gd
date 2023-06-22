extends MultiMeshInstance2D



func _ready():
	var multimesh = get_multimesh()
	var instance_count = multimesh.instance_count

	for i in range(instance_count):
		var transform = Transform2D.IDENTITY
		# Ustaw pozycję dla instancji (zmień według potrzeb)
		transform.origin = Vector2(randf_range(-2000, 2000), randf_range(-2000, 2000))
		# Ustaw przekształcenie dla instancji
		multimesh.set_instance_transform(i, transform)
