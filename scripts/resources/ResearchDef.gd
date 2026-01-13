extends Resource
class_name ResearchDef

enum ResearchType { SPECIES, TRAIT, HABITAT }

@export_group("Display")
@export var id: String = "unique_id"
@export var display_name: String = "Name"
@export var icon: Texture2D
@export var type: ResearchType = ResearchType.SPECIES

@export_group("Costs & Requirements")
@export var dna_cost: int = 500  # CHANGED FROM FOSSILS TO DNA
@export var parent_research: ResearchDef

@export_group("Rewards")
@export var unlock_species: DinosaurSpecies
