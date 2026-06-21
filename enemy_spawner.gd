@tool
class_name Spawner
extends Node
# @onready var spawn_timer : Timer = $SpawnTimer
@export var min_spawn_time: float = 3
@export var max_spawn_time: float = 7
var ENEMY : PackedScene = preload("res://heart_blade.tscn")
@export var spawn_points: PackedVector2Array = []
var amount_spawned: int = 0
var amount_killed: int = 0
@onready var spawn_timer : Timer = $SpawnTimer

@export_tool_button("Create Spawn Point")
var create_spawn_point = _create_spawn_point
@export_tool_button("Update Spawn Point")
var update_spawn_point = _update_spawn_points

func _create_spawn_point():
	for spawn_point in spawn_points:
		var marker := Marker2D.new()
		marker.name = "SpawnPoint%d" % get_child_count()
		marker.global_position = spawn_point
		add_child(marker)
		marker.owner = get_tree().edited_scene_root

func _update_spawn_points():
	spawn_points.clear()

	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child.global_position)

func _ready() -> void:
	Global.EnemySpawner = self

func spawn_blade() -> void:
	var spawn = ENEMY.instantiate()
	spawn.rip_speed = amount_killed * 10 + 200
	spawn.angular_velocity = randf_range(50, 100) + amount_killed * 5
	spawn.global_position = spawn_points[randi() % spawn_points.size()]
	add_child(spawn)

func enemy_killed() -> void:
	amount_killed += 1
	Global.Hud.blades_killed(amount_killed)

func _on_spawn_timer_timeout() -> void:
	amount_spawned += 1
	spawn_blade()
	# 1 in 4 chance to spawn an extra blade
	if randi() % 4 == 0:
		amount_spawned += 1
		spawn_blade()

	var time = randf_range(min_spawn_time, max_spawn_time)
	var time_subtracted = sqrt(amount_spawned) / 5
	if time_subtracted > max_spawn_time - min_spawn_time:
		min_spawn_time -= 0.1

	if time_subtracted > time:
		time_subtracted = 0.1
		
	spawn_timer.start(time - time_subtracted)
