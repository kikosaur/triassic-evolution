extends Control

@onready var label = $Label

var min_load_time = 2.0
var time_elapsed = 0.0
var data_loaded = false

func _ready():
	# 1. Listen for data load
	AuthManager.save_data_loaded.connect(_on_data_loaded)
	
	# 2. Trigger Load
	AuthManager.load_game_from_cloud()
	
	# 3. Animate Label
	var tween = create_tween().set_loops()
	tween.tween_property(label, "modulate:a", 0.5, 0.5)
	tween.tween_property(label, "modulate:a", 1.0, 0.5)

func _process(delta):
	time_elapsed += delta
	_check_transition()

func _on_data_loaded(_success):
	data_loaded = true
	_check_transition()

func _check_transition():
	if data_loaded and time_elapsed >= min_load_time:
		set_process(false) # Stop checking
		get_tree().change_scene_to_file("res://scenes/world/MainGame.tscn")
