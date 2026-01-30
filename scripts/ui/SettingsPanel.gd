extends Panel

# --- UI REFERENCES ---
# Adjust paths if your sliders are inside VBoxContainers!
@onready var master_slider = $MarginContainer/VBoxContainer/SliderMaster
@onready var music_slider = $MarginContainer/VBoxContainer/SliderMusic
@onready var sfx_slider = $MarginContainer/VBoxContainer/SliderMaster
@onready var close_btn = $MarginContainer/VBoxContainer/BtnClose # Or $VBoxContainer/CloseBtn depending on your layout

@onready var how_to_play_btn = $MarginContainer/VBoxContainer/HowToPlayBtn
@onready var terms_btn = $MarginContainer/VBoxContainer/TermsBtn
@onready var info_panel = $InfoPanel

var logout_btn: Button
var extinction_btn: Button

# --- DEFINE YOUR TEXT HERE ---
# We use BBCode ([b], [color]) to make the text look nice.
const HOW_TO_PLAY_TEXT = """
[b]1. Build Your Park[/b]
Buy dinosaurs from the Market to start generating DNA.

[b]2. Evolve[/b]
Use DNA to [color=yellow]Research[/color] new evolutionary traits. Unlocking nodes like 'Upright Stance' allows you to buy better dinosaurs.

[b]3. Complete Tasks[/b]
Check the Quest Menu for tasks. Completing them gives huge DNA bonuses!

[b]4. Manage Habitats[/b]
Buy habitat decorations to boost the efficiency of your dinosaurs.
"""

const TERMS_TEXT = """
[b]TRIASSIC EVOLUTION - TERMS OF USE[/b]

[b]1. Introduction[/b]
Welcome to Triassic Evolution. By playing this game, you join a community of dinosaur enthusiasts!

[b]2. Privacy Policy[/b]
This application is a student project and does NOT collect, store, or share any personal identifiable information (PII). All game data is stored locally on your device.

[b]3. Fair Play[/b]
Cheating, hacking, or exploiting bugs to gain unfair advantages (e.g., infinite DNA glitches) removes the fun of evolution. Play fair!

[b]4. Intellectual Property[/b]
All assets, including pixel art, music, and code, are original works or licensed for use. You may share screenshots and videos of your gameplay!

[b]5. Disclaimer[/b]
While we strive for accuracy, this is a simulation game. Evolutionary timelines and biological traits are stylized for gameplay purposes and may not reflect 100% scientific accuracy.

[i]Version 2.1.0 - The Evolution Update[/i]
"""

func _ready():
	# 1. CONNECT SLIDERS
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	master_slider.value_changed.connect(_on_master_changed)
	
	# 2. CONNECT CLOSE BUTTON (The Fix)
	# This hides the panel when clicked
	close_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		hide()
	)

	# 3. CONNECT INFO BUTTONS
	how_to_play_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		# info_panel.setup_popup("How to Play", HOW_TO_PLAY_TEXT)
		# Launch Interactive Tutorial
		hide() # Hide settings so we can see the tutorial
		TutorialManager.reset_tutorial()
	)
	
	terms_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		info_panel.setup_popup("Terms", TERMS_TEXT)
	)
	

	# 5. CONNECT LOGOUT BUTTON
	logout_btn = get_node_or_null("MarginContainer/VBoxContainer/BtnLogout")
	if logout_btn:
		logout_btn.pressed.connect(_on_logout_pressed)
		
	# 6. CONNECT EXTINCTION BUTTON
	extinction_btn = get_node_or_null("MarginContainer/VBoxContainer/BtnExtinction")
	if extinction_btn:
		extinction_btn.pressed.connect(_on_extinction_pressed)
		
	# Refresh button visibility when opening settings
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		_check_extinction_status()

func _check_extinction_status():
	if not extinction_btn: return
	
	if GameManager.is_win_condition_met():
		extinction_btn.visible = true
	else:
		extinction_btn.visible = false

func _on_extinction_pressed():
	AudioManager.play_sfx("click")
	# Trigger the event manually
	GameManager.trigger_extinction()
	hide()

func _on_logout_pressed():
	AudioManager.play_sfx("click")
	AuthManager.logout()
	# Return to Start Screen
	get_tree().change_scene_to_file("res://scenes/ui/StartScreen.tscn")


func _on_music_changed(value):
	# Send the new value directly to AudioManager
	AudioManager.set_music_volume(value)

func _on_sfx_changed(value):
	AudioManager.set_sfx_volume(value)
	# Optional: Play a test sound so user knows how loud it is
	if not AudioManager.sfx_player.playing:
		AudioManager.play_sfx("click")

func _on_master_changed(value):
	AudioManager.set_master_volume(value)
