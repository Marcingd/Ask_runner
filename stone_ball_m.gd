extends RigidBody2D

var previous_rotation
@onready var animation_player =$"../AnimationPlayer"

func _ready():
	# Zapisujemy początkowy kąt obrotu
	previous_rotation = rotation_degrees

func _physics_process(delta):
	
	
	# Oblicz różnicę kąta obrotu
	var rotation_difference = abs(rotation_degrees - previous_rotation)
	
	# Sprawdzamy, czy obiekt się obraca
	if rotation_difference > 0:
		# Jeśli się obraca i animacja nie jest odtwarzana, zacznij odtwarzać animację w pętli
		if not animation_player.is_playing():
			animation_player.play("rolling")
		
		# Ustalamy szybkość animacji na podstawie szybkości obrotu
		var animation_speed = (rotation_difference / delta) / 100
		animation_player.speed_scale = animation_speed
	else:
		# Jeśli się nie obraca, zatrzymaj odtwarzanie animacji
		if animation_player.is_playing():
			animation_player.stop()
		
	# Aktualizujemy poprzedni kąt obrotu
	previous_rotation = rotation_degrees

	
