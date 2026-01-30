extends Control

@export var my_data: ResearchDef
@export var parent_node: Control

# --- NODE PATHS ---
@onready var click_btn = $ClickButton
@onready var name_label = $VBoxContainer/NameLabel
@onready var cost_label = $VBoxContainer/CostLabel
@onready var line = $LinkLine
@onready var icon_rect = $VBoxContainer/IconRect

func _ready():
	# Connect the click
	click_btn.pressed.connect(_on_click)
	
	# Draw line to parent
	if parent_node:
		_draw_stepped_line()

	# Initial Visual Update
	_update_visuals()

func _draw_stepped_line():
	line.clear_points()
	
	# TARGETING FIX:
	# Use IconRect center (40, 40) instead of Control center (40, 70).
	# This ensures the line comes out of the "Image" part of the node.
	var icon_center = Vector2(size.x / 2, 40) # Hardcoded 80x80 icon / 2 = 40
	# Or dynamically: 
	# var icon_center = icon_rect.position + (icon_rect.size / 2)
	
	# Start at My Icon Center
	var start = icon_center
	
	# End at Parent Icon Center (Relative)
	# parent_node.position - position gets us to Parent Top-Left (Relative to me).
	# Then add parent's icon offset (40, 40).
	var relative_parent_pos = parent_node.position - position
	var end = relative_parent_pos + icon_center
	
	# Calculate Midpoint for "Dogleg" / "Manhattan" connection
	var mid_x = (start.x + end.x) / 2
	
	line.add_point(start)
	line.add_point(Vector2(mid_x, start.y))
	line.add_point(Vector2(mid_x, end.y))
	line.add_point(end)

func _on_click():
	# Find the menu and open popup
	var menu = find_parent("ResearchMenu")
	if menu and menu.has_method("open_research_popup"):
		menu.open_research_popup(my_data)
	else:
		# Fallback/Debug
		print("ResearchNode: Could not find ResearchMenu!")

func _process(_delta):
	# Keep checking visuals (useful if unlocked status changes)
	_update_visuals()

func _update_visuals():
	if not my_data: return
	
	# 1. SETUP ICON (Load image from data)
	if my_data.icon and icon_rect.texture != my_data.icon:
		icon_rect.texture = my_data.icon

	# 2. CHECK STATUS
	var is_unlocked = GameManager.is_research_unlocked(my_data)
	var parent_unlocked = true
	if my_data.parent_research:
		parent_unlocked = GameManager.is_research_unlocked(my_data.parent_research)
	
	# 3. APPLY VISUALS
	if is_unlocked:
		# --- OWNED STATE ---
		modulate = Color(1, 1, 1) # Full Color
		icon_rect.modulate = Color(1, 1, 1) # Normal Icon
		cost_label.text = "OWNED"
		name_label.text = my_data.display_name
		click_btn.disabled = false
		
		# Design: Gold Line for established connection
		line.default_color = Color(1, 0.8, 0, 1) # Gold
		line.width = 6.0
		
	elif parent_unlocked:
		# --- AVAILABLE STATE ---
		modulate = Color(1, 1, 1) # Normal brightness
		icon_rect.modulate = Color(0, 0, 0, 0.8) # Silhouetted Icon (Mystery)
		
		# Show Costs
		cost_label.text = "UNLOCK"
		name_label.text = my_data.display_name
		
		click_btn.disabled = false
		
		# Design: White Pulse? Just White for now
		line.default_color = Color(1, 1, 1, 0.5)
		line.width = 4.0
		
	else:
		# --- LOCKED STATE ---
		modulate = Color(0.5, 0.5, 0.5) # Dimmed
		icon_rect.modulate = Color(0, 0, 0, 1) # Black Silhouette
		
		cost_label.text = "LOCKED"
		name_label.text = "???"
		click_btn.disabled = true
		
		# Design: Dim Line
		line.default_color = Color(0.3, 0.3, 0.3, 0.5)
		line.width = 3.0
