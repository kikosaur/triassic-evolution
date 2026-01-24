extends Control

# --- NODES ---
@onready var prompt_label = $VBoxContainer/LblPrompt
@onready var title_container = $VBoxContainer
@onready var auth_screen = $AuthenticationScreen
@onready var btn_settings = $BtnSettings
@onready var settings_panel = $SettingsPanel
# --- STATE ---
var is_waiting_for_input = true

func _ready():
	# 1. Check if already logged in (Auto-Load feature)
	# NOTE: We now check this AFTER user interaction in _transition_to_auth
	# if AuthManager.user_id != "":
	# ...
	# 2. Setup initial state
	auth_screen.visible = false
	btn_settings.visible = true
	
	# 3. Animate the prompt (Blinking)
	var tween = create_tween().set_loops()
	tween.tween_property(prompt_label, "modulate:a", 0.2, 1.0) # Fade out
	tween.tween_property(prompt_label, "modulate:a", 1.0, 1.0) # Fade in

	# 4. Listen for login success
	AuthManager.user_logged_in.connect(_on_login_success)
	btn_settings.pressed.connect(func(): settings_panel.visible = true)
	
	# 5. Connect Click Zone
	var click_zone = find_child("ClickZone")
	if click_zone:
		click_zone.pressed.connect(_transition_to_auth)

func _input(event):
	# Detect "Press Anywhere" (Keys only, mouse is handled by ClickZone)
	if is_waiting_for_input:
		if event is InputEventKey and event.pressed and not event.echo:
			_transition_to_auth()

func _transition_to_auth():
	is_waiting_for_input = false
	
	# CHECK LOGIN STATUS HERE
	if AuthManager.user_id != "":
		# Already logged in? Skip auth screen and load game
		get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/LoadingScreen.tscn")
		return
	
	# Create a smooth animation
	var tween = create_tween().set_parallel(true)
	
	# 1. Fade out the "Press Anywhere" text
	tween.tween_property(prompt_label, "modulate:a", 0.0, 0.5)
	
	# 2. Move Title Up (Optional polish)
	# tween.tween_property(title_container, "position:y", title_container.position.y - 100, 0.5)
	
	# 3. Reveal Auth Panel and Settings
	auth_screen.visible = true
	auth_screen.modulate.a = 0.0 # Start invisible
	tween.tween_property(auth_screen, "modulate:a", 1.0, 0.5)
	
	btn_settings.visible = true

func _on_login_success(_user):
	# User logged in! Fade out the whole screen and destroy it.
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	# FIX: Don't just destroy self, load the Game Scene!
	# FIX: Go to Loading Screen first to fetch data
	get_tree().change_scene_to_file("res://scenes/ui/LoadingScreen.tscn")
