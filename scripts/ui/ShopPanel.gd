extends Panel

const ITEM_SCENE = preload("res://scenes/ui/ShopItem.tscn")

# 1. NEW REFERENCES (We now have TWO grids)
@onready var dino_grid = $TabContainer/Dinosaurs/MarginContainer/DinoGrid
@onready var hab_grid = $TabContainer/Habitats/MarginContainer/HabGrid

@export var dino_products: Array[Resource] = []
@export var habitat_products: Array[Resource] = []

# --- DRAG LOGIC ---
var _is_dragging: bool = false
var _active_scroll: ScrollContainer = null

func _ready():
	print("[FlowCheck] ShopPanel _ready called")
	# OPTIMIZATION: Pre-load items instantly!
	_populate_shop()
	
	if GameManager.has_signal("research_unlocked"):
		GameManager.connect("research_unlocked", _refresh_locks)
	
	visibility_changed.connect(_on_visibility_changed)
	
	# Start hidden (simple visibility)
	visible = false
	
	# Setup drag for both scroll containers
	var dino_scroll = $TabContainer/Dinosaurs
	var hab_scroll = $TabContainer/Habitats
	
	if dino_scroll:
		dino_scroll.gui_input.connect(func(event): _on_scroll_input(event, dino_scroll))
	if hab_scroll:
		hab_scroll.gui_input.connect(func(event): _on_scroll_input(event, hab_scroll))

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
	var scrolls = [$TabContainer/Dinosaurs, $TabContainer/Habitats]
	for s in scrolls:
		if visible:
			s.process_mode = PROCESS_MODE_INHERIT
		else:
			s.process_mode = PROCESS_MODE_DISABLED

func _populate_shop():
	# OPTIMIZATION: Only instantiate if empty
	if dino_grid.get_child_count() > 0:
		_refresh_items()
		return

	# 1. CLEAR OLD ITEMS (Only if force reset needed, but here we assume safe start)
	for child in dino_grid.get_children(): child.queue_free()
	for child in hab_grid.get_children(): child.queue_free()
	
	# 2. FILL DINO TAB
	for dino in dino_products:
		if not dino: continue # Skip empty slots
		_create_card(dino, null, dino_grid)
		
	# 3. FILL HABITAT TAB
	for hab in habitat_products:
		if not hab: continue # Skip empty slots
		_create_card(null, hab, hab_grid)

func _refresh_items():
	# Update all existing cards
	for card in dino_grid.get_children():
		if card.has_method("_check_lock_status"): card._check_lock_status()
		if card.has_method("_update_display"): card._update_display()
		
	for card in hab_grid.get_children():
		if card.has_method("_check_lock_status"): card._check_lock_status()
		if card.has_method("_update_display"): card._update_display()

# We added a 'target_grid' argument so we know where to put the card
func _create_card(dino_data, hab_data, target_grid):
	var card = ITEM_SCENE.instantiate()
	target_grid.add_child(card) # Add to the specific grid
	
	# Setup Data
	card.species_data = dino_data
	card.habitat_data = hab_data
	
	# Copy research requirements for dinosaurs
	if dino_data and "required_research_id" in dino_data:
		card.required_research_id = dino_data.required_research_id
	
	# Copy research requirements for habitat items
	if hab_data and "required_research_id" in hab_data:
		card.required_research_id = hab_data.required_research_id
	
	if card.has_method("_update_display"):
		card._update_display()

func _refresh_locks(_id):
	# Refresh both grids
	# Refresh both grids
	for card in dino_grid.get_children():
		if card.has_method("_check_lock_status"): card._check_lock_status()
	for card in hab_grid.get_children():
		if card.has_method("_check_lock_status"): card._check_lock_status()

func _add_item_to_grid(dino_data, hab_data, target_grid):
	var card = ITEM_SCENE.instantiate()
	target_grid.add_child(card)
	
	card.species_data = dino_data
	card.habitat_data = hab_data
	
	# 1. READ THE KEY FROM THE DINO DATA
	if dino_data and dino_data.required_research_id != "":
		card.required_research_id = dino_data.required_research_id
		
	# 2. READ THE KEY FROM HABITAT DATA
	elif hab_data and "required_research_id" in hab_data:
		# (Only works if you added the variable to HabitatProduct.gd too)
		if hab_data.required_research_id != "":
			card.required_research_id = hab_data.required_research_id
	
	# 3. FORCE UPDATE
	if card.has_method("_update_display"):
		card._update_display()
	
	# 4. RE-RUN VISIBILITY CHECK IMMEDIATELY
	# 4. RE-RUN VISIBILITY CHECK IMMEDIATELY
	if card.has_method("_check_lock_status"):
		card._check_lock_status()

func open_shop_popup(item_data):
	var popup = $ShopPopup
	if popup:
		if item_data is DinosaurSpecies:
			popup.setup_dinosaur(item_data)
		elif item_data is HabitatProduct:
			popup.setup_habitat(item_data)
