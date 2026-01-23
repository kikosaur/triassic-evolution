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
		"text": "Welcome to Triassic Evolution! Life begins here. Let's check your first task.",
		"highlight": "quest_btn", # ID of the UI element to highlight
		"alignment": "center"
	},
	{
		"text": "Open the Quest Log to see your goals. Complete tasks to earn DNA.",
		"highlight": "quest_panel",
		"alignment": "top_right"
	},
	{
		"text": "Great! Now you need to unlock your first dinosaur: The Archosaur.",
		"highlight": "research_btn",
		"alignment": "bottom_left"
	},
	{
		"text": "Once unlocked, you can breed them here. Gather 5 to complete your task!",
		"highlight": "dino_container", # Just a general area hint
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
