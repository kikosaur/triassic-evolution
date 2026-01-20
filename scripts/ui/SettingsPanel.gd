extends Panel

# --- AUDIO BUS INDICES ---
var master_bus = AudioServer.get_bus_index("Master")
var music_bus = AudioServer.get_bus_index("Music")
var sfx_bus = AudioServer.get_bus_index("SFX")

# --- NODES ---
@onready var slider_master = $MarginContainer/VBoxContainer/SliderMaster
@onready var slider_music = $MarginContainer/VBoxContainer/SliderMusic
@onready var slider_sfx = $MarginContainer/VBoxContainer/SliderSFX

@onready var info_panel = $InfoPanel
@onready var info_text = $InfoPanel/MarginContainer/VBoxContainer/InfoText
@onready var btn_back = $InfoPanel/MarginContainer/VBoxContainer/BtnBack

func _ready():
	# 1. Connect Sliders
	slider_master.value_changed.connect(_on_master_changed)
	slider_music.value_changed.connect(_on_music_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	
	# 2. Connect Buttons
	$MarginContainer/VBoxContainer/BtnTutorial.pressed.connect(_show_tutorial)
	$MarginContainer/VBoxContainer/BtnTerms.pressed.connect(_show_terms)
	$MarginContainer/VBoxContainer/BtnLogout.pressed.connect(_on_logout)
	$MarginContainer/VBoxContainer/BtnClose.pressed.connect(func(): visible = false)
	
	btn_back.pressed.connect(func(): info_panel.visible = false)
	
	# 3. Initialize Info Panel
	info_panel.visible = false

# --- VOLUME LOGIC ---
func _on_master_changed(value):
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	AudioServer.set_bus_mute(master_bus, value < 0.05) # Mute if near 0

func _on_music_changed(value):
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
	AudioServer.set_bus_mute(music_bus, value < 0.05)

func _on_sfx_changed(value):
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))
	AudioServer.set_bus_mute(sfx_bus, value < 0.05)

# --- INFO SCREENS ---
func _show_tutorial():
	info_text.text = "[center][b]HOW TO PLAY[/b][/center]\n\n" + \
	"- Buy Dinosaurs to earn DNA.\n" + \
	"- Carnivores hunt Herbivores if density is 0%.\n" + \
	"- Unlock Research to evolve your Habitat.\n" + \
	"- Find Fossils when dinos die to buy special upgrades!"
	info_panel.visible = true

func _show_terms():
	info_text.text = "[center][b]TERMS & CONDITIONS[/b][/center]\n\n" + \
	"1. Don't feed the T-Rex by hand.\n" + \
	"2. We are not responsible for lost limbs.\n" + \
	"3. Enjoy the evolution!"
	info_panel.visible = true

# --- LOGOUT LOGIC ---
func _on_logout():
	# 1. Clear Auth Data
	AuthManager.user_id = ""
	AuthManager.user_token = ""
	
	# 2. Save Game (Optional: Save before kicking them out)
	# var data = GameManager.get_save_dictionary()
	# AuthManager.save_game_to_cloud(data)
	
	# 3. Reset Game State
	# The easiest way is to reload the entire scene.
	# Since StartScreen appears if user_id is empty, it will show the login screen.
	get_tree().reload_current_scene()
