extends Panel

# DNA Info Popup - Small popup to explain DNA currency
@onready var title_lbl = $MarginContainer/VBoxContainer/TitleLabel
@onready var content_text = $MarginContainer/VBoxContainer/ContentLabel

func _ready():
	hide() # Start hidden

func show_dna_info():
	title_lbl.text = "DNA Points"
	
	# Get current DNA rate
	var dna_rate = GameManager.get_total_dna_per_second()
	
	content_text.text = """[b]Primary Currency for Evolution[/b]

[color=green]Used For:[/color]
• Buying new dinosaurs
• Unlocking research nodes
• Terraforming habitats

[color=cyan]How to Earn:[/color]
• Click dinosaurs or background
• Passive generation from living dinos
• Complete quests

[color=yellow]Current Rate:[/color] %d DNA/second""" % dna_rate
	
	show()
	move_to_front()
