extends Control

# ARRAYS: Drag your .tres files here!
@export var all_dinosaurs: Array[Resource]
@export var all_traits: Array[Resource] # Leave empty for now if you don't have them
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
@onready var d_sci = $DetailPanel/MarginContainer/HBoxContainer/VBoxContainer/SciNameLbl
@onready var d_year = $DetailPanel/MarginContainer/HBoxContainer/VBoxContainer/YearLbl
@onready var d_desc = $DetailPanel/MarginContainer/HBoxContainer/VBoxContainer/DescLbl

var slot_scene = preload("res://scenes/ui/MuseumSlot.tscn")

func _ready():
# Hide popup at start
	detail_panel.visible = false
	
	# Bottom "Close Museum" Button
	btn_close.pressed.connect(func(): visible = false)
	
	# --- CLOSE POPUP BUTTON ---
	btn_close_popup.pressed.connect(func():
		detail_panel.visible = false
	)
	
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

func _on_visibility_changed():
	var scrolls = [$TabContainer/Dinosaurs, $TabContainer/Traits, $TabContainer/Habitats]
	for s in scrolls:
		if visible:
			s.visible = true
			s.process_mode = PROCESS_MODE_INHERIT
		else:
			s.visible = false
			s.process_mode = PROCESS_MODE_DISABLED
	
	# 3. Listen for visibility to refresh only when open
	visibility_changed.connect(func(): if visible: refresh_gallery())
	
	# Fill data but dont instantiate UI yet
	_load_dynamic_resources()
	# refresh_gallery() # Defer to visibility

func _load_dynamic_resources():
	all_traits.clear()
	all_habitats.clear()
	
	# FIX for Mobile: Use Registry instead of DirAccess scanning
	all_traits.append_array(ResourceRegistry.TRAIT_FILES)
	all_habitats.append_array(ResourceRegistry.HABITAT_FILES)
	
	# _load_folder("res://resources/traits/", all_traits)
	# _load_folder("res://resources/habitats/", all_habitats)
	
	# Optional: Sort by Name
	all_traits.sort_custom(func(a, b): return a.display_name < b.display_name)
	all_habitats.sort_custom(func(a, b): return a.display_name < b.display_name)

func _load_folder(path, target_array):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(path + file_name)
				if res: target_array.append(res)
			file_name = dir.get_next()

func refresh_gallery():
	# 1. Populate Dinosaurs
	fill_grid(dino_grid, all_dinosaurs, "node_")
	
	# 2. Populate Traits (Future proofing)
	fill_grid(trait_grid, all_traits, "trait_")
	
	# 3. Populate Habitats (Future proofing)
	fill_grid(habitat_grid, all_habitats, "habitat_")

# A Helper function to fill ANY grid
func fill_grid(grid_node, data_array, _prefix):
	# Clear old items
	for child in grid_node.get_children():
		child.queue_free()
		
	for item in data_array:
		var is_unlocked = false
		
		# Check Unlock Logic
		# Check Unlock Logic
		if "species_name" in item and item.species_name == "Archosaur":
			is_unlocked = true # Starter
		elif "required_research_id" in item:
			# Universal Check: Does the user have the research?
			if item.required_research_id in GameManager.unlocked_research_ids:
				is_unlocked = true
				
		# Create Slot
		var slot = slot_scene.instantiate()
		grid_node.add_child(slot)
		slot.setup(item, is_unlocked)
		slot.slot_clicked.connect(_on_slot_clicked)

func _on_slot_clicked(data):
	# Show Details
	# Details
	if "icon" in data: d_img.texture = data.icon
	if "species_name" in data: d_name.text = data.species_name
	elif "display_name" in data: d_name.text = data.display_name
	if "description" in data: d_desc.text = data.description
	
	# Fix: Populate Scientific Name and Year
	if "scientific_name" in data: d_sci.text = data.scientific_name
	else: d_sci.text = ""
		
	if "time_period" in data: d_year.text = data.time_period
	else: d_year.text = ""
	
	detail_panel.visible = true
