extends Node2D

@onready var attac_area = $atack_area




func _physics_process(delta):
	var overlapping_bodies = $atack_area.get_overlapping_bodies()

	for body in overlapping_bodies:
		$target.global_position = body.global_position + Vector2(0,-250)

		$Skeleton2D/Bone2D/Bone2D2/Bone2D3/Bone2D4/head.look_at(body.global_position)


