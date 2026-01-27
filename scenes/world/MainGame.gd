extends Node2D
## MainGame - The primary game scene handling world visuals and UI connections.

# --- LOGGING (Set to false for production) ---
const DEBUG_MODE: bool = false

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

# Safety Watchdog
var _ui_watchdog_timer: float = 0.0

func _ready() -> void:
	print("MainGame: _ready() called!")
	if DEBUG_MODE:
		print("MainGame: Scene started")
	AudioManager.play_music()
	AudioManager.play_music()
	# click_zone.pressed.connect(_on_background_clicked) # REMOVED: Replaced by _unhandled_input for multi-touch
	
	# Listen for Habitat Changes
	
	btn_research.pressed.connect(func():
		research_menu.visible = !research_menu.visible
		_toggle_ui_buttons(research_menu.visible)
	)
	
	# --- BUTTON CONNECTIONS ---
	btn_shop.pressed.connect(func():
		AudioManager.play_sfx("ui_click")
		shop_panel.visible = !shop_panel.visible
		_toggle_ui_buttons(shop_panel.visible)
		if shop_panel.visible:
			research_menu.visible = false
			museum.visible = false
	)
		
	btn_museum.pressed.connect(func():
		AudioManager.play_sfx("ui_click")
		museum.visible = !museum.visible
		_toggle_ui_buttons(museum.visible)
		if museum.visible:
			research_menu.visible = false
			shop_panel.visible = false
	)
	
	btn_tasks.pressed.connect(func(): quest_panel.show_panel())
	
	# Connect panel visibility changes to toggle buttons
	shop_panel.visibility_changed.connect(func():
		if not shop_panel.visible:
			_toggle_ui_buttons(false)
	)
	
	research_menu.visibility_changed.connect(func():
		if not research_menu.visible:
			_toggle_ui_buttons(false)
	)
	
	museum.visibility_changed.connect(func():
		if not museum.visible:
			_toggle_ui_buttons(false)
	)
	
	GameManager.connect("extinction_triggered", _show_extinction)
	GameManager.connect("dinosaur_spawned", _spawn_dino)
	GameManager.connect("fossils_changed", _update_fossils_ui)
	GameManager.connect("research_unlocked", _on_research_unlocked)
	# Trigger visual update when habitat changes
	GameManager.connect("habitat_updated", func(_v, _c): _update_biome_visuals())

	# Safe to start tutorial now that scene is ready
	# Add a small delay so it doesn't pop up instantly
	var tween = create_tween()
	
	# --- OPTIMIZATION: GPU WARMUP ---
	# Force heavy UI to render one frame (invisible) to upload textures to GPU
	# This prevents the "Freeze" when clicking the button for the first time.
	_warmup_ui()
	
	tween.tween_interval(1.0)
	tween.tween_callback(TutorialManager.check_start)
	
func _warmup_ui():
	# GPU Warmup is no longer needed with alpha-based visibility
	# Panels are already visible=true with alpha=0 by default
	# They will warm up naturally when first toggled
	print("[MainGame] UI Warmup Skipped (Alpha-based system active)")

func _unhandled_input(event):
	# CRITICAL: Don't collect DNA if any panel is open
	var any_panel_open = (
		shop_panel.visible or
		museum.visible or
		research_menu.visible or
		extinction_panel.visible or
		quest_panel.visible or
		settings_panel.visible
	)
	
	if any_panel_open:
		return # Don't process background clicks
	
	# MULTITOUCH SUPPORT: Detect individual touches
	if event is InputEventScreenTouch and event.pressed:
		_on_background_clicked(event.position)
		get_viewport().set_input_as_handled()
		
	# PC FALLBACK (Testing): Mouse Click
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_background_clicked(event.position)
		get_viewport().set_input_as_handled()

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
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# STYLE: Pixel Font & Bigger Size
	label.add_theme_font_size_override("font_size", 32)
	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	if font:
		label.add_theme_font_override("font", font)
	
	# Add to FeedbackContainer (first child of UI_Layer, draws BEHIND buttons)
	var feedback_container = $UI_Layer/FeedbackContainer
	feedback_container.add_child(label)
	
	# OPTIMIZATION: Safety cap for click effects (Anti-Freeze)
	if feedback_container.get_child_count() > 100:
		var oldest = feedback_container.get_child(0)
		oldest.queue_free()
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", pos.y - 80, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _on_background_clicked(tap_position: Vector2):
	# 1. Base Click Value
	var amount = 1
	
	# 2. Add Global Bonus from Active Dinos
	if GameManager.has_method("get_global_click_bonus"):
		amount += GameManager.get_global_click_bonus()
		
	GameManager.add_dna(amount)
	_show_click_feedback(tap_position, amount)
	
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

func _process(delta):
	# --- UI WATCHDOG ---
	# SAFETY: Handle Hot-Reload where variable might be uninitialized (Nil)
	if _ui_watchdog_timer == null:
		_ui_watchdog_timer = 0.0
		
	# Occasionally check if UI state is inconsistent (Panels closed but buttons hidden)
	# This fixes the issue where closing the Research Menu sometimes leaves buttons hidden via race condition.
	_ui_watchdog_timer += delta
	if _ui_watchdog_timer > 0.5:
		_ui_watchdog_timer = 0.0
		_check_ui_consistency()

func _check_ui_consistency():
	# If ALL fullscreen panels are closed...
	if not shop_panel.visible and not research_menu.visible and not museum.visible and not extinction_panel.visible:
		# ...and the main buttons are hidden...
		if not btn_shop.visible:
			# ...Force them to show!
			if DEBUG_MODE:
				print("[MainGame] Watchdog: UI Buttons were hidden but panels are closed. Restoring.")
			_toggle_ui_buttons(false) # False = Show Buttons

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

# Helper function to hide/show UI buttons when full-screen panels are active
func _toggle_ui_buttons(should_hide: bool):
	if should_hide:
		# Hide all UI buttons when a full-screen panel is open
		btn_shop.visible = false
		btn_research.visible = false
		btn_museum.visible = false
		btn_tasks.visible = false
	else:
		# Show all UI buttons when panels are closed
		btn_shop.visible = true
		btn_research.visible = true
		btn_museum.visible = true
		btn_tasks.visible = true
