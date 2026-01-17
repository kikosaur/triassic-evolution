extends Panel

func _ready():
	$ResetBtn.pressed.connect(_on_reset)

func _on_reset():
	# 1. Calculate Prestige (10% bonus per run, or based on fossils)
	GameManager.prestige_multiplier += 0.1
	
	# 2. Reset Game Data
	GameManager.current_dna = 0
	GameManager.current_fossils = 0
	GameManager.vegetation_density = 0
	GameManager.critter_density = 0
	GameManager.unlocked_research_ids = ["node_archosaur"] # Reset tree
	GameManager.owned_dinosaurs.clear()
	
	# 3. Reload Scene
	get_tree().reload_current_scene()
