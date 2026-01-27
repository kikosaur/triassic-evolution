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
	# 1. Calculate Rewards & Prestige
	var fossil_reward = _calculate_fossil_reward()
	GameManager.prestige_multiplier += 0.1
	
	# 2. Capture Total Fossils to Preserve (Current + Reward)
	# We don't add them yet because reset_game_state() would wipe them.
	var final_fossils = GameManager.fossils + fossil_reward
	
	if DEBUG_MODE:
		print("ExtinctionPanel: Resetting. Preserving ", final_fossils, " fossils.")
	
	# 3. RESET GAME STATE (Logic in GameManager handles Tasks, Year, DNA, etc.)
	GameManager.reset_game_state()
	
	# 4. Restore Fossils
	GameManager.fossils = final_fossils
	GameManager.emit_signal("fossils_changed", final_fossils)
	
	# 5. Play success sound
	AudioManager.play_sfx("success")
	
	# 6. Reload Scene via LoadingScreen to ensure clean state
	get_tree().change_scene_to_file("res://scenes/ui/LoadingScreen.tscn")
