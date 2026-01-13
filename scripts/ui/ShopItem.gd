extends PanelContainer

@export var species_data: DinosaurSpecies
@export var habitat_data: HabitatProduct # NEW VARIABLE
@export var required_research_id: String = "" # e.g. "node_eoraptor"

@onready var icon = $HBoxContainer/Icon
@onready var name_lbl = $HBoxContainer/InfoBox/NameLabel
@onready var stats_lbl = $HBoxContainer/InfoBox/StatsLabel
@onready var buy_btn = $HBoxContainer/InfoBox/BuyBtn

func _ready():
	buy_btn.pressed.connect(_on_buy)
	_update_display()

func _update_display():
	# CASE 1: SELLING A DINO
	if species_data:
		name_lbl.text = species_data.species_name
		stats_lbl.text = "Cost: " + str(species_data.base_dna_cost)
		icon.texture = species_data.icon
	
	# CASE 2: SELLING HABITAT (NEW)
	elif habitat_data:
		name_lbl.text = habitat_data.name
		stats_lbl.text = "Cost: " + str(habitat_data.dna_cost) + " | +" + str(habitat_data.density_gain) + "%"
		icon.texture = habitat_data.icon

func _process(_delta):
	# 1. CHECK VISIBILITY (Is it unlocked?)
	if required_research_id != "":
		# If we don't own the research, HIDE this item
		if required_research_id not in GameManager.unlocked_research_ids:
			visible = false
		else:
			visible = true
			
	
	# CHECK AFFORDABILITY
	var cost = 0
	if species_data: cost = species_data.base_dna_cost
	if habitat_data: cost = habitat_data.dna_cost
	
	if GameManager.current_dna >= cost:
		buy_btn.disabled = false
		buy_btn.text = "BUY"
	else:
		buy_btn.disabled = true
		buy_btn.text = "NO DNA"

func _on_buy():
	# BUYING DINO
	if species_data:
		if GameManager.try_spend_dna(species_data.base_dna_cost):
			GameManager.trigger_dino_spawn(species_data)
			
	# BUYING HABITAT
	elif habitat_data:
		if GameManager.try_spend_dna(habitat_data.dna_cost):
			if habitat_data.type == HabitatProduct.ProductType.VEGETATION:
				GameManager.vegetation_density += habitat_data.density_gain
			else:
				GameManager.critter_density += habitat_data.density_gain
			
			# Clamp to 100%
			if GameManager.vegetation_density > 100: GameManager.vegetation_density = 100
			if GameManager.critter_density > 100: GameManager.critter_density = 100
			
			# Notify UI
			GameManager.emit_signal("habitat_updated", GameManager.vegetation_density, GameManager.critter_density)
