extends Control

func _ready() -> void:
	Global.Hud = self

@export var hearts : Array[HeartContainer] = []
var dead = false
# Returns true if the player is dead, false otherwise
func lower_hp() -> bool:
	for heart in hearts:
		if heart.deplete():
			return false

	dead = true
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	return true

func heal_hp() -> void:
	var last_depleted_heart = null
	for heart in hearts:
		if heart.depleted or heart.is_depleting:
			last_depleted_heart = heart

	last_depleted_heart.replete()

@onready var ripper : HSlider = $Ripper
@onready var rip_timer : Timer = $RipTimer
@onready var zipper_sound : AudioStreamPlayer = $ZipperSound
@onready var tutorial_text : Label = $TutorialText
func _on_ripper_drag_ended(value_changed: bool) -> void:
	if not Global.PlayerBlade: return
	if value_changed:
		if tutorial_text:
			Global.EnemySpawner.spawn_timer.start()
			tutorial_text.queue_free()
		Global.PlayerBlade.angular_velocity += ripper.value
		var tween = get_tree().create_tween()
		tween.tween_property(ripper, "value", 0, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		ripper.editable = false
		rip_timer.start()
		zipper_sound.pitch_scale = randf_range(1.6, 2.2) - abs(ripper.value / ripper.max_value)
		zipper_sound.volume_db = randf_range(8, 12) * abs(ripper.value / ripper.max_value)
		zipper_sound.play()

func _on_rip_timer_timeout() -> void:
	ripper.editable = true
	ripper.value = 0

@onready var current_rads_label : Label = $CurrentRadsLabel
@onready var flash_text: AnimationPlayer = $FlashText
func _physics_process(_delta) -> void:
	if dead or not Global.PlayerBlade or tutorial_text: return
	current_rads_label.text = "RAD/S: \n%.1f" % abs(Global.PlayerBlade.angular_velocity)
	if abs(Global.PlayerBlade.angular_velocity) < 200:
		flash_text.play("flash")
	else:
		flash_text.stop()

@onready var powerup_menu : Panel = $PowerupMenu
@onready var powerup_label1 : Label = $PowerupMenu/Powerup1/Label
@onready var powerup_label2 : Label = $PowerupMenu/Powerup2/Label
@onready var powerup_label3 : Label = $PowerupMenu/Powerup3/Label

var rads_per_rip: int = 100
@onready var ripValue : Label = $RipValue
func updateRadsPerRip(amount: int) -> void:
	ripper.max_value += amount
	ripValue.text = str(int(ripper.max_value))

var choiceOptions: Dictionary = {
	"Increase rip power\n\n+%d RAD/s per rip" % 100: func() -> void: updateRadsPerRip(100), 
	"Increase rip power\n\n+%d RAD/s per rip" % 125: func() -> void: updateRadsPerRip(125),
	"Increase rip power\n\n+%d RAD/s per rip" % 150: func() -> void: updateRadsPerRip(150),
	"heal one heart\n\n+1 HEART": func() -> void: heal_hp(),
	"decrease rad/s lost\n\n- 0.01 damp": func() -> void: Global.PlayerBlade.angular_damp -= -.01,
	"decrease rad/s lost\n\n- 0.02 damp": func() -> void: Global.PlayerBlade.angular_damp -= -.02,
}
var randomOption1 = null
var randomOption2 = null
var randomOption3 = null

func randomize_options() -> void:
	randomOption1 = choiceOptions.keys()[randi() % choiceOptions.size()]
	randomOption2 = choiceOptions.keys()[randi() % choiceOptions.size()]
	randomOption3 = choiceOptions.keys()[randi() % choiceOptions.size()]

func show_powerup_menu() -> void:
	powerup_menu.visible = true
	get_tree().paused = true
	ripper.visible = false
	ripValue.visible = false
	current_rads_label.visible = false
	randomize_options()

	powerup_label1.text = randomOption1
	powerup_label2.text = randomOption2
	powerup_label3.text = randomOption3

func hide_powerup_menu() -> void:
	powerup_menu.visible = false
	get_tree().paused = false
	ripper.visible = true
	ripValue.visible = true
	current_rads_label.visible = true

var powerup_every: int = 5
@onready var killed_label : Label = $KilledLabel
func blades_killed(amount: int) -> void:
	killed_label.text = "Blades \nKilled:%d" % amount
	if amount % powerup_every == 0 and not dead:
		show_powerup_menu()

func _on_powerup_1_pressed() -> void:
	choiceOptions[randomOption1].call()
	hide_powerup_menu()

func _on_powerup_2_pressed() -> void:
	choiceOptions[randomOption2].call()
	hide_powerup_menu()

func _on_powerup_3_pressed() -> void:
	choiceOptions[randomOption3].call()
	hide_powerup_menu()


func _on_invert_ripper_toggled(toggled_on: bool) -> void:
	ripper.scale.x = -1 if toggled_on else 1
