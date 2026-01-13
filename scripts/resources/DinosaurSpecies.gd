extends Resource
class_name DinosaurSpecies

enum Diet { HERBIVORE, CARNIVORE }

@export_group("Stats")
@export var species_name: String = "Dino Name"
@export var diet: Diet = Diet.HERBIVORE
@export var base_dna_cost: int = 10
@export var dna_yield: int = 1  # <--- THIS WAS MISSING OR NOT SAVED
@export var icon: Texture2D
