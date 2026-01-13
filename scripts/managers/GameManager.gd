extends Node

# --- SIGNALS ---
signal dna_changed(new_amount)
signal habitat_updated(veg_density, critter_density)
signal fossils_changed(new_amount)
signal dinosaur_spawned(species_resource)
signal extinction_triggered # Needed for Sprint 7

# --- ECONOMY VARIABLES ---
var current_dna: int = 0
var current_fossils: int = 0
var vegetation_density: float = 0.0
var critter_density: float = 0.0
var prestige_multiplier: float = 1.0 

# --- DATA TRACKING ---
var unlocked_research_ids: Array = []
var owned_dinosaurs: Dictionary = {} # THIS WAS MISSING!

func _ready():
	# Unlock starter
	unlocked_research_ids.append("node_archosaur")

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

func add_fossils(amount: int):
	current_fossils += amount
	emit_signal("fossils_changed", current_fossils)

func try_spend_fossils(amount: int) -> bool:
	if current_fossils >= amount:
		current_fossils -= amount
		emit_signal("fossils_changed", current_fossils)
		return true
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

func try_unlock_research(research_def: ResearchDef):
	if research_def.id in unlocked_research_ids: return

	if research_def.parent_research:
		if research_def.parent_research.id not in unlocked_research_ids:
			return 

	if try_spend_dna(research_def.dna_cost):
		unlocked_research_ids.append(research_def.id)
		print("Unlocked: ", research_def.display_name)

func trigger_dino_spawn(species_data: DinosaurSpecies):
	emit_signal("dinosaur_spawned", species_data)

func trigger_extinction():
	emit_signal("extinction_triggered")
