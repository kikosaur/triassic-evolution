extends Control

@onready var scroll_container = $ScrollContainer

# --- DRAG LOGIC ---
var _is_dragging: bool = false

func _ready():
	# Sync initial state
	_on_visibility_changed()
	
	# Connect signal
	visibility_changed.connect(_on_visibility_changed)
	
	# Connect ScrollContainer input for drag logic
	if scroll_container:
		scroll_container.gui_input.connect(_on_scroll_input)

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

func _on_scroll_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = event.pressed
			
	elif event is InputEventMouseMotion and _is_dragging:
		# Inverse the relative motion to "pull" the map
		scroll_container.scroll_horizontal -= event.relative.x
		scroll_container.scroll_vertical -= event.relative.y
