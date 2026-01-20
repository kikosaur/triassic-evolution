extends Resource
class_name TaskData

@export_group("Display Info")
@export var id: String = "task_00"
@export var title: String = "Task Title"
@export_multiline var description: String = "Description of what to do."
@export var icon: Texture2D # Optional: Icon for the popup

@export_group("Objectives")
# Enum to switch logic easily in the inspector
@export var goal_type: String = "dino_count" # Options: "dna", "dino_count", "research"
@export var target_amount: int = 10
@export var target_id: String = "" # e.g., "01_Lagosuchus" or "Upright Stance"

@export_group("Rewards")
@export var reward_dna: int = 500
