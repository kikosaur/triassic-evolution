extends Panel

# Using '%' finds the node anywhere in the scene, 
# even if it is inside a VBoxContainer!
@onready var veg_bar = %VegBar
@onready var critter_bar = %CritterBar
@onready var veg_info_popup = %VegetationInfoPopup
@onready var critter_info_popup = %CritterInfoPopup

func _ready():
	# Connect Buttons
	# Listen for updates
	GameManager.connect("habitat_updated", _on_update)
	
	# Initial set
	_on_update(GameManager.vegetation_density, GameManager.critter_density)
	
	# Connect section containers for click-anywhere behavior
	var veg_section = %VegSection
	if veg_section:
		veg_section.gui_input.connect(_on_veg_section_input)
	
	var critter_section = %CritterSection
	if critter_section:
		critter_section.gui_input.connect(_on_critter_section_input)

func _on_update(veg, critter):
	veg_bar.value = veg
	critter_bar.value = critter
	
	# Update popup content with current density
	if veg_info_popup:
		var content_label = veg_info_popup.find_child("ContentLabel", true, false)
		if content_label:
			content_label.text = """[b]Food Source for Herbivores[/b]

[color=green]Used For:[/color]
• Feeding herbivore dinosaurs
• Unlocking biome transitions
• Extinction event bonuses

[color=cyan]How to Increase:[/color]
• Buy from Habitat Shop
• Fern Bundle (+10%%)
• Cycad Crate (+50%%)

[color=yellow]Current Density:[/color] %d%%""" % int(veg)
	
	if critter_info_popup:
		var content_label = critter_info_popup.find_child("ContentLabel", true, false)
		if content_label:
			content_label.text = """[b]Food Source for Carnivores[/b]

[color=green]Used For:[/color]
• Feeding carnivore dinosaurs
• Unlocking biome transitions
• Protecting herbivores

[color=cyan]How to Increase:[/color]
• Buy from Habitat Shop
• Jar of Beetles (+15%%)
• Dragonfly Swarm (+60%%)

[color=orange]WARNING:[/color]
If critters run out, carnivores will hunt your herbivores!

[color=yellow]Current Density:[/color] %d%%""" % int(critter)

# Helper function to center a popup on the viewport
func _center_popup_on_viewport(popup: Control):
	var viewport_size = get_viewport_rect().size
	var popup_size = popup.size
	
	# Calculate center position
	var center_x = (viewport_size.x - popup_size.x) / 2.0
	var center_y = (viewport_size.y - popup_size.y) / 2.0
	
	# Set position (global position for proper centering)
	popup.global_position = Vector2(center_x, center_y)

# Section-wide input handlers (click anywhere in section)
func _on_veg_section_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				veg_info_popup.show()
				_center_popup_on_viewport(veg_info_popup)
				veg_info_popup.move_to_front()
			else:
				veg_info_popup.hide()

func _on_critter_section_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				critter_info_popup.show()
				_center_popup_on_viewport(critter_info_popup)
				critter_info_popup.move_to_front()
			else:
				critter_info_popup.hide()
