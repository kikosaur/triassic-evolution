extends Control

# UI References
@onready var icon = $Icon
@onready var popup = $PopupPanel
@onready var details_label = $PopupPanel/MarginContainer/Content/Details
@onready var title_label = $PopupPanel/MarginContainer/Content/Title

var issues: Array = []
var recent_deaths: int = 0
var death_timer: float = 0.0
var suppressed: bool = false

func _ready():
	# Default state
	visible = false
	popup.visible = false
	
	# Connect Button for Hold-to-View (User Request)
	var btn = $Button
	btn.button_down.connect(_on_press_start)
	btn.button_up.connect(_on_press_end)

	# Listen for deaths
	if GameManager.has_signal("dinosaur_died"):
		GameManager.dinosaur_died.connect(_on_dino_died)

func _process(delta):
	issues.clear()
	
	# 1. Calculate Starvation Times First
	var min_herbivore_time = 9999.0
	var min_carnivore_time = 9999.0
	var has_herbivores = false
	var has_carnivores = false
	
	var all_dinos = get_tree().get_nodes_in_group("dinos")
	for dino in all_dinos:
		if is_instance_valid(dino) and not dino.is_dead and dino.species_data:
			if "starvation_timer" in dino:
				var t = dino.starvation_timer
				var diet = dino.species_data.diet
				
				if diet == DinosaurSpecies.Diet.HERBIVORE:
					has_herbivores = true
					if t < min_herbivore_time:
						min_herbivore_time = t
				else:
					has_carnivores = true
					if t < min_carnivore_time:
						min_carnivore_time = t

	# Helper to format time
	var _fmt_time = func(val: float) -> String:
		var t_int = max(0, int(val))
		var mins = t_int / 60
		var secs = t_int % 60
		return "%02d:%02d" % [mins, secs]

	# 2. Check Food Shortage + Add Death Timer
	if GameManager.vegetation_density <= 0:
		var msg = "[color=red]CRITICAL:[/color] Vegetation Depleted! (0%)"
		if has_herbivores:
			var time_str = _fmt_time.call(min_herbivore_time)
			msg += "\nThe Herbivores will die in %s" % time_str
		issues.append(msg)
		
	if GameManager.critter_density <= 0:
		if has_carnivores:
			if has_herbivores:
				issues.append("[color=orange]WARNING:[/color] Critters Depleted!\nWatch out! Your carnivores will start eating your herbivores.")
			else:
				var time_str = _fmt_time.call(min_carnivore_time)
				issues.append("[color=red]CRITICAL:[/color] Critters Depleted! (0%%)\nThe Carnivores will die in %s" % time_str)
		else:
			issues.append("[color=red]CRITICAL:[/color] Critters Depleted! (0%)")
		
	# 3. Check Biome Stress
	var stressed_dinos = []
	# (dinos iteration removed here since we did it above, but logic requires check)
	# Re-using the loop above would be efficient but let's keep it simple for now or merge
	for dino in all_dinos:
		if is_instance_valid(dino) and not dino.is_dead and dino.species_data:
			# Check age multiplier (tolerance proxy)
			if "age_multiplier" in dino and dino.age_multiplier > 1.1:
				var s_name = dino.species_data.species_name
				if not s_name in stressed_dinos:
					stressed_dinos.append(s_name)
	
	if stressed_dinos.size() > 0:
		var list_str = ", ".join(stressed_dinos)
		issues.append("[color=orange]STRESS:[/color] Biome Mismatch:\n" + list_str)

	# 4. Recent Deaths

	# 4. Recent Deaths
	if recent_deaths > 0:
		# Decay death warning over time
		death_timer -= delta
		if death_timer <= 0:
			recent_deaths = 0
		else:
			issues.append("[color=gray]DEATHS:[/color] " + str(recent_deaths) + " recent casualties.")

	# --- VISIBILITY ---
	if suppressed:
		visible = false
		return
		
	if issues.size() > 0:
		visible = true
		_update_popup_text()
	else:
		visible = false
		popup.visible = false

func _update_popup_text():
	var full_text = ""
	for issue in issues:
		full_text += issue + "\n\n"
	details_label.text = full_text

func _on_dino_died(_dino):
	recent_deaths += 1
	death_timer = 10.0 # Warning stays for 10 seconds after a death

func _on_press_start():
	popup.visible = true
	
func _on_press_end():
	popup.visible = false
