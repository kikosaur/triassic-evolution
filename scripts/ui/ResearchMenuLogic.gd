extends Control

@onready var scroll_container = $ScrollContainer

func _ready():
	# Sync initial state
	_on_visibility_changed()
	
	# Connect signal
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if scroll_container:
		# If the menu is hidden, disable the scroll container's processing/physics
		# This prevents it from trying to calculate layout or access viewport while hidden
		if visible:
			scroll_container.visible = true
			scroll_container.process_mode = PROCESS_MODE_INHERIT
		else:
			scroll_container.visible = false
			scroll_container.process_mode = PROCESS_MODE_DISABLED
