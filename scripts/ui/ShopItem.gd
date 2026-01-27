extends Panel

@export var species_data: DinosaurSpecies
@export var habitat_data: HabitatProduct

@export var required_research_id: String = ""

@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
# @onready var price_lbl = ... (Removed)
@onready var dna_lbl = $MarginContainer/VBoxContainer/CostContainer/HBoxDNA/Label
@onready var fos_lbl = $MarginContainer/VBoxContainer/CostContainer/HBoxFossil/Label

@onready var icon_rect = $MarginContainer/VBoxContainer/IconRect
@onready var diet_icon = %DietIcon # Unique Name
@onready var click_btn = $ClickButton

func _ready():
	click_btn.pressed.connect(_on_click)
	
	# Optimization: Listen for unlock events instead of polling in _process
	if GameManager.has_signal("research_unlocked"):
		GameManager.connect("research_unlocked", _on_research_unlocked)
		
	# Initial Checks
	_setup_static_icons()
	_update_display()
	_check_lock_status()

func _setup_static_icons():
	# Manually load icons to avoid .tscn Parse Errors with new assets
	var dna_icon = $MarginContainer/VBoxContainer/CostContainer/HBoxDNA/Icon
	var fos_icon = $MarginContainer/VBoxContainer/CostContainer/HBoxFossil/Icon
	
	dna_icon.texture = load("res://assets/ui/dna_icon.svg")
	fos_icon.texture = load("res://assets/ui/fossil_icon.svg")

	
func _on_research_unlocked(_id):
	_check_lock_status()
	
func _check_lock_status():
	var is_locked = false
	
	# Check if this item requires research and if that research is unlocked
	if required_research_id != "":
		if required_research_id not in GameManager.unlocked_research_ids:
			is_locked = true
			
	if is_locked:
		modulate = Color(0.5, 0.5, 0.5) # Dimmed
		click_btn.disabled = true
	else:
		modulate = Color(1, 1, 1)
		click_btn.disabled = false

func _update_display():
	# CASE 1: SELLING DINOSAUR
	if species_data:
		name_lbl.text = species_data.species_name
		
		# Show DNA Cost / Fossil Cost
		var cost_dna = GameManager.get_dino_cost(species_data)
		var cost_fos = GameManager.get_dino_fossil_cost(species_data)
		
		dna_lbl.text = GameManager.format_number(cost_dna)
		fos_lbl.text = str(cost_fos)
		
		if species_data.icon:
			icon_rect.texture = species_data.icon
			
		# Diet Icon Logic (Optional, keep if previously existing)
		match species_data.diet:
			0: diet_icon.modulate = Color(0, 1, 0) # Green (Herb)
			1: diet_icon.modulate = Color(1, 0, 0) # Red (Carn)
			2: diet_icon.modulate = Color(1, 1, 0) # Omnivore
			
	# CASE 2: SELLING HABITAT
	elif habitat_data:
		name_lbl.text = habitat_data.name
		var cost = GameManager.get_habitat_cost(habitat_data)
		var cost_fos = habitat_data.fossil_cost if "fossil_cost" in habitat_data else 1
		
		dna_lbl.text = GameManager.format_number(cost)
		fos_lbl.text = str(cost_fos)
		
		if habitat_data.icon:
			icon_rect.texture = habitat_data.icon
		
		# Clear Diet Icon for Habitats
		diet_icon.texture = null
		
	# FORCE LOCK CHECK ON UPDATE
	_check_lock_status()

func _on_click():
	# Double check lock
	if click_btn.disabled: return

	# Find parent ShopPanel and open popup
	var shop = find_parent("ShopPanel")
	if shop and shop.has_method("open_shop_popup"):
		if species_data:
			shop.open_shop_popup(species_data)
		elif habitat_data:
			shop.open_shop_popup(habitat_data)
	else:
		print("ShopItem: Could not find ShopPanel!")
