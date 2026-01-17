extends Panel

# Using '%' finds the node anywhere in the scene, 
# even if it is inside a VBoxContainer!
@onready var veg_bar = %VegBar
@onready var critter_bar = %CritterBar

func _ready():
	# Connect Buttons
	
	# Listen for updates
	GameManager.connect("habitat_updated", _on_update)
	
	# Initial set
	_on_update(GameManager.vegetation_density, GameManager.critter_density)

func _on_update(veg, critter):
	veg_bar.value = veg
	critter_bar.value = critter
