extends Panel # Changed from PanelContainer to match the new "Card" root

@export var species_data: DinosaurSpecies
@export var habitat_data: HabitatProduct
@export var required_research_id: String = ""

# --- UPDATED UI REFERENCES (Vertical Layout) ---
@onready var icon_rect = $MarginContainer/VBoxContainer/IconRect
@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
@onready var price_lbl = $MarginContainer/VBoxContainer/PriceLabel # We use this for Cost/Stats now
@onready var buy_btn = $MarginContainer/VBoxContainer/BuyButton
@onready var diet_icon = %DietIcon

# Preload diet icons
var herbivore_icon = preload("res://assets/ui/herbivore_icon.svg")
var carnivore_icon = preload("res://assets/ui/carnivore_icon.svg")

func _ready():
	buy_btn.pressed.connect(_on_buy)
	_update_display()

func _update_display():
	# CASE 1: SELLING A DINO
	if species_data:
		name_lbl.text = species_data.species_name
		var cost = GameManager.get_dino_cost(species_data)
		price_lbl.text = GameManager.format_number(cost) + " DNA"
		if species_data.icon:
			icon_rect.texture = species_data.icon
		
		# Set diet icon
		if species_data.diet == DinosaurSpecies.Diet.HERBIVORE:
			diet_icon.texture = herbivore_icon
			diet_icon.visible = true
		else: # CARNIVORE
			diet_icon.texture = carnivore_icon
			diet_icon.visible = true
	
	# CASE 2: SELLING HABITAT
	elif habitat_data:
		name_lbl.text = habitat_data.name
		var cost = GameManager.get_habitat_cost(habitat_data)
		# Format: "500 DNA | +10%"
		price_lbl.text = GameManager.format_number(cost) + " DNA\n+" + str(habitat_data.density_gain) + "% Density"
		if habitat_data.icon:
			icon_rect.texture = habitat_data.icon
		
		# Hide diet icon for habitats
		diet_icon.visible = false

func _process(_delta):
	# 1. VISIBILITY CHECK (The "Locked" System) (Unchanged)
	if required_research_id != "":
		visible = (required_research_id in GameManager.unlocked_research_ids)

	# 2. AFFORDABILITY CHECK
	var cost = 0
	if species_data:
		cost = GameManager.get_dino_cost(species_data)
	if habitat_data:
		cost = GameManager.get_habitat_cost(habitat_data)
	
	if GameManager.current_dna >= cost:
		buy_btn.disabled = false
		buy_btn.text = "HATCH" if species_data else "BUILD"
	else:
		buy_btn.disabled = true
		buy_btn.text = "NEED DNA"

func _on_buy():
	# BUYING DINO
	AudioManager.play_sfx("click")
	if species_data:
		var cost = GameManager.get_dino_cost(species_data)
		if GameManager.try_spend_dna(cost):
			GameManager.trigger_dino_spawn(species_data)
			_update_display() # Update price for next one!
			
	# BUYING HABITAT
	elif habitat_data:
		var cost = GameManager.get_habitat_cost(habitat_data)
		if GameManager.try_spend_dna(cost):
			if habitat_data.type == HabitatProduct.ProductType.VEGETATION:
				GameManager.vegetation_density += habitat_data.density_gain
			else:
				GameManager.critter_density += habitat_data.density_gain
			
			# Clamp to 100%
			if GameManager.vegetation_density > 100: GameManager.vegetation_density = 100
			if GameManager.critter_density > 100: GameManager.critter_density = 100
			
			GameManager.emit_signal("habitat_updated", GameManager.vegetation_density, GameManager.critter_density)
			_update_display() # Update price!
