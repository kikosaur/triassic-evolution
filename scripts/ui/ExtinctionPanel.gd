extends Panel
## ExtinctionPanel - Handles the prestige/reset mechanic.

# --- LOGGING (Set to false for production) ---
const DEBUG_MODE: bool = false

var reward_label: Label

func _ready() -> void:
	reward_label = get_node_or_null("RewardLabel")
	$ResetBtn.pressed.connect(_on_reset)
	
	# Close Button Logic
	var close_btn = get_node_or_null("CloseBtn")
	if close_btn:
		close_btn.pressed.connect(func(): visible = false)

func _on_show() -> void:
	var can_reset = _check_requirements()
	$ResetBtn.disabled = not can_reset
	
	if can_reset:
		# Calculate and display expected reward when panel opens
		var expected = _calculate_fossil_reward()
		if reward_label:
			reward_label.text = "Fossil Reward: +" + GameManager.format_number(expected)
	else:
		if reward_label:
			reward_label.text = "REQUIREMENTS NOT MET:\n"
			if not GameManager.is_all_research_unlocked():
				reward_label.text += "- Unlock All Research\n"
			if not QuestManager.are_all_quests_completed():
				reward_label.text += "- Complete All Tasks"

func _check_requirements() -> bool:
	return GameManager.is_all_research_unlocked() and QuestManager.are_all_quests_completed()

func _calculate_fossil_reward() -> int:
	# Base reward from research progress (1 fossil per unlocked node)
	var research_bonus = GameManager.unlocked_research_ids.size()
	
	# Bonus from total DPS (1 fossil per 100 DPS)
	var dps_bonus = int(GameManager.get_total_dna_per_second() / 100.0)
	
	# Bonus from vegetation progress (1 fossil per 20% density)
	var habitat_bonus = int(GameManager.vegetation_density / 20)
	
	# Minimum of 5 fossils + bonuses
	return 5 + research_bonus + dps_bonus + habitat_bonus

func _on_reset() -> void:
	# 1. Calculate and grant Fossil Reward BEFORE reset
	var fossil_reward = _calculate_fossil_reward()
	GameManager.add_fossils(fossil_reward)
	if DEBUG_MODE:
		print("ExtinctionPanel: Granted ", fossil_reward, " fossils")
	
	# 2. Calculate Prestige (10% bonus per run)
	GameManager.prestige_multiplier += 0.1
	
	# 3. Reset Game Data (but keep fossils!)
	var saved_fossils = GameManager.fossils # Preserve fossils
	GameManager.current_dna = 0
	GameManager.vegetation_density = 0
	GameManager.critter_density = 0
	GameManager.unlocked_research_ids = ["node_archosaur"] # Reset tree
	GameManager.owned_dinosaurs.clear()
	GameManager.fossils = saved_fossils # Restore fossils
	
	# 4. Play success sound
	AudioManager.play_sfx("success")
	
	# 5. Reload Scene
	get_tree().reload_current_scene()
