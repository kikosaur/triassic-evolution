extends Panel

@onready var icon_rect = %IconRect
@onready var name_label = %NameLabel
@onready var desc_label = %DescLabel
@onready var btn_dna = %BtnDNA
@onready var btn_fossil = %BtnFossil
@onready var lbl_diet = %DietLabel
@onready var lbl_life = %LifespanLabel
@onready var lbl_bio = %BiosphereLabel
@onready var lbl_income = %IncomeLabel

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
	
	# 1. DIET
	var diet_str = "Unknown"
	if species.diet == 0: diet_str = "Herbivore 🌿"
	elif species.diet == 1: diet_str = "Carnivore 🥩"
	lbl_diet.text = "Diet: " + diet_str
	
	# 2. LIFESPAN
	lbl_life.text = "Lifespan: %s Seconds (Years in Game)" % str(species.base_lifespan)
	
	# 3. BIOSPHERE INFO (Replaces Traits)
	# "Biome: Desert | Eat: 1.0/s"
	var biome_name = "Desert"
	if species.ideal_biome_phase == 2: biome_name = "Oasis"
	elif species.ideal_biome_phase == 3: biome_name = "Forest"
	
	var rate = species.consumption_rate
	lbl_bio.text = "Biome: %s | Eat: %s/s" % [biome_name, str(rate)]
		
	# 4. INCOME STATS (User Request)
	# Format: "Stats: 10/s | Click: +10 (+2 Global)"
	var passive = str(species.passive_dna_yield)
	var click = str(species.click_yield)
	var global = str(species.global_click_bonus)
	
	lbl_income.text = "Stats: %s DNA/s | Click: +%s (+%s Global)" % [passive, click, global]
	
	# Show all stats
	lbl_diet.visible = true
	lbl_life.visible = true
	lbl_bio.visible = true
	lbl_income.visible = true
	
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
	
	# REUSE LABELS FOR HABITAT INFO
	
	# 1. TARGET (Diet Label)
	if habitat.type == 0: # VEGETATION
		lbl_diet.text = "Target: Herbivores 🌿"
	else:
		lbl_diet.text = "Target: Carnivores 🥩"
		
	# 2. DENSITY (Lifespan Label)
	lbl_life.text = "Gain: +%s Density" % str(habitat.density_gain)
	
	# 3. HIDE TRAITS & INCOME
	lbl_bio.visible = false
	lbl_income.visible = false
	
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
		# Check limit BEFORE spending
		if not GameManager.can_spawn_dino(): return
		
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
		# Check limit BEFORE spending
		if not GameManager.can_spawn_dino(): return
		
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
	
	# NEW: Record purchase for price scaling consistency
	if GameManager.has_method("record_habitat_purchase"):
		GameManager.record_habitat_purchase(current_habitat)
	
	GameManager.emit_signal("habitat_updated", GameManager.vegetation_density, GameManager.critter_density)
