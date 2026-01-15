extends Node2D
class_name DinoUnit

@export var species_data: DinosaurSpecies

# --- STATE VARIABLES ---
var is_dead: bool = false
var current_age: float = 0.0
var age_multiplier: float = 1.0

# Movement Variables
var target_position: Vector2
var move_speed: float = 30.0
var move_timer: float = 0.0

# Components
@onready var sprite = $Sprite2D
var passive_timer: Timer

func _ready():
	# 1. SETUP VISUALS
	if species_data:
		sprite.texture = species_data.icon
		# Randomize speed slightly so they don't all move in sync
		move_speed = randf_range(20.0, 40.0) 
	
	# 2. PICK FIRST DESTINATION
	_pick_random_destination()
	
	# 3. START PASSIVE INCOME & EATING
	_setup_passive_timer()

func _process(delta):
	if is_dead: return 
	
	_handle_aging(delta)
	_handle_movement(delta)

# --- MOVEMENT LOGIC (RESTORED) ---
func _handle_movement(delta):
	# Move towards target
	position = position.move_toward(target_position, move_speed * delta)
	
	# Flip sprite based on direction
	if target_position.x < position.x:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
		
	# Check if we arrived
	if position.distance_to(target_position) < 5.0:
		move_timer -= delta
		if move_timer <= 0:
			_pick_random_destination()

func _pick_random_destination():
	# Pick a random spot on the screen (adjust numbers to fit your map size)
	var x = randf_range(100, 1100) # Keep within screen width
	var y = randf_range(300, 600)  # Keep on the ground
	target_position = Vector2(x, y)
	move_timer = randf_range(2.0, 5.0) # Wait 2-5 seconds before moving again

# --- AGING LOGIC (KEPT) ---
func _handle_aging(delta):
	if not species_data: return

	var current_phase = GameManager.get_current_biome_phase()
	var ideal = species_data.ideal_biome_phase
	
	if current_phase == ideal:
		age_multiplier = 1.0
		sprite.modulate = sprite.modulate.lerp(Color(1, 1, 1), delta * 5.0) 
	else:
		var mismatch = abs(current_phase - ideal) 
		var tolerance = species_data.tolerance
		age_multiplier = 1.0 + (mismatch * (1.0 - tolerance) * 2.0)
		sprite.modulate = sprite.modulate.lerp(Color(1, 0.4, 0.4), delta * 5.0)

	current_age += delta * age_multiplier
	
	if current_age >= species_data.base_lifespan:
		die()

# --- EATING & INCOME LOGIC (RESTORED) ---
func _setup_passive_timer():
	passive_timer = Timer.new()
	passive_timer.wait_time = 1.0
	passive_timer.autostart = true
	add_child(passive_timer)
	passive_timer.timeout.connect(_on_tick)

func _on_tick():
	if is_dead or not species_data: return
	
	# 1. TRY TO EAT
	var ate_food = false
	
	# Check diet (0 = Herbivore, 1 = Carnivore)
	if species_data.diet == DinosaurSpecies.Diet.HERBIVORE:
		# Try to eat 1% Vegetation
		ate_food = GameManager.consume_vegetation(1.0) 
	else:
		# Try to eat 1% Critters
		ate_food = GameManager.consume_critters(1.0)
	
	# 2. GENERATE DNA (Only if they ate!)
	if ate_food:
		GameManager.add_dna(species_data.passive_dna_yield)
	else:
		# Optional: Take damage or age faster if starving?
		print(species_data.species_name + " is starving!")

# --- DEATH & HARVESTING (KEPT) ---
func die():
	if is_dead: return 
	is_dead = true
	
	sprite.modulate = Color(0.4, 0.35, 0.3) 
	sprite.rotation_degrees = 180 
	sprite.position.y += 10 
	
	if passive_timer: passive_timer.stop()
	print("Dino died! Click to harvest fossil.")

func _unhandled_input(event):
	if is_dead and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if sprite.get_rect().has_point(sprite.to_local(event.position)):
			_harvest_fossil()

func _harvest_fossil():
	if GameManager.has_method("add_fossils"):
		GameManager.add_fossils(1)
	queue_free()
