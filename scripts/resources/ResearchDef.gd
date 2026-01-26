extends Resource
class_name ResearchDef

enum ResearchType {SPECIES, TRAIT, HABITAT}

@export_group("Display")
@export var id: String = "unique_id"
@export var display_name: String = "Name"
@export var icon: Texture2D
@export_multiline var description: String = "Research Description"
@export var type: ResearchType = ResearchType.SPECIES

@export_group("Costs & Requirements")
@export var dna_cost: int = 500
@export var fossil_cost: int = 5 # NEW: Premium Cost
@export var parent_research: ResearchDef

@export_group("Rewards")
@export var unlock_species: DinosaurSpecies
@export var unlock_trait: Resource # Should be DinoTrait, but Resource is safer if class_name not defined
@export var unlock_habitat: Resource # Should be HabitatProduct
