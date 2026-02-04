extends Node
## TutorialManager.gd
## Manages the new user onboarding sequence.

# --- SIGNALS ---
signal step_changed(step_index: int, data: Dictionary)
signal tutorial_completed

# --- CONFIG ---
const TUTORIAL_QUEST_ID = "task_01"

# --- STATE ---
var current_step: int = -1
var is_active: bool = false
var overlay_node: Control = null

# Step Definitions
# 0: Welcome
# 1: Highlight Quest Log
# 2: Highlight Research Button
# 3: Highlight Buy Button (Generic area or specific if possible)
var steps = [
	{
		"text": "Welcome to Triassic Evolution! Let's start with the basics.\n\n[b]Tap Anywhere[/b] on the ground to earn DNA! Try it now!",
		"highlight": "center", # No specific button, just center
		"alignment": "center"
	},
	{
		"text": "Great! Dinosaurs generate [b]Passive DNA[/b] every second as long as they are fed.\n\nYou can also [b]Tap Them[/b] for an instant bonus!",
		"highlight": "center",
		"alignment": "center"
	},
	{
		"text": "Open the [b]Research Menu[/b] to unlock new species. This is how you advance through the Triassic era.",
		"highlight": "research_btn",
		"alignment": "bottom_left"
	},
	{
		"text": "Once unlocked, buy Dinosaurs in the [b]Shop[/b].\n\nCheck their **Stats** (Income & Consumption) in the info popup before buying!",
		"highlight": "shop_btn",
		"alignment": "bottom_left"
	},
	{
		"text": "Your dinosaurs need food to survive! If [b]Food Runs Out[/b], their DNA income stops.\n\nDon't forget the [b]Habitat Tab[/b] to buy vegetation!",
		"highlight": "habitat_bars",
		"alignment": "center"
	},
	{
		"text": "Monitor your park at the top! The [b]Active Counter[/b] shows your population (Max 25).\n\nThe [b]Biome Label[/b] shows if you are in a Desert, Oasis, or Forest.",
		"highlight": "center",
		"alignment": "top_center"
	},
	{
		"text": "Check the [b]Task Log[/b] often! Completing goals earns you huge DNA rewards to evolve faster.",
		"highlight": "quest_btn",
		"alignment": "top_right"
	},
	{
		"text": "As you buy Habitat items, the world transforms!\n\n**Tip:** You must unlock [b]River[/b] and [b]Forest[/b] research nodes to advance beyond the Desert phase.",
		"highlight": "habitat_bars",
		"alignment": "center"
	},
	{
		"text": "Each species has a preferred Biome Phase (1, 2, or 3).\n\n[color=red]Warning:[/color] In the wrong biome, dinosaurs become [b]Stressed[/b]. They die younger and produce less DNA!",
		"highlight": "habitat_bars",
		"alignment": "center"
	},
	{
		"text": "If critical issues arise (like Starvation or Stress), a [b]Warning Icon[/b] will appear.\n\n[b]Tap It[/b] to see exactly what needs fixing!",
		"highlight": "center",
		"alignment": "center"
	},
	{
		"text": "The [b]Museum[/b] tracks your collection.\n\nKeep an eye out for Fossils ([color=yellow]+1[/color]) when dinos die—they are rare and valuable!",
		"highlight": "museum_btn",
		"alignment": "bottom_left"
	},
	{
		"text": "That's all for now. Good luck on your journey to evolve the ultimate Triassic ecosystem!",
		"highlight": "center",
		"alignment": "center"
	}
]

func _ready():
	# Wait for Game Load
	await get_tree().process_frame
	
func check_start():
	# Only start if Task 01 is active and progress is 0, AND not already done
	if GameManager.tutorial_completed:
		return

	if QuestManager.active_quests.size() > 0:
		var q1 = QuestManager.active_quests[0]
		if q1.data.id == TUTORIAL_QUEST_ID and q1.current == 0 and not q1.completed:
			start_tutorial()
		else:
			print("TutorialManager: Player is advanced, skipping tutorial.")

func start_tutorial():
	if is_active: return
	is_active = true
	current_step = 0
	
	# Spawn Overlay if not present
	_spawn_overlay()
	_update_step()
	
	
func reset_tutorial():
	# Force restart even if completed
	GameManager.tutorial_completed = false
	if is_active:
		if overlay_node: overlay_node.queue_free()
		is_active = false
	start_tutorial()
	
func next_step():
	if not is_active: return
	
	current_step += 1
	if current_step >= steps.size():
		complete_tutorial()
	else:
		_update_step()

func _update_step():
	var data = steps[current_step]
	emit_signal("step_changed", current_step, data)

func complete_tutorial():
	is_active = false
	GameManager.tutorial_completed = true
	emit_signal("tutorial_completed")
	if overlay_node:
		overlay_node.queue_free()
		overlay_node = null

func _spawn_overlay():
	var scene = load("res://scenes/ui/TutorialOverlay.tscn")
	if scene:
		overlay_node = scene.instantiate()
		# Add to the highest layer of MainGame
		var root = get_tree().root.get_node_or_null("MainGame/UI_Layer")
		if root:
			root.add_child(overlay_node)
		else:
			# Fallback for testing
			get_tree().root.add_child(overlay_node)
