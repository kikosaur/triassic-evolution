extends Node2D
## MainGame - The primary game scene handling world visuals and UI connections.

# --- LOGGING (Set to false for production) ---
const DEBUG_MODE: bool = false

@onready var click_zone = $ClickZone
@onready var dino_container = $DinoContainer
# Labels moved to TopPanel internal logic
# @onready var dna_label = ... 
# @onready var fossil_label = ...
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
# btn_settings moved to TopPanel internal logic

@onready var btn_tasks = $UI_Layer/BtnTasks
@onready var quest_panel = $UI_Layer/QuestPanel

func _ready() -> void:
	if DEBUG_MODE:
		print("MainGame: Scene started")
	AudioManager.play_music()
	click_zone.pressed.connect(_on_background_clicked)
	# Listen for Habitat Changes
	
	btn_research.pressed.connect(func(): research_menu.visible = !research_menu.visible)
	
	GameManager.connect("extinction_triggered", _show_extinction)
	GameManager.connect("dinosaur_spawned", _spawn_dino)
	GameManager.connect("fossils_changed", _update_fossils_ui)
	GameManager.connect("research_unlocked", _on_research_unlocked)
	# Trigger visual update when habitat changes
	GameManager.connect("habitat_updated", func(_v, _c): _update_biome_visuals())
	

	_update_biome_visuals()
	
	# Safe to start tutorial now that scene is ready
	# Add a small delay so it doesn't pop up instantly
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(TutorialManager.check_start)
	
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
	
	# btn_settings.pressed.connect... (Handled in TopPanel now)
	
	btn_tasks.pressed.connect(func(): quest_panel.show_panel())

func _on_research_unlocked(_id):
	_update_biome_visuals()

func _update_biome_visuals():
	var veg = GameManager.vegetation_density
	var crit = GameManager.critter_density
	var unlocked = GameManager.unlocked_research_ids
	var target_texture = bg_01_base
	
	# Determine Biome based on Density Thresholds AND Research
	if veg >= 80.0 and crit >= 80.0 and "node_forest" in unlocked:
		target_texture = bg_06_forest
	elif veg >= 50.0 and crit >= 40.0 and "node_cycads" in unlocked:
		target_texture = bg_05_cycads
	elif veg >= 30.0 and crit >= 30.0 and "node_river" in unlocked:
		target_texture = bg_04_rivers
	elif veg >= 20.0 and "node_ferns" in unlocked:
		target_texture = bg_03_ferns
	elif veg >= 10.0 and "node_pools" in unlocked:
		target_texture = bg_02_pools
	
	# --- 2. APPLY TEXTURE & RESIZE ---
	# Only update if it's actually different (saves performance)
	if background_sprite.texture != target_texture:
		background_sprite.texture = target_texture
		
		# CRITICAL: This makes it fit the mobile screen immediately!
		# This calls the function in the script we just attached to the sprite.
		if background_sprite.has_method("apply_cover_scale"):
			background_sprite.apply_cover_scale()

func _show_click_feedback(pos: Vector2, amount: int):
	var label = Label.new()
	label.text = "+" + str(amount)
	label.modulate = Color(0.7, 1.0, 0.7) # Light Green
	label.position = pos
	
	# STYLE: Pixel Font & Bigger Size
	label.add_theme_font_size_override("font_size", 32)
	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	if font:
		label.add_theme_font_override("font", font)
	
	$UI_Layer.add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", pos.y - 80, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _on_background_clicked():
	# 1. Base Click Value
	var amount = 1
	
	# 2. Add Global Bonus from Active Dinos
	if GameManager.has_method("get_global_click_bonus"):
		amount += GameManager.get_global_click_bonus()
		
	GameManager.add_dna(amount)
	_show_click_feedback(get_viewport().get_mouse_position(), amount)
	
	# --- RARE FOSSIL: 0.1% chance (1/1000) to find a fossil when clicking dirt ---
	if randf() < 0.001: # 0.1% chance
		GameManager.add_fossils(1)
		AudioManager.play_sfx("success")
		if DEBUG_MODE:
			print("MainGame: Rare fossil found!")

func _on_buy_pressed():
	if GameManager.try_spend_dna(archosaur_res.base_dna_cost):
		spawn_dino(archosaur_res)

func _spawn_dino(species_res: DinosaurSpecies):
	spawn_dino(species_res)

func spawn_dino(species):
	var new_dino = dino_scene.instantiate()
	new_dino.species_data = species
	new_dino.position = Vector2(randf_range(500, 700), randf_range(300, 500)) # Randomize slightly
	dino_container.add_child(new_dino)
	
	# Notify QuestManager via GameManager
	GameManager.notify_dino_spawned(new_dino)

func _show_extinction():
	extinction_panel.visible = true
	# Optional: Play a sound or shake screen here

func _process(_delta):
	pass

func _update_fossils_ui(_new_amount):
	pass

func _on_btn_save_pressed():
	var data = GameManager.get_save_dictionary()
	AuthManager.save_game_to_cloud(data)

func _on_btn_load_pressed():
	AuthManager.load_game_from_cloud()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Give GameManager time to send the save request
		if AuthManager.user_id != "":
			if DEBUG_MODE:
				print("MainGame: Saving before quit...")
			var data = GameManager.get_save_dictionary()
			AuthManager.save_game_to_cloud(data)
			# Wait a tiny bit for the request to fire
			await get_tree().create_timer(0.5).timeout
		
		get_tree().quit()

# Inside MainGame.gd (around line 133)

func _on_timer_timeout(): # Or wherever you calculated it
	var total_dps = GameManager.get_total_dna_per_second()
	
	# FIX: Use the variable to update the UI!
	# FIX: Use the variable to update the UI!
	$UI_Layer/TopPanel.update_dps_label(total_dps)
