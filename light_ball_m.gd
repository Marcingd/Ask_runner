extends Area2D

var speed = 700 # szybkość, z jaką kula porusza się w kierunku postaci
var target = null # docelowa postać, do której kula jest przyciągana
@onready var anim = $Animation

func _ready():
#	connect("body_entered", self, "_on_body_entered")
#	connect("body_exited", self, "_on_body_exited")
	pass
func _physics_process(delta):
	if target != null:
#		var direction = (target.position - self.position).normalized()
		var direction = ((target.position - Vector2(0,150)) - self.position).normalized()
		var velocity = direction * speed * delta
		position += velocity


func _on_body_entered(body):
	target = body
	anim.play("collected")
	print(target)

func _on_body_exited(body):
	target = null





