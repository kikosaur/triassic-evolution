extends Node2D
class_name DinoUnit

@export var species_data: DinosaurSpecies

# --- CONFIG ---
@export_group("Movement Settings")
@export var min_x: float = 50.0
@export var max_x: float = 1200.0
@export var min_y: float = 380.0
@export var max_y: float = 650.0

# --- STATE ---
var is_dead: bool = false
var current_age: float = 0.0
var age_multiplier: float = 1.0

# Movement
var target_position: Vector2
var move_speed: float = 30.0
var move_timer: float = 0.0
var is_moving: bool = false
var is_eating: bool = false

# Predation
var hunger: float = 0.0
var target_prey: Node2D = null

# Components
@onready var anim = $AnimatedSprite # CHANGED: Now references AnimatedSprite2D
var passive_timer: Timer

func _safe_play(anim_name: String):
	if anim_name == "" or not anim.sprite_frames: return
	
	if anim.sprite_frames.has_animation(anim_name):
		if anim.animation != anim_name:
			anim.play(anim_name)
	elif anim_name == "idle" and anim.sprite_frames.has_animation("default"):
		# Fallback: Play "default" if "idle" is missing
		if anim.animation != "default":
			anim.play("default")

func _ready():
	add_to_group("dinos")
	
	if species_data:
		# Check if animations exist
		if species_data.animations:
			anim.sprite_frames = species_data.animations
			
			# Q: Force a valid animation to prevent Errors
			var valid_anim = ""
			if anim.sprite_frames.has_animation("idle"):
				valid_anim = "idle"
			elif anim.sprite_frames.has_animation("default"):
				valid_anim = "default"
			else:
				# Pick first available if any
				var names = anim.sprite_frames.get_animation_names()
				if names.size() > 0:
					valid_anim = names[0]
			
			if valid_anim != "":
				anim.animation = valid_anim
				anim.play(valid_anim)
				
				# --- SIZE NORMALIZATION FIX ---
				# This ensures 4K images and Pixel Art images can coexist!
				var tex = anim.sprite_frames.get_frame_texture(valid_anim, 0)
				if tex:
					var raw_width = float(tex.get_width())
					
					# 1. Choose a "Standard" width in pixels for a 1.0 scale dino
					# (Adjustment: 200px looks good on 1080p)
					var base_target_width = 200.0
					
					# 2. Calculate how much we need to shrink/grow this specific image
					var resolution_scale = base_target_width / raw_width
					
					# 3. Combine with the Species "Game Size" factor
					# visual_scale 1.0 = Average, 0.5 = Small, 2.0 = Giant
					var final_s = resolution_scale * species_data.visual_scale
					
					anim.scale = Vector2(final_s, final_s)
			
			# Ensure we are safe
			# _safe_play("idle") # Redundant now
		
		# Old simple logic (Removed)
		# var global_shrink = 0.2
		# var s = species_data.visual_scale * global_shrink
		# anim.scale = Vector2(s, s)
		
		move_speed = randf_range(20.0, 40.0)
	
	_pick_random_destination()
	_setup_passive_timer()

func _process(delta):
	if is_dead: return
	
	_handle_aging(delta)
	
	# Only move if not busy eating
	if not is_eating:
		_handle_movement(delta)

func _handle_movement(delta):
	var dest = target_position
	
	# Hunting Logic
	if target_prey != null and is_instance_valid(target_prey):
		dest = target_prey.global_position
		move_speed = 60.0
		if position.distance_to(dest) < 15.0:
			_eat_prey(target_prey)

	# Movement Physics
	if position.distance_to(dest) > 5.0:
		is_moving = true
		position = position.move_toward(dest, move_speed * delta)
		
		# ANIMATION: Walk
		_safe_play("walk") # <--- Use Safe Play
			
		# FLIP
		if dest.x < position.x:
			anim.flip_h = true
		else:
			anim.flip_h = false
			
	else:
		is_moving = false
		
		# ANIMATION: Idle
		_safe_play("idle") # <--- Use Safe Play

		move_timer -= delta
		if move_timer <= 0:
			_pick_random_destination()

func _on_tick():
	if is_dead or not species_data: return
	
	var ate_food = false
	var rate = species_data.consumption_rate if species_data.consumption_rate != null else 0.05
	
	if species_data.diet == DinosaurSpecies.Diet.HERBIVORE:
		ate_food = GameManager.consume_vegetation(rate)
	else:
		ate_food = GameManager.consume_critters(rate)
	
	if ate_food:
		# Scale reward by the time interval (Burst income)
		var income = species_data.passive_dna_yield * passive_timer.wait_time
		GameManager.add_dna(income)
		
		hunger = 0.0
		target_prey = null
		_play_eat_animation()
	else:
		hunger += 1.0
		# Trigger Hunt Logic
		if species_data.diet == DinosaurSpecies.Diet.CARNIVORE and hunger > 5.0 and target_prey == null:
			target_prey = GameManager.get_nearest_herbivore(global_position)
	
	# Reset timer to new random interval
	passive_timer.wait_time = randf_range(20.0, 30.0)

func _play_eat_animation():
	if is_eating: return
	is_eating = true
	
	# Play "eat" animation if it exists
	if anim.sprite_frames.has_animation("eat"):
		anim.play("eat")
		await anim.animation_finished # Wait for it to finish
	else:
		# Fallback if no eat animation: just wait 0.5s
		await get_tree().create_timer(0.5).timeout
	
	is_eating = false
	# anim.play("idle") # REMOVED: Let _process handle the next state (Idle or Walk) naturally

func _eat_prey(prey):
	if is_instance_valid(prey):
		prey.die()
		hunger = 0.0
		target_prey = null
		_play_eat_animation()
		_pick_random_destination()

func _pick_random_destination():
	if target_prey != null: return
	var x = randf_range(min_x, max_x)
	var y = randf_range(min_y, max_y)
	target_position = Vector2(x, y)
	move_timer = randf_range(2.0, 5.0)

# (Keep Aging, Die, and Fossil Logic same as before)
func die():
	if is_dead: return
	is_dead = true
	
	if passive_timer: passive_timer.stop()
	
	# IMPROVED DEATH LOGIC
	# 1. Try to play death animation
	if anim.sprite_frames.has_animation("die"):
		anim.play("die")
		# Optional: Tint it slightly so it looks dead even with placeholder art
		anim.modulate = Color(0.6, 0.6, 0.6)
	else:
		# 2. Fallback: Stop and fade to gray
		anim.stop()
		anim.modulate = Color(0.5, 0.5, 0.5) # Gray corpse
	
	# FIX: Auto-delete after 60 seconds to prevent lag
	var rot_timer = get_tree().create_timer(60.0)
	rot_timer.timeout.connect(queue_free)

func _handle_aging(delta):
	if not species_data: return
	var current_phase = GameManager.get_current_biome_phase()
	var ideal = species_data.ideal_biome_phase
	
	if current_phase == ideal:
		age_multiplier = 1.0
		# Restore color if they return to valid biome
		anim.modulate = anim.modulate.lerp(Color(1, 1, 1), delta * 2.0)
	else:
		var mismatch = abs(current_phase - ideal)
		var tolerance = species_data.tolerance
		age_multiplier = 1.0 + (mismatch * (1.0 - tolerance) * 2.0)
		
		# FIX: Removed the red tint "warning". 
		# If you want visual feedback, maybe just slightly dim it, 
		# but "Turning Red" was too aggressive.
		# anim.modulate = anim.modulate.lerp(Color(1, 0.8, 0.8), delta * 5.0) 
		
	current_age += delta * age_multiplier
	if current_age >= species_data.base_lifespan:
		die()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_click_on_sprite(event.position):
			if is_dead:
				# Dead dino: Harvest fossil
				_harvest_fossil()
			else:
				# Living dino: Give click yield DNA bonus
				_on_dino_clicked()

func _on_dino_clicked():
	if not species_data: return
	GameManager.add_dna(species_data.click_yield)
	AudioManager.play_sfx("click")
	
	# Optional: Visual feedback (small bounce)
	var tween = create_tween()
	tween.tween_property(anim, "scale", anim.scale * 1.1, 0.1)
	tween.tween_property(anim, "scale", anim.scale, 0.1)

func _harvest_fossil():
	if GameManager.has_method("add_fossils"):
		GameManager.add_fossils(1)
		AudioManager.play_sfx("success")
	queue_free()

func _setup_passive_timer():
	passive_timer = Timer.new()
	passive_timer = Timer.new()
	# Randomize eating interval to 20-30 seconds (User Request)
	passive_timer.wait_time = randf_range(20.0, 30.0)
	passive_timer.autostart = true
	add_child(passive_timer)
	passive_timer.timeout.connect(_on_tick)

# Helper function to replace get_rect()
func _is_click_on_sprite(mouse_global_pos: Vector2) -> bool:
	if not anim.sprite_frames: return false
	
	# 1. Get the texture of the current frame
	var tex = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	if not tex: return false
	
	# 2. Get local mouse position relative to the dino
	var local_pos = anim.to_local(mouse_global_pos)
	
	# 3. Calculate the box (Assuming the sprite is Centered)
	var size = tex.get_size()
	# If your sprite is centered (default), the box goes from -width/2 to +width/2
	var rect = Rect2(-size / 2, size)
	
	return rect.has_point(local_pos)
