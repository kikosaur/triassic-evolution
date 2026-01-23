extends Control

# --- NODES ---
@onready var prompt_label = $VBoxContainer/LblPrompt
@onready var title_container = $VBoxContainer
@onready var auth_panel = $AuthPanel # Ensure this matches your node name!
@onready var btn_settings = $BtnSettings
@onready var settings_panel = $SettingsPanel
# --- STATE ---
var is_waiting_for_input = true

func _ready():
	# 1. Check if already logged in (Auto-Load feature)
	# 1. Check if already logged in (Auto-Load feature)
	# 1. Check if already logged in (Auto-Load feature)
	if AuthManager.user_id != "":
		# We are already in MainGame, just remove the splash screen
		queue_free()
		return

	# 2. Setup initial state
	auth_panel.visible = false
	btn_settings.visible = false
	
	# 3. Animate the prompt (Blinking)
	var tween = create_tween().set_loops()
	tween.tween_property(prompt_label, "modulate:a", 0.2, 1.0) # Fade out
	tween.tween_property(prompt_label, "modulate:a", 1.0, 1.0) # Fade in

	# 4. Listen for login success
	AuthManager.user_logged_in.connect(_on_login_success)
	btn_settings.pressed.connect(func(): settings_panel.visible = true)

func _input(event):
	# Detect "Press Anywhere"
	if is_waiting_for_input:
		if event is InputEventMouseButton and event.pressed:
			_transition_to_auth()
		elif event is InputEventKey and event.pressed:
			_transition_to_auth()

func _transition_to_auth():
	is_waiting_for_input = false
	
	# Create a smooth animation
	var tween = create_tween().set_parallel(true)
	
	# 1. Fade out the "Press Anywhere" text
	tween.tween_property(prompt_label, "modulate:a", 0.0, 0.5)
	
	# 2. Move Title Up (Optional polish)
	# tween.tween_property(title_container, "position:y", title_container.position.y - 100, 0.5)
	
	# 3. Reveal Auth Panel and Settings
	auth_panel.visible = true
	auth_panel.modulate.a = 0.0 # Start invisible
	tween.tween_property(auth_panel, "modulate:a", 1.0, 0.5)
	
	btn_settings.visible = true

func _on_login_success(_user):
	# User logged in! Fade out the whole screen and destroy it.
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	# FIX: Don't just destroy self, load the Game Scene!
	# FIX: Go to Loading Screen first to fetch data
	get_tree().change_scene_to_file("res://scenes/ui/LoadingScreen.tscn")
