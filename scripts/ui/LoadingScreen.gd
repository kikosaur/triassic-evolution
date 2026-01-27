extends Control

@onready var label = $Label

var min_load_time = 2.0
var time_elapsed = 0.0
var data_loaded = false
var scene_path = "res://scenes/world/MainGame.tscn"
var _load_progress = []

func _ready():
	# 1. Listen for data load
	AuthManager.save_data_loaded.connect(_on_data_loaded)
	
	# 2. Trigger Auth/Data Load
	AuthManager.load_game_from_cloud()
	
	# 3. Trigger Scene Load (Background Thread)
	ResourceLoader.load_threaded_request(scene_path)
	
	# 4. Animate Label
	var tween = create_tween().set_loops()
	tween.tween_property(label, "modulate:a", 0.5, 0.5)
	tween.tween_property(label, "modulate:a", 1.0, 0.5)

func _process(delta):
	time_elapsed += delta
	_check_transition()

func _on_data_loaded(success):
	if not success:
		print("LoadingScreen: Load failed (Session Expired). Returning to Start.")
		get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/StartScreen.tscn")
		return
		
	data_loaded = true
	# No need to call _check_transition here, _process handles it

func _check_transition():
	# 1. Wait for Data Load & Min Time
	if not data_loaded or time_elapsed < min_load_time:
		return

	# 2. Check Scene Load Status
	var status = ResourceLoader.load_threaded_get_status(scene_path, _load_progress)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false) # Stop checking
		var new_scene_resource = ResourceLoader.load_threaded_get(scene_path)
		print("LoadingScreen: Scene loaded. Transitioning...")
		get_tree().change_scene_to_packed(new_scene_resource)
		
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		print("LoadingScreen: Critical Error - Failed to load MainGame!")
		set_process(false)
