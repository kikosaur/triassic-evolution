extends Node

@onready var sfx_player = $SFX_Player
@onready var music_player = $Music_Player

# --- SOUND LIBRARY ---
# Drag your .wav/.ogg files here in the Inspector
@export var sfx_click: AudioStream
@export var sfx_success: AudioStream
@export var music_main: AudioStream

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
