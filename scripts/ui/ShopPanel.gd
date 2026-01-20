extends Panel

const ITEM_SCENE = preload("res://scenes/ui/ShopItem.tscn")

# 1. NEW REFERENCES (We now have TWO grids)
@onready var dino_grid = $TabContainer/Dinosaurs/MarginContainer/DinoGrid
@onready var hab_grid = $TabContainer/Habitats/MarginContainer/HabGrid

@export var dino_products: Array[Resource] = []
@export var habitat_products: Array[Resource] = []

func _ready():
	_populate_shop()
	if GameManager.has_signal("research_unlocked"):
		GameManager.connect("research_unlocked", _refresh_locks)

func _populate_shop():
	# 1. CLEAR OLD ITEMS (From both grids)
	for child in dino_grid.get_children(): child.queue_free()
	for child in hab_grid.get_children(): child.queue_free()
	
	# 2. FILL DINO TAB
	for dino in dino_products:
		_create_card(dino, null, dino_grid)
		
	# 3. FILL HABITAT TAB
	for hab in habitat_products:
		_create_card(null, hab, hab_grid)

# We added a 'target_grid' argument so we know where to put the card
func _create_card(dino_data, hab_data, target_grid):
	var card = ITEM_SCENE.instantiate()
	target_grid.add_child(card) # Add to the specific grid
	
	# Setup Data
	card.species_data = dino_data
	card.habitat_data = hab_data
	
	if dino_data and "required_research_id" in dino_data:
		card.required_research_id = dino_data.required_research_id
	
	if card.has_method("_update_display"):
		card._update_display()

func _refresh_locks(_id):
	# Refresh both grids
	for card in dino_grid.get_children(): card._process(0)
	for card in hab_grid.get_children(): card._process(0)

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
	card._process(0)
