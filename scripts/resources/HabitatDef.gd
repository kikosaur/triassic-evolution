extends Resource
class_name HabitatDef

@export var display_name: String = "Habitat Name"
@export var id: String = "unique_habitat_id"
@export_multiline var description: String = "Description..."
@export var icon: Texture2D
@export var required_research_id: String = "" # Link to ResearchDef.id
