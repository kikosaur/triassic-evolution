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

# --- ECONOMY VARIABLES ---
var current_dna: int = 0
var fossils: int = 0 # Single source of truth for fossils
var vegetation_density: float = 0.0
var critter_density: float = 0.0
var prestige_multiplier: float = 1.0

# --- DATA TRACKING ---
var unlocked_research_ids: Array = []
var owned_dinosaurs: Dictionary = {} # THIS WAS MISSING!

# --- DINO LIBRARY ---
# Variable to hold the Dino Scene
var dino_scene = preload("res://scenes/units/DinoUnit.tscn")

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
	
	# --- PASSIVE REGROWTH TIMER ---
	var regrowth_timer = Timer.new()
	regrowth_timer.wait_time = 10.0 # Grow every 10 seconds
	regrowth_timer.autostart = true
	add_child(regrowth_timer)
	regrowth_timer.timeout.connect(_on_passive_regrowth)

func _on_passive_regrowth() -> void:
	# Grow Vegetation (+1%)
	if vegetation_density < 100.0:
		vegetation_density = clamp(vegetation_density + 1.0, 0, 100)
	
	# Grow Critters (Synergy: Needs Vegetation > 30%)
	if vegetation_density > 30.0 and critter_density < 100.0:
		critter_density = clamp(critter_density + 0.5, 0, 100)
		
	emit_signal("habitat_updated", vegetation_density, critter_density)
	if DEBUG_MODE:
		print("GameManager: Passive Regrowth tick.")

func _on_auto_save() -> void:
	# Only save if logged in!
	if AuthManager.user_id != "":
		if DEBUG_MODE:
			print("GameManager: Auto-saving...")
		var data = get_save_dictionary()
		AuthManager.save_game_to_cloud(data)


func _notification(what):
	# Save when the player quits the window
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if AuthManager.user_id != "":
			var data = get_save_dictionary()
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
	if try_spend_dna(50):
		vegetation_density = clamp(vegetation_density + 5.0, 0, 100)
		emit_signal("habitat_updated", vegetation_density, critter_density)

func buy_critters():
	if try_spend_dna(75):
		critter_density = clamp(critter_density + 5.0, 0, 100)
		emit_signal("habitat_updated", vegetation_density, critter_density)

# --- CONSUMPTION LOGIC ---
func consume_vegetation(amount: float) -> bool:
	if vegetation_density >= amount:
		vegetation_density -= amount
		emit_signal("habitat_updated", vegetation_density, critter_density)
		return true
	return false

func consume_critters(amount: float) -> bool:
	if critter_density >= amount:
		critter_density -= amount
		emit_signal("habitat_updated", vegetation_density, critter_density)
		return true
	return false

# --- RESEARCH FUNCTIONS ---
func is_research_unlocked(research_def: ResearchDef) -> bool:
	if research_def == null: return true
	return research_def.id in unlocked_research_ids

func try_unlock_research(research_def: ResearchDef) -> void:
	if research_def.id in unlocked_research_ids: return

	if research_def.parent_research:
		if research_def.parent_research.id not in unlocked_research_ids:
			return

	if try_spend_dna(research_def.dna_cost):
		unlocked_research_ids.append(research_def.id)
		if DEBUG_MODE:
			print("GameManager: Unlocked ", research_def.display_name)

		emit_signal("research_unlocked", research_def.id)
		
		# --- BREAKTHROUGH: Spawn 1 free unit when unlocking a species ---
		if research_def.unlock_species != null:
			trigger_dino_spawn(research_def.unlock_species)
			if DEBUG_MODE:
				print("GameManager: Breakthrough! Free ", research_def.unlock_species.species_name)

func trigger_dino_spawn(species_data: DinosaurSpecies):
	emit_signal("dinosaur_spawned", species_data)

func trigger_extinction():
	emit_signal("extinction_triggered")
	
	# --- BIOME HELPERS ---
func get_current_biome_phase() -> int:
	# Phase 1: Desert (0-30%)
	if vegetation_density <= 30.0:
		return 1
	# Phase 2: Oasis (31-60%)
	elif vegetation_density <= 60.0:
		return 2
	# Phase 3: Jungle (61%+)
	else:
		return 3
		
# --- PREDATION HELPERS ---
func get_nearest_herbivore(hunter_position: Vector2) -> Node2D:
	var shortest_dist = 99999.0
	var nearest_prey = null
	
	# We need to access the container where dinos live.
	# Ideally, MainGame should register itself, or we search the group "dinosaurs".
	# Let's assume all dinos are in a Group named "dinos".
	var all_dinos = get_tree().get_nodes_in_group("dinos")
	
	for dino in all_dinos:
		# 1. Skip if dead or is the hunter itself
		if dino.is_dead or dino.global_position == hunter_position: continue
		
		# 2. Check if it's a Herbivore (Diet 0)
		if dino.species_data.diet == 0: # 0 = Herbivore
			var dist = hunter_position.distance_to(dino.global_position)
			if dist < shortest_dist:
				shortest_dist = dist
				nearest_prey = dino
				
	return nearest_prey

# --- SAVE / LOAD SYSTEM ---

func get_save_dictionary() -> Dictionary:
	# 1. Basic Resources
	var save_dict = {
		"dna": current_dna,
		"fossils": fossils,
		"unlocked_research": unlocked_research_ids,
		"critter_density": critter_density,
		"vegetation_density": vegetation_density,
		
		# --- ADD THIS LINE ---
		"timestamp": Time.get_unix_time_from_system(),
		"quests": QuestManager.get_save_data(),
		# ---------------------
		
		"dinos": []
	}
	
	# 2. Serialize Dinosaurs
	var dino_nodes = get_tree().get_nodes_in_group("dinos")
	for dino in dino_nodes:
		if not dino.is_dead:
			var d_data = {
				"species_id": dino.species_data.species_name, # or a unique ID if you have one
				"age": dino.current_age,
				"pos_x": dino.position.x,
				"pos_y": dino.position.y
			}
			save_dict["dinos"].append(d_data)
			
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

	if "quests" in data:
		QuestManager.load_save_data(data["quests"])
	
	# Update UI
	emit_signal("dna_changed", current_dna)
	emit_signal("fossils_changed", fossils)
	
	# 2. Restore Dinosaurs (Clear old ones first)
	get_tree().call_group("dinos", "queue_free")
	
	if "dinos" in data:
		for d_data in data["dinos"]:
			_spawn_dino_from_save(d_data)
	if "timestamp" in data:
		var saved_time = data["timestamp"]
		var current_time = Time.get_unix_time_from_system()
		var seconds_passed = current_time - saved_time
		
		if seconds_passed > 60: # Only count if gone for more than 1 minute
			_calculate_offline_earnings(seconds_passed)
			
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
			if dino.species_data.diet == 0: # Herbivore
				herb_dps += dino.species_data.passive_dna_yield
				herb_consumption += 0.05 # Consumes 0.05 per sec
			else: # Carnivore
				carn_dps += dino.species_data.passive_dna_yield
				carn_consumption += 0.05 # Consumes 0.05 per sec
	
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
		
		# Show Popup
		emit_signal("offline_earnings_calculated", earnings, int(seconds_passed))
		
		if DEBUG_MODE:
			print("GameManager: Offline - Earned ", earnings, " DNA. Food consumed.")

func _spawn_dino_from_save(d_data):
	var id = d_data["species_id"]
	
	if id in dino_library:
		var path = dino_library[id]
		var stats = load(path)
		
		if stats:
			var new_dino = dino_scene.instantiate()
			
			# 1. Assign Data FIRST (Prevents crash)
			new_dino.species_data = stats
			new_dino.position = Vector2(d_data["pos_x"], d_data["pos_y"])
			new_dino.current_age = d_data["age"]
			
			# 2. Add to Scene LAST (Triggers _ready)
			var main_game = get_tree().root.get_node_or_null("MainGame")
			if main_game:
				var container = main_game.get_node_or_null("DinoContainer")
				if container:
					container.add_child(new_dino)
					
					# 3. EXTRA SAFETY: Check if animations exist before playing
					if new_dino.has_node("AnimatedSprite"):
						var anim = new_dino.get_node("AnimatedSprite")
						
						# Ensure frames are loaded
						if stats.animations:
							anim.sprite_frames = stats.animations
							
							# Only play if the animation name actually exists
							if anim.sprite_frames.has_animation("idle"):
								anim.play("idle")

					# 4. QUEST SYSTEM SIGNAL (Crucial for tracking!)
					notify_dino_spawned(new_dino)

	else:
		if DEBUG_MODE:
			print("GameManager: Warning - Unknown dino species: ", id)

func notify_dino_spawned(dino_node: Node):
	emit_signal("dino_spawned", dino_node)

# --- INCOME HELPER ---
func get_total_dna_per_second() -> int:
	var total = 0
	var dinos = get_tree().get_nodes_in_group("dinos")
	
	for dino in dinos:
		if not dino.is_dead and dino.species_data:
			# Check if they are starving? 
			# For simplicity, we assume they would have found food.
			# Or you can check: if dino.hunger < 10:
			total += dino.species_data.passive_dna_yield
			
	return total

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
