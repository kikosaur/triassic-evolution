extends Node2D

@onready var click_zone = $ClickZone
@onready var dino_container = $DinoContainer
@onready var dna_label = $UI_Layer/TopPanel/DNALabel

# DRAG TEXTURES HERE IN INSPECTOR!
@export var phase_1_tex: Texture2D # Desert [cite: 19]
@export var phase_2_tex: Texture2D # Oasis [cite: 21]
@export var phase_3_tex: Texture2D # Jungle [cite: 23]

# BACKGROUND
@onready var layer_water = $WorldArt/Layer_Water
@onready var layer_ferns = $WorldArt/Layer_Ferns
@onready var layer_trees = $WorldArt/Layer_Trees

# EXISTING EXPORTS
@export var dino_scene: PackedScene 
@export var archosaur_res: Resource 

# RESEARCH
@onready var research_menu = $UI_Layer/ResearchMenu
@onready var btn_research = $UI_Layer/BtnToggleResearch

# DINO SHOP
@onready var shop_panel = $UI_Layer/ShopPanel
@onready var btn_shop = $UI_Layer/BtnToggleShop

@onready var extinction_panel = $UI_Layer/ExtinctionPanel

func _ready():
	print("Main Game Started")
	click_zone.pressed.connect(_on_background_clicked)
	# Listen for Habitat Changes
	
	btn_research.pressed.connect(func(): research_menu.visible = !research_menu.visible)
	
	GameManager.connect("extinction_triggered", _show_extinction)
	
	GameManager.connect("dinosaur_spawned", _spawn_dino)
	
	# --- TOGGLE LOGIC ---
	# Open/Close the Shop
	btn_shop.pressed.connect(func(): 
		shop_panel.visible = !shop_panel.visible
		# Optional: Close Research if opening Shop (to avoid overlap)
		if shop_panel.visible:
			research_menu.visible = false
		)

func _on_background_clicked():
	GameManager.add_dna(5) # Increased to 5 to make testing faster!

func _on_buy_pressed():
	if GameManager.try_spend_dna(archosaur_res.base_dna_cost):
		spawn_dino(archosaur_res)

func spawn_dino(species):
	var new_dino = dino_scene.instantiate()
	new_dino.species_data = species
	new_dino.position = Vector2(640, 500)
	dino_container.add_child(new_dino)

func _show_extinction():
	extinction_panel.visible = true
	# Optional: Play a sound or shake screen here

func _spawn_dino(species_res: DinosaurSpecies):
	var new_dino = load("res://scenes/units/DinoUnit.tscn").instantiate()
	new_dino.species_data = species_res
	new_dino.position = Vector2(500, 300) # Center spawn
	dino_container.add_child(new_dino)

func _process(_delta):
	# Check the unlocked list in GameManager
	if "node_pools" in GameManager.unlocked_research_ids:
		layer_water.visible = true
	
	if "node_ferns" in GameManager.unlocked_research_ids:
		layer_ferns.visible = true
		
	if "node_forest" in GameManager.unlocked_research_ids:
		layer_trees.visible = true
	var total_dps = 0
	for dino in dino_container.get_children():
		if not dino.is_dead and dino.species_data:
			total_dps += dino.species_data.passive_dna_yield
	
	dna_label.text = "DNA: " + str(GameManager.current_dna) + " (+" + str(total_dps) + "/s)"
