extends PanelContainer

@export var species_data: DinosaurSpecies
@export var required_research_id: String = "" # e.g. "node_eoraptor"

@onready var icon = $HBoxContainer/Icon
@onready var name_lbl = $HBoxContainer/InfoBox/NameLabel
@onready var stats_lbl = $HBoxContainer/InfoBox/StatsLabel
@onready var buy_btn = $HBoxContainer/InfoBox/BuyBtn

func _ready():
	# Setup Visuals
	if species_data:
		name_lbl.text = species_data.species_name
		stats_lbl.text = "Cost: " + str(species_data.base_dna_cost) + " | Yield: " + str(species_data.dna_yield)
		icon.texture = species_data.icon
		# Color the icon so they don't all look the same (Optional)
		# icon.modulate = Color(randf(), randf(), randf()) 
	
	buy_btn.pressed.connect(_on_buy)

func _process(_delta):
	# 1. CHECK VISIBILITY (Is it unlocked?)
	if required_research_id != "":
		# If we don't own the research, HIDE this item
		if required_research_id not in GameManager.unlocked_research_ids:
			visible = false
		else:
			visible = true
	
	# 2. CHECK AFFORDABILITY (Can we buy it?)
	if species_data:
		if GameManager.current_dna >= species_data.base_dna_cost:
			buy_btn.disabled = false
			buy_btn.text = "BUY"
		else:
			buy_btn.disabled = true
			buy_btn.text = "NO DNA"

func _on_buy():
	if GameManager.try_spend_dna(species_data.base_dna_cost):
		# Spawn logic must be handled by MainGame, or we use a Global Signal.
		# Let's use the Global Signal we made in GameManager!
		GameManager.emit_signal("dinosaur_spawned", species_data)
