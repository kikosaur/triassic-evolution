extends Panel

@onready var icon_rect = %IconRect
@onready var name_label = %NameLabel
@onready var desc_label = %DescLabel
@onready var btn_dna = %BtnDNA
@onready var btn_fossil = %BtnFossil

var current_species: DinosaurSpecies
var current_habitat: HabitatProduct

func _ready():
	hide() # Start hidden
	btn_dna.pressed.connect(_on_buy_dna)
	btn_fossil.pressed.connect(_on_buy_fossil)

func setup_dinosaur(species: DinosaurSpecies):
	current_species = species
	current_habitat = null
	
	name_label.text = species.species_name
	desc_label.text = species.description if "description" in species else "A prehistoric dinosaur."
	
	if species.icon:
		icon_rect.texture = species.icon
		
	_update_buttons()
	show()

func setup_habitat(habitat: HabitatProduct):
	current_habitat = habitat
	current_species = null
	
	name_label.text = habitat.name
	# Habitat might not have description yet, add fallback
	desc_label.text = "Enhances habitat density."
	
	if habitat.icon:
		icon_rect.texture = habitat.icon
		
	_update_buttons()
	show()
	
func _update_buttons():
	if current_species:
		var cost_dna = GameManager.get_dino_cost(current_species)
		var cost_fos = GameManager.get_dino_fossil_cost(current_species)
		
		btn_dna.text = "Buy Using DNA (%s)" % GameManager.format_number(cost_dna)
		btn_fossil.text = "Buy Using Fossil (%s)" % str(cost_fos)
		
		btn_dna.disabled = (GameManager.current_dna < cost_dna)
		btn_fossil.disabled = (GameManager.fossils < cost_fos)
		
	elif current_habitat:
		var cost_dna = GameManager.get_habitat_cost(current_habitat)
		var cost_fos = current_habitat.fossil_cost if "fossil_cost" in current_habitat else 1
		
		btn_dna.text = "Buy Using DNA (%s)" % GameManager.format_number(cost_dna)
		btn_fossil.text = "Buy Using Fossil (%s)" % str(cost_fos)
		
		btn_dna.disabled = (GameManager.current_dna < cost_dna)
		btn_fossil.disabled = (GameManager.fossils < cost_fos)

func _on_buy_dna():
	if current_species:
		var cost = GameManager.get_dino_cost(current_species)
		if GameManager.try_spend_dna(cost):
			GameManager.trigger_dino_spawn(current_species)
			hide()
	elif current_habitat:
		var cost = GameManager.get_habitat_cost(current_habitat)
		if GameManager.try_spend_dna(cost):
			_apply_habitat_effect()
			hide()

func _on_buy_fossil():
	if current_species:
		var cost = GameManager.get_dino_fossil_cost(current_species)
		if GameManager.try_spend_fossils(cost):
			GameManager.trigger_dino_spawn(current_species)
			hide()
	elif current_habitat:
		var cost = current_habitat.fossil_cost if "fossil_cost" in current_habitat else 1
		if GameManager.try_spend_fossils(cost):
			_apply_habitat_effect()
			hide()

func _apply_habitat_effect():
	if current_habitat.type == HabitatProduct.ProductType.VEGETATION:
		GameManager.vegetation_density += current_habitat.density_gain
	else:
		GameManager.critter_density += current_habitat.density_gain
	
	# Clamp to 100%
	if GameManager.vegetation_density > 100: GameManager.vegetation_density = 100
	if GameManager.critter_density > 100: GameManager.critter_density = 100
	
	GameManager.emit_signal("habitat_updated", GameManager.vegetation_density, GameManager.critter_density)
