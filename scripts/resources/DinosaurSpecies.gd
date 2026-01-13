extends Resource
class_name DinosaurSpecies

# Enum for dropdown menu in Inspector
enum Diet { HERBIVORE, CARNIVORE }

@export_group("Stats")
@export var species_name: String = "Dino Name"
@export var diet: Diet = Diet.HERBIVORE  # NEW: Default to Herbivore
@export var base_dna_cost: int = 10
@export var icon: Texture2D
