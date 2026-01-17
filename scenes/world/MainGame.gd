extends Node2D

@onready var click_zone = $ClickZone
@onready var dino_container = $DinoContainer
@onready var dna_label = $UI_Layer/TopPanel/DNALabel
@onready var fossil_label = $UI_Layer/TopPanel/FossilLabel
@onready var background_sprite = $WorldArt/Background # Make sure this points to your BG!

@export_group("Biome Transitions")
@export var bg_01_base: Texture2D
@export var bg_02_pools: Texture2D
@export var bg_03_ferns: Texture2D
@export var bg_04_rivers: Texture2D
@export var bg_05_cycads: Texture2D
@export var bg_06_forest: Texture2D

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

@onready var museum = $UI_Layer/MuseumScene
@onready var btn_museum = $UI_Layer/BtnMuseum

@onready var settings_panel = $UI_Layer/SettingsPanel
@onready var btn_settings = $UI_Layer/TopPanel/BtnSettings

func _ready():
	print("Main Game Started")
	click_zone.pressed.connect(_on_background_clicked)
	# Listen for Habitat Changes
	
	btn_research.pressed.connect(func(): research_menu.visible = !research_menu.visible)
	
	GameManager.connect("extinction_triggered", _show_extinction)
	GameManager.connect("dinosaur_spawned", _spawn_dino)
	GameManager.connect("fossils_changed", _update_fossils_ui)
	GameManager.connect("research_unlocked", _on_research_unlocked)
	
	_update_biome_visuals()
	
	# --- TOGGLE LOGIC ---
	# Open/Close the Shop
	btn_shop.pressed.connect(func(): 
		shop_panel.visible = !shop_panel.visible
		# Optional: Close Research if opening Shop (to avoid overlap)
		if shop_panel.visible:
			research_menu.visible = false
		)
		
	btn_museum.pressed.connect(func(): 
		museum.visible = true
		museum.refresh_gallery() # Ensure it updates if we just unlocked something!
	)
	btn_settings.pressed.connect(func(): settings_panel.visible = true)

func _on_research_unlocked(_id):
	_update_biome_visuals()

func _update_biome_visuals():
	# We check from HIGHEST tier to LOWEST tier.
	# The first one we find is the "best" background we have.
	
	var unlocked = GameManager.unlocked_research_ids
	
	# 1. CHECK TIER 6 (Forest)
	if "node_forest" in unlocked:
		background_sprite.texture = bg_06_forest
		return

	# 2. CHECK TIER 5 (Cycads)
	if "node_cycads" in unlocked:
		background_sprite.texture = bg_05_cycads
		return

	# 3. CHECK TIER 4 (Rivers - assuming ID is node_rivers)
	if "node_river" in unlocked:
		background_sprite.texture = bg_04_rivers
		return

	# 4. CHECK TIER 3 (Ferns)
	if "node_ferns" in unlocked:
		background_sprite.texture = bg_03_ferns
		return

	# 5. CHECK TIER 2 (Pools)
	if "node_pools" in unlocked:
		background_sprite.texture = bg_02_pools
		return

	# 6. DEFAULT (Base)
	background_sprite.texture = bg_01_base

func _on_background_clicked():
	GameManager.add_dna(10000) # Increased to 5 to make testing faster!

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
	var total_dps = 0
	for dino in dino_container.get_children():
		if not dino.is_dead and dino.species_data:
			total_dps += dino.species_data.passive_dna_yield
	
	dna_label.text = str(GameManager.current_dna)

func _update_fossils_ui(new_amount):
	# This updates the text whenever the number changes
	fossil_label.text = str(new_amount)

func _on_btn_save_pressed():
	var data = GameManager.get_save_dictionary()
	AuthManager.save_game_to_cloud(data)

func _on_btn_load_pressed():
	AuthManager.load_game_from_cloud()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Give GameManager time to send the save request
		if AuthManager.user_id != "":
			print("Saving before quit...")
			var data = GameManager.get_save_dictionary()
			AuthManager.save_game_to_cloud(data)
			# Wait a tiny bit for the request to fire (approximate)
			await get_tree().create_timer(0.5).timeout
		
		get_tree().quit() # Now actually close
