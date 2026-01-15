extends Button

var my_data: Resource
signal slot_clicked(data)

# Get the nodes we just added
@onready var icon_rect = $VBoxContainer/TextureRect
@onready var name_label = $VBoxContainer/Label

func setup(data: Resource, is_unlocked: bool):
	my_data = data
	
	# 1. ICON SETUP
	if "icon" in data:
		icon_rect.texture = data.icon
	
	# 2. LOCKED VS UNLOCKED
	if is_unlocked:
		disabled = false
		
		# Show full color
		icon_rect.modulate = Color(1, 1, 1, 1) 
		
		# Show Real Name
		if "species_name" in data:
			name_label.text = data.species_name
		else:
			name_label.text = "Unknown"
			
	else:
		disabled = true
		
		# Silhouette (Black)
		icon_rect.modulate = Color(0, 0, 0, 1) 
		
		# Mystery Text
		name_label.text = "???"

func _pressed():
	emit_signal("slot_clicked", my_data)
