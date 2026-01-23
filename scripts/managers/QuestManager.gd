extends Node
## QuestManager - Handles quest/task tracking and rewards.
## Autoload singleton accessible globally.

# --- LOGGING (Set to false for production) ---
const DEBUG_MODE: bool = false

signal quests_updated # Tells UI to redraw

# Holds the state of every quest
var active_quests: Array = []

func _ready():
	_load_all_tasks()
	
	# LISTEN FOR GAME EVENTS (With duplicate connection protection)
	if GameManager.has_signal("dna_changed"):
		if not GameManager.dna_changed.is_connected(_on_dna_changed):
			GameManager.dna_changed.connect(_on_dna_changed)
	
	if GameManager.has_signal("dino_spawned"):
		if not GameManager.dino_spawned.is_connected(_on_dino_event):
			GameManager.dino_spawned.connect(_on_dino_event)
		
	if GameManager.has_signal("research_unlocked"):
		if not GameManager.research_unlocked.is_connected(_on_research_event):
			GameManager.research_unlocked.connect(_on_research_event)

# --- LOADING SYSTEM ---
func _load_all_tasks():
	active_quests.clear()
	active_quests.clear()
	
	# FIX: Use Registry instead of DirAccess for Mobile compatibility!
	var task_files = ResourceRegistry.TASK_FILES
	
	for res in task_files:
		if res is TaskData:
			var state = {
				"data": res,
				"current": 0,
				"completed": false,
				"claimed": false
			}
			active_quests.append(state)
	
	# Sort by ID
	active_quests.sort_custom(func(a, b): return a.data.id < b.data.id)
	
	# Run an initial check after a short delay to let Dinos load
	await get_tree().create_timer(0.1).timeout
	_recalculate_all()

# --- CHECKING LOGIC ---

func reset_quests():
	_load_all_tasks()
	emit_signal("quests_updated")

func _on_dna_changed(amount):
	var needs_update = false
	for q in active_quests:
		if q.data.goal_type == "currency" and not q.completed:
			# Update progress
			if q.current != amount:
				q.current = amount
				needs_update = true
				_check_complete(q)
	
	if needs_update:
		emit_signal("quests_updated")

func _on_research_event(research_id):
	var needs_update = false
	for q in active_quests:
		if q.data.goal_type == "research" and not q.completed:
			# Check exact ID match
			if q.data.target_id == research_id:
				q.current = 1
				needs_update = true
				_check_complete(q)
				
	if needs_update:
		emit_signal("quests_updated")

func _on_dino_event(_dino_node):
	_recalculate_all()

func _recalculate_all():
	var all_dinos = get_tree().get_nodes_in_group("dinos")
	var something_changed = false
	
	for q in active_quests:
		if q.completed: continue
		
		# 1. DINO COUNT
		if q.data.goal_type == "dino_count":
			var count = 0
			var target_name = q.data.target_id.strip_edges() # "Archosaur"
			
			# Count...
			for dino in all_dinos:
				var found_name = ""
				if "species_data" in dino and dino.species_data != null:
					found_name = dino.species_data.species_name
				elif "species_name" in dino:
					found_name = dino.species_name
				
				if found_name == target_name:
					count += 1
			
			if q.current != count:
				q.current = count
				something_changed = true
				if DEBUG_MODE:
					print("QuestManager: Quest '", q.data.title, "' progress: ", count)
				_check_complete(q)
				
		# 2. RESEARCH (Retroactive Check)
		elif q.data.goal_type == "research":
			if q.data.target_id in GameManager.unlocked_research_ids:
				if q.current != 1:
					q.current = 1
					something_changed = true
					_check_complete(q)
					
		# 3. CURRENCY (Retroactive Check)
		elif q.data.goal_type == "currency" or q.data.goal_type == "dna":
			if q.current != GameManager.current_dna:
				q.current = GameManager.current_dna
				something_changed = true
				_check_complete(q)

	# 3. TELL THE UI TO REFRESH
	if something_changed:
		emit_signal("quests_updated")

func _check_complete(q: Dictionary) -> void:
	if q.current >= q.data.target_amount:
		if not q.completed:
			q.completed = true
			q.current = q.data.target_amount
			if DEBUG_MODE:
				print("QuestManager: Completed quest '", q.data.title, "'")

# --- REWARD SYSTEM ---
func claim_reward(index):
	if index < 0 or index >= active_quests.size(): return
	
	var q = active_quests[index]
	if q.completed and not q.claimed:
		q.claimed = true
		GameManager.add_dna(q.data.reward_dna)
		emit_signal("quests_updated")
# --- PERSISTENCE ---
func get_save_data() -> Array:
	var save_data = []
	for q in active_quests:
		save_data.append({
			"id": q.data.id,
			"current": q.current,
			"completed": q.completed,
			"claimed": q.claimed
		})
	return save_data

func load_save_data(data_list: Array):
	for saved_q in data_list:
		# Find the matching quest logic
		for active_q in active_quests:
			if active_q.data.id == saved_q["id"]:
				active_q.current = saved_q["current"]
				active_q.completed = saved_q["completed"]
				active_q.claimed = saved_q["claimed"]
				break
	
	emit_signal("quests_updated")
