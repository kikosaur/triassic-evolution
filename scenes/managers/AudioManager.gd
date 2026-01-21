extends Node

@onready var sfx_player = $SFX_Player
@onready var music_player = $Music_Player

# --- SOUND LIBRARY ---
# Drag your .wav/.ogg files here in the Inspector
@export var sfx_click: AudioStream
@export var sfx_success: AudioStream
@export var music_main: AudioStream

func _ready():
	# Loop Music
	music_player.finished.connect(func(): music_player.play())

func play_sfx(sound_name: String):
	# Choose the sound based on the name
	if sound_name == "click":
		sfx_player.stream = sfx_click
	elif sound_name == "success":
		sfx_player.stream = sfx_success
	
	# Randomize pitch slightly for variety (optional)
	sfx_player.pitch_scale = randf_range(0.9, 1.1)
	sfx_player.play()

func play_music():
	if music_player.stream != music_main:
		music_player.stream = music_main
		music_player.play()

func set_music_volume(value: float):
	# 1. Find the index of the Music bus
	var bus_index = AudioServer.get_bus_index("Music")
	
	# 2. Convert 0-1 slider value to Decibels (Logarithmic)
	# If value is 0, we mute it entirely
	if value <= 0.05:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func set_sfx_volume(value: float):
	var bus_index = AudioServer.get_bus_index("SFX")
	
	if value <= 0.05:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func set_master_volume(value: float):
	# The "Master" bus is always index 0, but searching by name is safer
	var bus_index = AudioServer.get_bus_index("Master")
	
	if value <= 0.05:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
