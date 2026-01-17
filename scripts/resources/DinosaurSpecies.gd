extends Resource
class_name DinosaurSpecies

enum Diet { HERBIVORE, CARNIVORE }

@export_group("Stats")
@export var species_name: String = "Dino Name"
@export var visual_scale: float = 1.0
@export var animations: SpriteFrames
@export var diet: Diet = Diet.HERBIVORE
@export var base_dna_cost: int = 10
@export var passive_dna_yield: int = 1
@export var icon: Texture2D

# --- NEW SURVIVAL STATS ---
@export_group("Survival Stats")
@export var ideal_biome_phase: int = 1  # 1=Desert, 2=Oasis, 3=Jungle
@export_range(0.0, 1.0) var tolerance: float = 0.5 # 1.0 = Invincible, 0.0 = Very Fragile
@export var base_lifespan: float = 60.0 # How many seconds they live (under perfect conditions)

@export_group("Museum Entry")
@export var scientific_name: String = "Latin Name"
@export var time_period: String = "230 Million Years Ago"
@export_multiline var description: String = "A brief description of this dinosaur."
