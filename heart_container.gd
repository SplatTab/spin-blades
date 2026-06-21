class_name HeartContainer
extends AnimatedSprite2D

var is_depleting = false
var depleted = false
var rotation_speed = 360.0


func deplete() -> bool:
	if is_depleting or depleted:
		return false
	
	is_depleting = true
	play()
	return true
	# await animation_finished
	# is_depleting = false
	# depleted = true
	# rotation_speed = 360

func replete() -> void:
	is_depleting = false
	depleted = false
	rotation_speed = 360
	frame = 0
	stop()

func _ready() -> void:
	animation_finished.connect(func() -> void:
		is_depleting = false
		depleted = true
		rotation_speed = 360
	)

func _process(delta: float) -> void:
	if depleted: return

	if is_depleting:
		var weight = 1.0 - exp(-0.9 * delta)
		rotation_speed = lerpf(rotation_speed, 0.0, weight)

	rotation_degrees += rotation_speed * delta
