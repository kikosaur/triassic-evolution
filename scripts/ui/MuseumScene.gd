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
@onready var d_name = $DetailPanel/MarginContainer/HBoxContainer/InfoContainer/NameLbl
@onready var d_sci = $DetailPanel/MarginContainer/HBoxContainer/InfoContainer/SciNameLbl
@onready var d_size = $DetailPanel/MarginContainer/HBoxContainer/InfoContainer/SizeLabel
@onready var d_diet = $DetailPanel/MarginContainer/HBoxContainer/InfoContainer/DietLabel
@onready var d_desc = $DetailPanel/MarginContainer/HBoxContainer/InfoContainer/DescLbl

var slot_scene = preload("res://scenes/ui/MuseumSlot.tscn")

# --- DRAG LOGIC ---
var _is_dragging: bool = false
var _active_scroll: ScrollContainer = null

func _ready():
	print("[FlowCheck] MuseumScene _ready called")
# Hide popup at start
	detail_panel.visible = false
	
	# Bottom "Close Museum" Button
	btn_close.pressed.connect(func(): visible = false)
	
	# --- CLOSE POPUP BUTTON ---
	btn_close_popup.pressed.connect(func():
		detail_panel.visible = false
	)
	
	# Set default tab to Dinosaurs (index 0)
	var tab_container = $TabContainer
	tab_container.current_tab = 0
	
	visibility_changed.connect(_on_visibility_changed)
	
	# OPTIMIZATION: Load resources ONCE at startup, not every open.
	_load_dynamic_resources()
	refresh_gallery() # Build UI immediately (Pre-load)
	
	# Start hidden (simple visibility)
	visible = false
	
	# Setup drag for all three scroll containers
	var dino_scroll = $TabContainer/Dinosaurs
	var trait_scroll = $TabContainer/Traits
	var habitat_scroll = $TabContainer/Habitats
	
	if dino_scroll:
		dino_scroll.gui_input.connect(func(event): _on_scroll_input(event, dino_scroll))
	if trait_scroll:
		trait_scroll.gui_input.connect(func(event): _on_scroll_input(event, trait_scroll))
	if habitat_scroll:
		habitat_scroll.gui_input.connect(func(event): _on_scroll_input(event, habitat_scroll))

func _on_scroll_input(event, scroll_container):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = event.pressed
			if event.pressed:
				_active_scroll = scroll_container
			else:
				_active_scroll = null
			
	elif event is InputEventMouseMotion and _is_dragging and _active_scroll:
		# Inverse the relative motion to "pull" the content
		_active_scroll.scroll_horizontal -= event.relative.x
		_active_scroll.scroll_vertical -= event.relative.y

func _on_visibility_changed():
	# Process mode control
	var scrolls = [$TabContainer/Dinosaurs, $TabContainer/Traits, $TabContainer/Habitats]
	for s in scrolls:
		if visible:
			s.process_mode = PROCESS_MODE_INHERIT
			# Reset to Dinosaurs tab when opening
			$TabContainer.current_tab = 0
		else:
			s.process_mode = PROCESS_MODE_DISABLED

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

# A Helper function to fill ANY grid (OPTIMIZED)
func fill_grid(grid_node, data_array, _prefix):
	# OPTIMIZATION: If grid is already full, just refresh
	if grid_node.get_child_count() == data_array.size():
		var i = 0
		for child in grid_node.get_children():
			var item = data_array[i]
			var is_unlocked = _check_unlock_status(item)
			if child.has_method("setup"):
				child.setup(item, is_unlocked)
			i += 1
		return

	# Clear old items (Only if count mismatch or force reset)
	for child in grid_node.get_children():
		child.queue_free()
		
	for item in data_array:
		var is_unlocked = _check_unlock_status(item)
				
		# Create Slot
		var slot = slot_scene.instantiate()
		grid_node.add_child(slot)
		slot.setup(item, is_unlocked)
		slot.slot_clicked.connect(_on_slot_clicked)

func _check_unlock_status(item) -> bool:
	if "species_name" in item and item.species_name == "Archosaur":
		return true # Starter
	elif "required_research_id" in item:
		# Universal Check: Does the user have the research?
		if item.required_research_id in GameManager.unlocked_research_ids:
			return true
	return false

func _on_slot_clicked(data):
	# Show Details
	if "icon" in data: d_img.texture = data.icon
	if "species_name" in data: d_name.text = data.species_name
	elif "display_name" in data: d_name.text = data.display_name
	if "description" in data: d_desc.text = data.description
	
	# Populate Scientific Name
	if "scientific_name" in data: d_sci.text = "[i]" + data.scientific_name + "[/i]"
	else: d_sci.text = ""
	
	# Populate Size
	if "length" in data: d_size.text = "Size: " + data.length
	else: d_size.text = ""
	
	# Populate Diet
	if "diet" in data:
		if data.diet == DinosaurSpecies.Diet.CARNIVORE:
			d_diet.text = "Diet: Carnivore"
		else:
			d_diet.text = "Diet: Herbivore"
	else:
		d_diet.text = ""
	
	detail_panel.visible = true
