extends Control

@export var my_data: ResearchDef
@export var parent_node: Control 

# --- NODE PATHS ---
# Update these to match your exact Scene Tree!
# Based on your screenshots, these seem to be direct children, not in a VBox.
@onready var btn_node = $VBoxContainer/BtnNode
@onready var name_label = $VBoxContainer/NameLabel
@onready var cost_label = $VBoxContainer/CostLabel
@onready var line = $LinkLine
@onready var icon_rect = $IconRect # Ensure this node exists!

func _ready():
	# Connect the click
	btn_node.pressed.connect(_on_click)
	
	# Draw line to parent
	if parent_node:
		line.clear_points()
		line.add_point(size / 2) # My Center
		# Calculate Parent Center (Relative to me)
		var target = parent_node.position - position + (parent_node.size / 2)
		line.add_point(target)

	# Initial Visual Update
	_update_visuals()

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
		btn_node.disabled = false # Allow clicking (maybe to view details?)
		
	elif parent_unlocked:
		# --- AVAILABLE STATE ---
		modulate = Color(1, 1, 1) # Normal brightness
		icon_rect.modulate = Color(0, 0, 0, 0.8) # Silhouetted Icon (Mystery)
		
		cost_label.text = str(my_data.dna_cost) + " DNA"
		name_label.text = my_data.display_name # Show name so they know what to buy
		btn_node.disabled = false
		
	else:
		# --- LOCKED STATE ---
		modulate = Color(0.5, 0.5, 0.5) # Dimmed
		icon_rect.modulate = Color(0, 0, 0, 1) # Black Silhouette
		
		cost_label.text = "LOCKED"
		name_label.text = "???"
		btn_node.disabled = true

func _on_click():
	GameManager.try_unlock_research(my_data)
