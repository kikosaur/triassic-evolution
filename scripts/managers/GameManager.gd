extends Node
## GameManager - Core game state manager handling economy, research, and progression.
## Autoload singleton accessible globally.

# --- LOGGING (Set to false for production) ---
const DEBUG_MODE: bool = false

# --- SIGNALS ---
signal dna_changed(new_amount: int)
signal habitat_updated(veg_density: float, critter_density: float)
signal fossils_changed(new_amount: int)
signal dinosaur_spawned(species_resource: Resource)
signal extinction_triggered
signal research_unlocked(research_id: String)
signal offline_earnings_calculated(amount: int, time_seconds: int)
signal dino_spawned(dino_node: Node)
signal spawn_floating_text(pos: Vector2, text: String, color: Color)
signal toast_notification(text: String, color: Color)
signal dinosaur_died(dino_node: Node)

# --- ECONOMY VARIABLES ---
var current_dna: int = 0
var fossils: int = 0 # Single source of truth for fossils
var vegetation_density: float = 0.0
var critter_density: float = 0.0
var prestige_multiplier: float = 1.0

# --- LIMITS ---
var max_dino_count: int = 25 # Dynamic: Increases when habitat research is unlocked

# --- DATA TRACKING ---
var unlocked_research_ids: Array = []
var owned_dinosaurs: Dictionary = {}
var tutorial_completed: bool = false
var lifetime_purchases: Dictionary = {} # Tracks total buys for persistent pricing

# --- LIFECYCLE TRACKING (For Quests) ---
var total_dinos_spawned: int = 0 # Lifetime spawns
var total_dinos_died: int = 0 # Lifetime deaths
var dino_spawn_history: Array = [] # [{species: "Archosaur", timestamp: 123}]
var dino_death_history: Array = [] # [{species: "Archosaur", timestamp: 456, cause: "old_age"}]

# --- CACHED STATS (Optimization) ---
var _cached_herbivore_dps: int = 0
var _cached_carnivore_dps: int = 0
var _cached_click_bonus: int = 0
var _cached_dino_counts: Dictionary = {}
var _cached_herbivores: Array = [] # New: Fast access for hunting
var _cached_carnivores: Array = [] # New: Fast access (future proof)

# --- DINO LIBRARY ---
# Variable to hold the Dino Scene
var dino_scene = preload("res://scenes/units/DinoUnit.tscn")
var pending_dino_load_data: Array = [] # Buffer for dinos if scene isn't ready
var pending_offline_earnings: int = 0
var pending_offline_time: int = 0

# Dictionary to map Names to Files
var dino_library = {
	"Archosaur": "res://resources/dinos/00_Archosaur.tres",
	"Lagosuchus": "res://resources/dinos/01_Lagosuchus.tres",
	"Eoraptor": "res://resources/dinos/02_Eoraptor.tres",
	"Herrerasaurus": "res://resources/dinos/03_Herrerasaurus.tres",
	"Panphagia": "res://resources/dinos/04_Panphagia.tres",
	"Coelophysis": "res://resources/dinos/05_Coelophysis.tres",
	"Plateosaurus": "res://resources/dinos/06_Plateosaurus.tres",
	"Liliensternus": "res://resources/dinos/07_Liliensternus.tres",
	"Riojasaurus": "res://resources/dinos/08_Riojasaurus.tres"
}

var auto_save_timer: Timer

func _ready():
	# Unlock starter
	unlocked_research_ids.append("node_archosaur")
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 60.0 # Save every 60 seconds
	auto_save_timer.autostart = true
	add_child(auto_save_timer)
	auto_save_timer.timeout.connect(_on_auto_save)
	
	# LISTEN FOR QUEST UPDATES
	if QuestManager.has_signal("quests_updated"):
		QuestManager.quests_updated.connect(_check_win_condition)
		
	# LISTEN FOR OWN RESEARCH UPDATES
	research_unlocked.connect(_check_win_condition)
	
	# Passive regrowth removed by user request (Fix hunger mechanics)
	
	# Time System
	_setup_year_timer()

# Helper to trigger floating text (encapsulates signal)
func trigger_floating_text(pos: Vector2, text: String, color: Color = Color.WHITE):
	emit_signal("spawn_floating_text", pos, text, color)

var year_timer: Timer
var current_year: int = 0
signal year_advanced(total_years: int)

func _setup_year_timer():
	year_timer = Timer.new()
	year_timer.wait_time = 1.0 # 1 Real Second = 1 In-Game Year
	year_timer.autostart = true
	add_child(year_timer)
	year_timer.timeout.connect(func():
		current_year += 1
		emit_signal("year_advanced", current_year)
	)


func _on_auto_save() -> void:
	var data = get_save_dictionary()
	
	# Always save local backup
	AuthManager.save_game_local(data)
	
	# Only save cloud if logged in!
	if AuthManager.user_id != "":
		if DEBUG_MODE:
			print("GameManager: Cloud Auto-saving...")
		AuthManager.save_game_to_cloud(data)


func _notification(what):
	# Save when the player quits the window
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		var data = get_save_dictionary()
		AuthManager.save_game_local(data)
		
		if AuthManager.user_id != "":
			AuthManager.save_game_to_cloud(data)

# --- CORE ECONOMY FUNCTIONS ---
func add_dna(amount: int):
	# Apply Prestige Multiplier
	var final_amount = int(amount * prestige_multiplier)
	current_dna += final_amount
	emit_signal("dna_changed", current_dna)

func try_spend_dna(amount: int) -> bool:
	if current_dna >= amount:
		current_dna -= amount
		emit_signal("dna_changed", current_dna)
		return true
	return false

func add_fossils(amount: int) -> void:
	fossils += amount
	emit_signal("fossils_changed", fossils)
	if DEBUG_MODE:
		print("GameManager: Fossils collected, total: ", fossils)

func try_spend_fossils(amount: int) -> bool:
	if fossils >= amount:
		fossils -= amount
		emit_signal("fossils_changed", fossils)
		return true
	return false

# --- TIME WARP (Premium Feature) ---
const TIME_WARP_COST: int = 10 # Fossils needed
const TIME_WARP_SECONDS: int = 3600 # 1 hour = 3600 seconds

func use_time_warp() -> bool:
	if try_spend_fossils(TIME_WARP_COST):
		var dna_rate = get_total_dna_per_second()
		var earnings = dna_rate * TIME_WARP_SECONDS
		add_dna(earnings)
		if DEBUG_MODE:
			print("GameManager: Time Warp used, earned ", earnings, " DNA")
		return true
	else:
		if DEBUG_MODE:
			print("GameManager: Not enough fossils for Time Warp")
		return false


# --- HABITAT FUNCTIONS ---
func buy_vegetation():
	if try_spend_dna(100):
		vegetation_density = clamp(vegetation_density + 10.0, 0, 100)
		emit_signal("habitat_updated", vegetation_density, critter_density)

func buy_critters():
	if try_spend_dna(150):
		critter_density = clamp(critter_density + 10.0, 0, 100)
		emit_signal("habitat_updated", vegetation_density, critter_density)

# --- CONSUMPTION LOGIC ---
func consume_vegetation(amount: float) -> bool:
	# USER REQUEST: Allow consumption even if it surpasses available amount.
	# This means we just drain to 0 and always return true.
	vegetation_density = max(0.0, vegetation_density - amount)
	emit_signal("habitat_updated", vegetation_density, critter_density)
	return true

func consume_critters(amount: float) -> bool:
	# USER REQUEST: Allow consumption even if it surpasses available amount.
	critter_density = max(0.0, critter_density - amount)
	emit_signal("habitat_updated", vegetation_density, critter_density)
	return true

# --- RESEARCH FUNCTIONS ---
func is_research_unlocked(research_def: ResearchDef) -> bool:
	if research_def == null: return true
	return research_def.id in unlocked_research_ids

func try_unlock_research(research_def: ResearchDef) -> bool:
	if research_def.id in unlocked_research_ids: return false

	if research_def.parent_research:
		if research_def.parent_research.id not in unlocked_research_ids:
			return false

	if try_spend_dna(research_def.dna_cost):
		unlocked_research_ids.append(research_def.id)
		if DEBUG_MODE:
			print("GameManager: Unlocked ", research_def.display_name)

		emit_signal("research_unlocked", research_def.id)
		
		# --- HABITAT EXPANSION: Increase limit when unlocking habitat research ---
		if research_def.type == ResearchDef.ResearchType.HABITAT:
			max_dino_count += 10
			if DEBUG_MODE:
				print("GameManager: Habitat unlocked! New dino limit: ", max_dino_count)
		
		# --- BREAKTHROUGH: Spawn 1 free unit when unlocking a species ---
		if research_def.unlock_species != null:
			trigger_dino_spawn(research_def.unlock_species)
			if DEBUG_MODE:
				print("GameManager: Breakthrough! Free ", research_def.unlock_species.species_name)
		return true
	return false

func try_unlock_research_with_fossils(research_def: ResearchDef) -> bool:
	if research_def.id in unlocked_research_ids: return false

	# Fossil Unlock might SKIP parent requirements? 
	# User Request implied "Fast Track". But to be safe, let's enforce parents for now.
	if research_def.parent_research:
		if research_def.parent_research.id not in unlocked_research_ids:
			if DEBUG_MODE: print("GameManager: Cannot buy with fossils - Parent locked")
			return false

	if try_spend_fossils(research_def.fossil_cost):
		unlocked_research_ids.append(research_def.id)
		emit_signal("research_unlocked", research_def.id)
		
		# --- HABITAT EXPANSION: Increase limit when unlocking habitat research ---
		if research_def.type == ResearchDef.ResearchType.HABITAT:
			max_dino_count += 10
			if DEBUG_MODE:
				print("GameManager: Habitat unlocked! New dino limit: ", max_dino_count)
		
		if research_def.unlock_species != null:
			trigger_dino_spawn(research_def.unlock_species)
		return true
	return false

func is_all_research_unlocked() -> bool:
	# There are 17 total research nodes (based on files)
	# 8 Species + 1 Starter + 8 Upgrades/Traits
	# A robust way is to check the resource registry or just hardcode the target
	return unlocked_research_ids.size() >= 17

func can_spawn_dino() -> bool:
	var count = get_tree().get_nodes_in_group("dinos").size()
	# Check pending buffer too for strictness
	if count + pending_dino_load_data.size() >= max_dino_count:
		# Use TOAST instead of floating text (Always Visible)
		# Also show debug count to help user understand "24/25" confusion
		emit_signal("toast_notification", "HABITAT FULL! (%d/%d)" % [count, max_dino_count], Color.RED)
		return false
	return true
	
func trigger_dino_spawn(species_data: DinosaurSpecies):
	if not can_spawn_dino():
		return

	# Increment Lifetime Count (Economy consistency)
	record_dino_purchase(species_data)
		
	emit_signal("dinosaur_spawned", species_data)

func record_dino_purchase(species_data: DinosaurSpecies):
	var s_name = species_data.species_name
	if s_name in lifetime_purchases:
		lifetime_purchases[s_name] += 1
	else:
		lifetime_purchases[s_name] = 1

func trigger_extinction():
	# Only trigger if not already triggered (optional check, but good for safety)
	emit_signal("extinction_triggered")
	if DEBUG_MODE: print("GameManager: EXTINCTION EVENT STARTED!")

func is_win_condition_met() -> bool:
	return is_all_research_unlocked() and QuestManager.are_all_quests_completed()

func _check_win_condition(_ignored_arg = null):
	# Just emit a signal if we want UI to react immediately, 
	# but the UI will likely poll or update when opened.
	if is_win_condition_met():
		if DEBUG_MODE: print("GameManager: Win condition met! Waiting for player to trigger Extinction.")
		# We could emit a signal here if we want a notification, e.g. "Extinction Ready!"


	# --- BIOME HELPERS ---
func get_current_biome_phase() -> int:
	# PHASE 1: DESERT (Default)
	# Requirement: None (Always starts here)
	var phase = 1
	
	# PHASE 2: OASIS
	# Requirement: Density > 30% AND 'node_river' researched
	if int(vegetation_density) > 30:
		if "node_river" in unlocked_research_ids:
			phase = 2
		else:
			return 1 # Cap at Phase 1 if River not unlocked
			
	# PHASE 3: JUNGLE
	# Requirement: Density > 60% AND 'node_forest' researched (AND must have passed Phase 2)
	if int(vegetation_density) > 60:
		# We assume if they hit 60 they probably have river, but let's be strict
		if "node_forest" in unlocked_research_ids and phase == 2:
			phase = 3
		elif phase == 2:
			return 2 # Cap at Phase 2 if Forest not unlocked
			
	return phase
		
# --- PREDATION HELPERS ---
func get_nearest_herbivore(hunter_position: Vector2) -> Node2D:
	var shortest_dist = 99999.0
	var nearest_prey = null
	
	# OPTIMIZATION: Use cached list instead of getting group every frame
	# Note: The list effectively filters out dead dinos since cache is rebuilt on death/spawn
	for dino in _cached_herbivores:
		# Check validity (Double safety, though cache rebuild should handle it)
		if not is_instance_valid(dino) or dino.is_dead: continue
		
		# Skip if too far (simple optimization)? No, we want nearest.
		# Skip if it's the hunter itself? (Unlikely since hunters are carnivores, but safety first)
		if dino.global_position == hunter_position: continue
		
		var dist = hunter_position.distance_to(dino.global_position)
		if dist < shortest_dist:
			shortest_dist = dist
			nearest_prey = dino
				
	return nearest_prey

func has_living_herbivores() -> bool:
	return _cached_herbivores.size() > 0

func reset_game_state():
	if DEBUG_MODE:
		print("GameManager: Resetting game state...")
		
	# 1. Reset Economy
	current_dna = 0
	# fossils = 0  <-- USER REQUEST: Fossils (Prestige) must REMAIN
	vegetation_density = 0.0
	critter_density = 0.0
	lifetime_purchases.clear()
	max_dino_count = 25 # Reset Limit (Requested)
	
	# 2. Reset Research (Keep Starter Logic)
	unlocked_research_ids.clear()
	unlocked_research_ids.append("node_archosaur")
	
	# 3. Clear Dinosaurs (Active & Buffer)
	get_tree().call_group("dinos", "queue_free")
	owned_dinosaurs.clear()
	pending_dino_load_data.clear() # Fix: Clear pending buffer
	dino_spawn_history.clear()
	dino_death_history.clear()
	
	# 4. Reset Quests
	QuestManager.reset_quests()
	tutorial_completed = false
	
	# 5. Reset Year (User Request)
	current_year = 0
	emit_signal("year_advanced", current_year)
	
	# 6. Update UI
	emit_signal("dna_changed", current_dna)
	emit_signal("fossils_changed", fossils)
	emit_signal("habitat_updated", vegetation_density, critter_density)
	
	# 7. CRITICAL FIX: Save the empty state immediately!
	# Otherwise, reloading the game will load the OLD save file.
	var empty_state = get_save_dictionary()
	empty_state["dinos"] = [] # FORCE EMPTY to avoid race condition with queue_free
	
	AuthManager.save_game_to_cloud(empty_state)
	
	if DEBUG_MODE:
		print("GameManager: Reset state saved to cloud.")
		
	# 8. VERIFICATION (Runs next frame to allow queue_free to finish)
	get_tree().create_timer(0.1).timeout.connect(_debug_verify_reset)

func _debug_verify_reset():
	if not DEBUG_MODE: return
	
	print("\n--- RESET VERIFICATION ---")
	print("DNA: ", current_dna, " (Expected: 0)")
	print("Fossils: ", fossils, " (Expected: Preserved/Non-Zero)")
	
	var dino_count = get_tree().get_nodes_in_group("dinos").size()
	print("Active Dinos: ", dino_count, " (Expected: 0)")
	
	print("Research: ", unlocked_research_ids.size(), " (Expected: 1 - 'node_archosaur')")
	print("Purchases: ", lifetime_purchases.size(), " (Expected: 0)")
	print("History: ", dino_spawn_history.size(), " (Expected: 0)")
	print("--------------------------\n")


func get_save_dictionary() -> Dictionary:
	# 1. Basic Resources
	var save_dict = {
		"dna": current_dna,
		"fossils": fossils,
		"unlocked_research": unlocked_research_ids,
		"critter_density": critter_density,
		"vegetation_density": vegetation_density,
		"tutorial_completed": tutorial_completed,
		
		# --- ADD THIS LINE ---
		"timestamp": Time.get_unix_time_from_system(),
		"current_year": current_year,
		"quests": QuestManager.get_save_data(),
		"lifetime_purchases": lifetime_purchases,
		"prestige_multiplier": prestige_multiplier,
		"max_dino_count": max_dino_count,
		# ---------------------
		
		"dinos": []
	}
	
	# 2. Serialize Dinosaurs with Optimization
	var dino_nodes = get_tree().get_nodes_in_group("dinos")
	if DEBUG_MODE:
		print("GameManager: Found ", dino_nodes.size(), " dinos in group 'dinos' to save.")
		
	for dino in dino_nodes:
		if is_instance_valid(dino) and not dino.is_dead:
			# Verify data validity
			if not dino.species_data:
				if DEBUG_MODE: print("GameManager: WARNING - Dino skipped, species_data is null!")
				continue
				
			var d_data = {
				"species_id": dino.species_data.species_name,
				"age": snapped(dino.current_age, 0.1), # Optimize: 1 decimal
				"pos_x": int(dino.position.x), # Optimize: Integer
				"pos_y": int(dino.position.y) # Optimize: Integer
			}
			save_dict["dinos"].append(d_data)
		else:
			if DEBUG_MODE: print("GameManager: Skipped invalid or dead dino.")

	if DEBUG_MODE:
		print("GameManager: Saved ", save_dict["dinos"].size(), " valid dinos.")
			
	return save_dict

func load_save_dictionary(data: Dictionary):
	# 1. Restore Resources (Use YOUR variable names here!)
	if "dna" in data:
		current_dna = data["dna"] # <--- FIXED
	
	if "fossils" in data:
		fossils = data["fossils"]
		
	if "unlocked_research" in data:
		unlocked_research_ids = data["unlocked_research"]
		
	if "critter_density" in data:
		critter_density = data["critter_density"]
		
	if "vegetation_density" in data:
		vegetation_density = data["vegetation_density"]

	if "tutorial_completed" in data:
		tutorial_completed = data["tutorial_completed"]
	else:
		tutorial_completed = false

	if "quests" in data:
		QuestManager.load_save_data(data["quests"])

	if "lifetime_purchases" in data:
		lifetime_purchases = data["lifetime_purchases"]
		
	if "prestige_multiplier" in data:
		prestige_multiplier = data["prestige_multiplier"]
	else:
		prestige_multiplier = 1.0
	
	if "max_dino_count" in data:
		max_dino_count = data["max_dino_count"]
	else:
		max_dino_count = 25 # Default if not in save file
	
		#  MIGRATION: Recalculate limit based on unlocked habitats
	var habitat_ids = ["node_pools", "node_ferns", "node_river", "node_cycads", "node_forest"]
	var unlocked_habitat_count = 0
	for habitat_id in habitat_ids:
		if habitat_id in unlocked_research_ids:
			unlocked_habitat_count += 1
	var expected_limit = 25 + (unlocked_habitat_count * 10)
	if max_dino_count < expected_limit:
		max_dino_count = expected_limit


	if "current_year" in data:
		current_year = str(data["current_year"]).to_int()
		emit_signal("year_advanced", current_year)
	
	# Update UI
	emit_signal("dna_changed", current_dna)
	emit_signal("fossils_changed", fossils)
	
	# 2. Restore Dinosaurs (Clear old ones first)
	get_tree().call_group("dinos", "queue_free")
	
	if "dinos" in data:
		var saved_dinos = data["dinos"]
		if DEBUG_MODE:
			print("GameManager: Found ", saved_dinos.size(), " dinos in save file to load.")
		
		for d_data in saved_dinos:
			_spawn_dino_from_save(d_data)
	if "timestamp" in data:
		var saved_time = data["timestamp"]
		var current_time = Time.get_unix_time_from_system()
		var seconds_passed = current_time - saved_time
		
		if seconds_passed > 10: # Lowered to 10s for testing (was 60)
			print("GameManager: Offline for ", seconds_passed, "s. Calculating earnings...")
			_calculate_offline_earnings(seconds_passed)
			
	# 1. IMMEDIATE UPDATE (Fastest possible feedback)
	emit_signal("habitat_updated", vegetation_density, critter_density)
	emit_signal("dna_changed", current_dna)
	emit_signal("fossils_changed", fossils)
	_check_win_condition()

	# 2. SAFETY BACKUP (In case this ran during a scene transition)
	get_tree().create_timer(0.1).timeout.connect(func():
		emit_signal("habitat_updated", vegetation_density, critter_density)
		emit_signal("dna_changed", current_dna)
		emit_signal("fossils_changed", fossils)
		_check_win_condition()
	)
			
func _calculate_offline_earnings(seconds_passed: float):
	# 1. Cap time to 24 hours
	var max_seconds = 24 * 60 * 60
	if seconds_passed > max_seconds:
		seconds_passed = max_seconds
		
	# 2. Gather Stats
	var herb_dps = 0.0
	var herb_consumption = 0.0
	var carn_dps = 0.0
	var carn_consumption = 0.0
	
	var all_dinos = get_tree().get_nodes_in_group("dinos")
	for dino in all_dinos:
		if not dino.is_dead and dino.species_data:
			var rate = dino.species_data.consumption_rate if dino.species_data.consumption_rate != null else 0.05
			# MULTIPLIER: 0.05 (User Request: Drastically slow down offline consumption)
			rate *= 0.05
			
			if dino.species_data.diet == 0: # Herbivore
				herb_dps += dino.species_data.passive_dna_yield
				herb_consumption += rate
			else: # Carnivore
				carn_dps += dino.species_data.passive_dna_yield
				carn_consumption += rate
				
	# 3. ALSO CHECK BUFFERED DINOS (Critical for loading screen)
	for d_data in pending_dino_load_data:
		var id = d_data["species_id"]
		if id in dino_library:
			var path = dino_library[id]
			# Load resource just for stats (Cached by Godot usually)
			var species_res = load(path)
			if species_res:
				var rate = species_res.consumption_rate if species_res.consumption_rate != null else 0.05
				# MULTIPLIER: 0.05 (Consistent with above)
				rate *= 0.05
				
				if species_res.diet == 0: # Herbivore
					herb_dps += species_res.passive_dna_yield
					herb_consumption += rate
				else: # Carnivore
					carn_dps += species_res.passive_dna_yield
					carn_consumption += rate
	
	# 3. Calculate Valid Time (Starvation limit)
	var time_herb = seconds_passed
	if herb_consumption > 0:
		# How long until food runs out?
		var max_food_time = vegetation_density / herb_consumption
		time_herb = min(seconds_passed, max_food_time)
		
	var time_carn = seconds_passed
	if carn_consumption > 0:
		var max_food_time = critter_density / carn_consumption
		time_carn = min(seconds_passed, max_food_time)
		
	# 4. Calculate Earnings & Consume Resources
	var earnings = int((herb_dps * time_herb) + (carn_dps * time_carn))
	
	if herb_consumption > 0:
		vegetation_density -= (herb_consumption * time_herb)
	if carn_consumption > 0:
		critter_density -= (carn_consumption * time_carn)
		
	# Clamp resources to 0 just in case
	vegetation_density = max(0.0, vegetation_density)
	critter_density = max(0.0, critter_density)
	
	# 5. Apply Results
	if earnings > 0:
		add_dna(earnings)
		emit_signal("habitat_updated", vegetation_density, critter_density)
		
		# Show Popup (Store for UI when it's ready)
		pending_offline_earnings = earnings
		pending_offline_time = int(seconds_passed)
		emit_signal("offline_earnings_calculated", earnings, int(seconds_passed))
		
		if DEBUG_MODE:
			print("GameManager: Offline - Earned ", earnings, " DNA. Food consumed.")

func _spawn_dino_from_save(d_data, offline_seconds: float = 0.0):
	var id = d_data["species_id"]
	
	if id in dino_library:
		var path = dino_library[id]
		var stats = load(path)
		
		# 1. Attempt to find Container
		var main_game = get_tree().root.get_node_or_null("MainGame")
		# Fallback: Check current scene if named MainGame
		if not main_game and get_tree().current_scene.name == "MainGame":
			main_game = get_tree().current_scene
			
		var container = null
		if main_game:
			container = main_game.get_node_or_null("DinoContainer")
			
		# 2. If Container NOT found, BUFFER IT (Fixes Loading Screen Race Condition)
		if not container:
			if DEBUG_MODE:
				print("GameManager: Container not found. Buffering dino spawn: ", id)
			pending_dino_load_data.append(d_data)
			return

		if stats:
			var new_dino = dino_scene.instantiate()
			
			# 3. Assign Data FIRST (Prevents crash)
			new_dino.species_data = stats
			new_dino.position = Vector2(d_data["pos_x"], d_data["pos_y"])
			
			# --- OFFLINE AGING ---
			var saved_age = d_data["age"]
			var new_age = saved_age + offline_seconds
			var lifespan = stats.base_lifespan
			
			# Check if dino died while offline
			var died_offline = new_age >= lifespan
			
			if died_offline:
				# Set age to lifespan (for debug display)
				new_dino.current_age = lifespan
				if DEBUG_MODE:
					print("GameManager: ", stats.species_name, " died offline (age: ", saved_age, " + ", offline_seconds, "s = ", new_age, " >= ", lifespan, ")")
			else:
				new_dino.current_age = new_age
			
			# 4. Add to Scene
			container.add_child(new_dino)
			
			# --- SPAWN AS CORPSE IF DIED OFFLINE ---
			if died_offline:
				# Call spawn_as_corpse AFTER adding to tree (needs tree access for timer)
				if new_dino.has_method("spawn_as_corpse"):
					new_dino.spawn_as_corpse()
				# Don't notify spawn - this is a corpse, not a living dino
				return
			
			# 5. EXTRA SAFETY: Check if animations exist before playing
			if new_dino.has_node("AnimatedSprite"):
				var anim = new_dino.get_node("AnimatedSprite")
				
				# Ensure frames are loaded
				if stats.animations:
					anim.sprite_frames = stats.animations
					
					# Only play if the animation name actually exists
					if anim.sprite_frames.has_animation("idle"):
						anim.play("idle")

			# 6. QUEST SYSTEM SIGNAL (Crucial for tracking!)
			notify_dino_spawned(new_dino)

	else:
		if DEBUG_MODE:
			print("GameManager: Warning - Unknown dino species ID in save: ", id)
			# print("Available keys: ", dino_library.keys())

func process_pending_dinos():
	if pending_dino_load_data.is_empty(): return
	
	if DEBUG_MODE:
		print("GameManager: Processing ", pending_dino_load_data.size(), " buffered dinos...")
		
	var buffer = pending_dino_load_data.duplicate()
	pending_dino_load_data.clear()
	
	for d_data in buffer:
		_spawn_dino_from_save(d_data)

func notify_dino_spawned(dino_node: Node):
	# Track lifecycle stats for quests
	total_dinos_spawned += 1
	var species_name = ""
	if "species_data" in dino_node and dino_node.species_data:
		species_name = dino_node.species_data.species_name
	
	dino_spawn_history.append({
		"species": species_name,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Keep history limited to last 100 entries
	if dino_spawn_history.size() > 100:
		dino_spawn_history.pop_front()
	
	emit_signal("dino_spawned", dino_node)
	
	# Connect to death/removal to keep cache fresh
	if not dino_node.is_connected("tree_exited", _recalculate_cache):
		dino_node.tree_exited.connect(_recalculate_cache)
		
	# Update immediately for the new spawn
	_recalculate_cache()

func notify_dino_died(dino_node: Node):
	# Track lifecycle stats for quests
	total_dinos_died += 1
	var species_name = ""
	var death_cause = "unknown"
	
	if "species_data" in dino_node and dino_node.species_data:
		species_name = dino_node.species_data.species_name
	
	# Try to determine death cause (if DinoUnit has it)
	if "last_death_cause" in dino_node:
		death_cause = dino_node.last_death_cause
	
	dino_death_history.append({
		"species": species_name,
		"timestamp": Time.get_unix_time_from_system(),
		"cause": death_cause
	})
	
	# Keep history limited to last 100 entries
	if dino_death_history.size() > 100:
		dino_death_history.pop_front()
	
	emit_signal("dinosaur_died", dino_node)
	_recalculate_cache()

func _recalculate_cache():
	# SAFETY CHECK: If the tree is gone (quit/change), stop immediately.
	if not is_inside_tree(): return
	var tree = get_tree()
	if not tree: return

	var herb_dps = 0
	var carn_dps = 0
	var total_bonus = 0
	var counts = {}
	
	# Clear lists
	_cached_herbivores.clear()
	_cached_carnivores.clear()
	
	var dinos = get_tree().get_nodes_in_group("dinos")
	
	for dino in dinos:
		# Check validity
		if not is_instance_valid(dino) or dino.is_queued_for_deletion():
			continue
			
		if "is_dead" in dino and dino.is_dead:
			continue
			
		if not dino.species_data:
			continue
			
		# 1. DPS (Split by diet)
		if dino.species_data.diet == 0: # Herbivore
			herb_dps += dino.species_data.passive_dna_yield
			_cached_herbivores.append(dino)
		else: # Carnivore
			carn_dps += dino.species_data.passive_dna_yield
			_cached_carnivores.append(dino)
		
		# 2. Click Bonus
		if "global_click_bonus" in dino.species_data:
			total_bonus += dino.species_data.global_click_bonus
		else:
			total_bonus += 1
			
	# 3. Counts
		var s_name = dino.species_data.species_name
		if s_name in counts:
			counts[s_name] += 1
		else:
			counts[s_name] = 1
			
		# 4. Cache Lists (Handled in loop now)
			
	_cached_herbivore_dps = herb_dps
	_cached_carnivore_dps = carn_dps
	_cached_click_bonus = total_bonus
	_cached_dino_counts = counts
	
	if DEBUG_MODE:
		print("GameManager: Cache updated. H_DPS: ", herb_dps, " C_DPS: ", carn_dps)

# --- INCOME HELPER ---
func get_total_dna_per_second() -> int:
	var total = 0
	if vegetation_density > 0:
		total += _cached_herbivore_dps
		
	# LOGIC UPDATE: Carnivores produce DNA if Critters > 0 OR if they can hunt Herbivores
	if critter_density > 0 or _cached_herbivores.size() > 0:
		total += _cached_carnivore_dps
	return total

func get_global_click_bonus() -> int:
	# FIX: Default should be 0, not 1. 
	# Base click (1) is added in MainGame.gd, this is ONLY the bonus.
	if _cached_click_bonus == 0:
		return 0
	return _cached_click_bonus

# --- DYNAMIC PRICING ---
func get_dino_count(species_name: String) -> int:
	return _cached_dino_counts.get(species_name, 0)

func get_dino_cost(species_data: DinosaurSpecies) -> int:
	if not species_data: return 0
	
	var base = species_data.base_dna_cost
	# var count = get_dino_count(species_data.species_name) <--- OLD
	var count = lifetime_purchases.get(species_data.species_name, 0)
	
	# Formula: Base * (1.15 ^ Count)
	var multiplier = pow(1.15, count)
	return int(base * multiplier)

func get_dino_fossil_cost(species_data: DinosaurSpecies) -> int:
	if not species_data: return 0
	# Premium Cost is FIXED (No Inflation) to encourage using it
	var base = species_data.base_fossil_cost
	if "base_fossil_cost" in species_data:
		base = species_data.base_fossil_cost
	else:
		base = 5 # Default fallback
		
	return base

func get_habitat_cost(product_res: Resource) -> int:
	if not product_res: return 0
	
	# Assuming Product Script has 'dna_cost', 'type' (0=Veg, 1=Critter)
	var base = product_res.dna_cost
	
	# Formula: Base * (1.08 ^ PurchaseCount)
	# Was based on density, now based on consistent purchase history
	var count = lifetime_purchases.get(product_res.name, 0)
	var multiplier = pow(1.08, count)
	
	return int(base * multiplier)

func record_habitat_purchase(product_res: Resource):
	if not product_res: return
	
	var h_name = product_res.name
	if h_name in lifetime_purchases:
		lifetime_purchases[h_name] += 1
	else:
		lifetime_purchases[h_name] = 1

# --- UTILITIES ---

func format_number(value: int) -> String:
	if value < 1000:
		return str(value)
	elif value < 1000000:
		return str(snapped(value / 1000.0, 0.01)) + "k"
	elif value < 1000000000:
		return str(snapped(value / 1000000.0, 0.01)) + "m"
	elif value < 1000000000000:
		return str(snapped(value / 1000000000.0, 0.01)) + "b"
	elif value < 1000000000000000:
		return str(snapped(value / 1000000000000.0, 0.01)) + "t"
	else:
		return str(snapped(value / 1000000000000000.0, 0.01)) + "q"
