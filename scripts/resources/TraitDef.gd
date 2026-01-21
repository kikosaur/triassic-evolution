extends Resource
class_name TraitDef

@export var display_name: String = "Trait Name"
@export var id: String = "unique_trait_id"
@export_multiline var description: String = "Description..."
@export var icon: Texture2D
@export var required_research_id: String = "" # Link to ResearchDef.id
