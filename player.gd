class_name Player
extends RigidBody2D

const EXPLOSION_SCENE = preload("res://explosion.tscn")
@onready var target_direction_node: Node2D = $TargetDirection
var target_direction = Vector2.ZERO
@onready var thump_sound : AudioStreamPlayer = $ThumpSound
@onready var hurt_sound : AudioStreamPlayer = $HurtSound

func _ready() -> void:
	Global.PlayerBlade = self

func _physics_process(_delta):
	if Input.is_action_just_pressed("set_blade_target"):
		var mouse_pos = get_global_mouse_position()
		target_direction = (mouse_pos - global_position).normalized()
		target_direction_node.rotation = target_direction.angle()
		target_direction_node.visible = true
	if Input.is_action_pressed("remove_blade_target"):
		target_direction_node.visible = false
		target_direction = Vector2.ZERO
		linear_velocity = Vector2.ZERO

	target_direction_node.global_position = global_position

	linear_velocity += target_direction * angular_velocity/100
	rotation_degrees = round(rotation_degrees / 5) * 5

func hit_by_enemy() -> void:
	hurt_sound.play()
	var explosion = EXPLOSION_SCENE.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	if Global.Hud.lower_hp():
		queue_free()

var immunity: bool = false
@onready var immunity_timer: Timer = $ImmunityTimer
func _on_body_entered(body: Node) -> void:
	if angular_velocity > 100:
		thump_sound.volume_db = angular_velocity/200
		thump_sound.pitch_scale = randf_range(0.8, 1.2)
		thump_sound.play()

	if body is Enemy and not immunity:
		var diff = angular_velocity - body.angular_velocity
		if diff > 50:
			body.kill()
		elif diff < -50:
			hit_by_enemy()
			angular_velocity /= 1.25

		immunity = true
		immunity_timer.start()
	else:
		linear_velocity = global_position.direction_to(Vector2.ZERO) * 50 * (angular_velocity/100)
		target_direction = Vector2.ZERO
		target_direction_node.visible = false

		angular_velocity /= 1.25


func _on_immunity_timer_timeout() -> void:
	immunity = false
