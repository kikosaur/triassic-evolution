extends CharacterBody2D

var species_data: DinosaurSpecies
var target_pos: Vector2
var is_dead: bool = false
var hunger_timer: float = 0.0

func _ready():
	if species_data:
		$Sprite2D.texture = species_data.icon
		
	# Random destination start
	_pick_random_destination()

	# Life Timer (Death)
	var life = Timer.new()
	life.wait_time = randf_range(30.0, 60.0) # Increased life so they have time to eat
	life.one_shot = true
	life.timeout.connect(_on_death)
	add_child(life)
	life.start()

func _physics_process(delta):
	if is_dead: return
	
	# 1. Move
	var dir = (target_pos - global_position).normalized()
	velocity = dir * 50.0
	if velocity.x < 0: $Sprite2D.flip_h = true
	else: $Sprite2D.flip_h = false
	move_and_slide()
	
	if global_position.distance_to(target_pos) < 10.0:
		_pick_random_destination()

	# 2. Hunger Check (Every 4 seconds)
	hunger_timer += delta
	if hunger_timer > 4.0:
		hunger_timer = 0
		_check_hunger()

func _pick_random_destination():
	target_pos = Vector2(randf_range(50, 1200), randf_range(300, 650))

func _check_hunger():
	# If no data, assume safe
	if not species_data: return

	if species_data.diet == DinosaurSpecies.Diet.HERBIVORE:
		# Try to eat plants (Cost 1.0 density)
		if GameManager.consume_vegetation(1.0):
			show_popup("Yum") # Optional visual
		else:
			# STARVATION: No plants left!
			_take_damage()

	elif species_data.diet == DinosaurSpecies.Diet.CARNIVORE:
		# PRIORITY 1: Eat Critters [cite: 102]
		if GameManager.consume_critters(1.0):
			show_popup("Yum")
		else:
			# PRIORITY 2: The Desperation Rule (Hunt Herbivores) [cite: 104]
			_hunt_herbivore()

func _hunt_herbivore():
	# Find all dinos
	var all_dinos = get_tree().get_nodes_in_group("dinos")
	
	for dino in all_dinos:
		# Don't eat myself, and don't eat dead things
		if dino != self and not dino.is_dead:
			# Check if target is Herbivore
			if dino.species_data.diet == DinosaurSpecies.Diet.HERBIVORE:
				dino.die_from_predator()
				show_popup("HUNTED!")
				return # Ate one, stop hunting
	
	# If we found nothing to eat, we starve
	_take_damage()

func _take_damage():
	# Visual feedback for starvation
	modulate = Color(1, 0, 0) # Flash Red
	print(name + " is starving!")

func die_from_predator():
	_on_death() # Trigger normal death logic
	# Maybe add blood effect here later

# --- EXISTING DEATH/CLICK LOGIC ---
func _on_death():
	is_dead = true
	$Sprite2D.rotation_degrees = 180
	$Sprite2D.modulate = Color(0.5, 0.5, 0.5)

func _on_button_pressed():
	if is_dead:
		GameManager.add_fossils(1)
		queue_free()
	else:
		GameManager.add_dna(1)

# Helper for debug text (optional)
func show_popup(text):
	print(species_data.species_name + ": " + text)
