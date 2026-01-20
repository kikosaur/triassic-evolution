extends Resource
class_name HabitatProduct  # <--- THIS LINE IS CRITICAL!

enum ProductType { VEGETATION, CRITTERS }

@export var name: String = "Item Name"
@export var type: ProductType = ProductType.VEGETATION
@export var dna_cost: int = 50
@export var density_gain: float = 10.0
@export var icon: Texture2D

@export var required_research_id: String = ""
