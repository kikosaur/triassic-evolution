extends Control

@onready var light_ray = $CenterContainer/LightRayHolder
# Note: We rotate the Holder, so the AnimatedSprite inside rotates with it.
@onready var icon_texture = $CenterContainer/Icon
@onready var title_label = $VBoxContainer/TitleLabel
@onready var desc_label = $VBoxContainer/DescLabel

var rotation_speed = 0.5
var time_passed = 0.0

func _ready():
	# Start invisible
	modulate.a = 0.0
	
	# Animate Entrance
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_property($CenterContainer, "scale", Vector2(1, 1), 0.6).from(Vector2(0, 0)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Play Sound
	AudioManager.play_sfx("success")

func _process(delta):
	time_passed += delta
	
	if light_ray:
		# Rotate
		light_ray.rotation += rotation_speed * delta
		
		# Throb (Sine wave scaling)
		var scale_amount = 1.0 + (sin(time_passed * 2.0) * 0.1) # Pulsate between 0.9 and 1.1
		light_ray.scale = Vector2(scale_amount, scale_amount)

func setup(research_id: String):
	# Look up the resource definition
	var target_res = null
	for res in ResourceRegistry.RESEARCH_FILES:
		if res and "id" in res and res.id == research_id:
			target_res = res
			break
			
	if target_res:
		set_content(target_res.display_name, target_res.icon)
	else:
		# Fallback
		set_content("New Discovery", null)
		print("ResearchUnlockPopup: Could not find resource for ID: ", research_id)

func set_content(title: String, icon: Texture2D):
	title_label.text = "UNLOCKED:\n" + title
	if icon:
		icon_texture.texture = icon
	
	# Reset scale for animation
	$CenterContainer.scale = Vector2.ZERO

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		_close()
	elif event is InputEventScreenTouch and event.pressed:
		_close()

func _close():
	set_process_input(false) # Prevent double clicks
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()
