class_name Enemy
extends RigidBody2D
const EXPLOSION_SCENE = preload("res://explosion.tscn")

var target_direction = Vector2.ZERO
@onready var target_direction_node: Node2D = $TargetDirection
@onready var sprite: Sprite2D = $Sprite2D
@export var time_to_rip: float = 1.5
@export var faster_than_to_attack: float = 150.0
var rip_speed: float = 200.0
var can_rip = true

func kill() -> void:
	var explosion = EXPLOSION_SCENE.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	Global.EnemySpawner.enemy_killed()
	queue_free()

var flash = false
func _physics_process(_delta):	
	if not Global.PlayerBlade:
		kill()
		return
	if not can_rip: return

	if angular_velocity - faster_than_to_attack < Global.PlayerBlade.angular_velocity:
		sprite.material.set_shader_parameter("replace_color", Color.ORANGE_RED)
		target_direction_node.visible = false
		target_direction = Vector2.ZERO
		linear_velocity = Vector2.ZERO
		can_rip = false
		var rip_timer = get_tree().create_timer(time_to_rip)
		rip_timer.timeout.connect(func() -> void:
			can_rip = true
			angular_velocity += rip_speed
		)
	else:
		sprite.material.set_shader_parameter("replace_color", Color.RED)
		#Magic 1 incase player no moving
		target_direction = (Global.PlayerBlade.global_position - global_position).normalized() * (1 + Global.PlayerBlade.angular_velocity/100)
		target_direction_node.rotation = target_direction.angle()
		target_direction_node.visible = true

		target_direction_node.global_position = global_position

		linear_velocity += target_direction * angular_velocity/100
		rotation_degrees = round(rotation_degrees / 5) * 5

func _on_body_entered(body: Node) -> void:
	angular_velocity /= 1.2
	# If is wall bounce off towards center
	if not body is Player:
		linear_velocity = global_position.direction_to(Vector2.ZERO) * 50 * (angular_velocity/100)
		target_direction = Vector2.ZERO
