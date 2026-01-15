extends Control

# ARRAYS: Drag your .tres files here!
@export var all_dinosaurs: Array[Resource]
@export var all_traits: Array[Resource]   # Leave empty for now if you don't have them
@export var all_habitats: Array[Resource] # Leave empty for now

# GRIDS (Inside the TabContainer)
@onready var dino_grid = $TabContainer/Dinosaurs/Grid
@onready var trait_grid = $TabContainer/Traits/Grid
@onready var habitat_grid = $TabContainer/Habitats/Grid

# UI
@onready var btn_close = $BtnClose # The bottom close button
@onready var detail_panel = $DetailPanel

@onready var btn_close_popup = $DetailPanel/BtnClosePopup

# Detail UI
@onready var d_img = $DetailPanel/MarginContainer/HBoxContainer/LargeImage
@onready var d_name = $DetailPanel/MarginContainer/HBoxContainer/VBoxContainer/NameLbl
@onready var d_desc = $DetailPanel/MarginContainer/HBoxContainer/VBoxContainer/DescLbl

var slot_scene = preload("res://scenes/ui/MuseumSlot.tscn")

func _ready():
# Hide popup at start
	detail_panel.visible = false
	
	# Bottom "Close Museum" Button
	btn_close.pressed.connect(func(): visible = false)
	
	# --- FIX FOR THE 'X' BUTTON ---
	# We connect the pressed signal to hide the panel
	btn_close_popup.pressed.connect(func(): 
		print("X Button Clicked") # Debug print to check if it works
		detail_panel.visible = false
	)
	
	# Fill the grid
	refresh_gallery()

func refresh_gallery():
	# 1. Populate Dinosaurs
	fill_grid(dino_grid, all_dinosaurs, "node_")
	
	# 2. Populate Traits (Future proofing)
	fill_grid(trait_grid, all_traits, "trait_")
	
	# 3. Populate Habitats (Future proofing)
	fill_grid(habitat_grid, all_habitats, "habitat_")

# A Helper function to fill ANY grid
func fill_grid(grid_node, data_array, prefix):
	# Clear old items
	for child in grid_node.get_children():
		child.queue_free()
		
	for item in data_array:
		var is_unlocked = false
		
		# Check Unlock Logic
		if "species_name" in item:
			# It's a Dino
			var id = prefix + item.species_name.to_lower()
			if id in GameManager.unlocked_research_ids or item.species_name == "Archosaur":
				is_unlocked = true
				
		# Create Slot
		var slot = slot_scene.instantiate()
		grid_node.add_child(slot)
		slot.setup(item, is_unlocked)
		slot.slot_clicked.connect(_on_slot_clicked)

func _on_slot_clicked(data):
	# Show Details
	if "icon" in data: d_img.texture = data.icon
	if "species_name" in data: d_name.text = data.species_name
	if "description" in data: d_desc.text = data.description
	
	detail_panel.visible = true
