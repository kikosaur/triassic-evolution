extends Panel

@onready var icon_rect = %IconRect
@onready var name_label = %NameLabel
@onready var desc_label = %DescLabel
@onready var btn_dna = %BtnDNA
@onready var btn_fossil = %BtnFossil

var current_research: ResearchDef

func _ready():
	hide() # Start hidden
	btn_dna.pressed.connect(_on_buy_dna)
	btn_fossil.pressed.connect(_on_buy_fossil)
	
	# Close when clicking outside? Or use a Close Button?
	# User design implies a modal card. We can add a close button or "click outside" logic if this is a full screen overlay.
	# For now, let's assume there's a close button or we add one.
	
func setup(research_def: ResearchDef):
	current_research = research_def
	
	name_label.text = research_def.display_name
	
	# IMPROVEMENT: Use the description from the linked resource if available
	# This ensures the details match the actual item (Dino, Trait, Habitat)
	var final_desc = research_def.description
	
	if research_def.unlock_species and "description" in research_def.unlock_species:
		final_desc = research_def.unlock_species.description
	elif "unlock_trait" in research_def and research_def.unlock_trait and "description" in research_def.unlock_trait:
		final_desc = research_def.unlock_trait.description
	elif "unlock_habitat" in research_def and research_def.unlock_habitat:
		# HabitatDefs use 'display_name', but verify just in case
		var hab = research_def.unlock_habitat
		if "description" in hab and hab.description != "":
			final_desc = hab.description
		elif "display_name" in hab:
			final_desc = "Unlocks: " + hab.display_name
		elif "name" in hab:
			final_desc = "Unlocks: " + hab.name
			
	desc_label.text = final_desc
	
	if research_def.icon:
		icon_rect.texture = research_def.icon
		
	_update_buttons()
	show()
	
func _update_buttons():
	if not current_research: return
	
	var cost_d = current_research.dna_cost
	var cost_f = current_research.fossil_cost
	
	btn_dna.text = "Buy Using DNA (%s)" % GameManager.format_number(cost_d)
	btn_fossil.text = "Buy Using Fossil (%s)" % str(cost_f)
	
	btn_dna.disabled = (GameManager.current_dna < cost_d)
	btn_fossil.disabled = (GameManager.fossils < cost_f)

func _on_buy_dna():
	if GameManager.try_unlock_research(current_research):
		hide()
		# Optional: Play sound

func _on_buy_fossil():
	if GameManager.try_unlock_research_with_fossils(current_research):
		hide()
