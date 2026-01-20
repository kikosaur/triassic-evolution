extends Node

# Signal to tell the UI (QuestPanel) to redraw the list
signal quests_updated

# --- CONFIGURATION ---
# This holds the "Blueprints" (Resources) loaded from the folder
var task_database: Array[TaskData] = []

# --- STATE ---
# This holds the "Live" data: { "data": Resource, "current": 0, "completed": false, "claimed": false }
var active_quests: Array = []

func _ready():
	# 1. LOAD TASKS AUTOMATICALLY
	# Scans the folder so you don't have to drag files manually
	_load_tasks_from_folder()
	
	# 2. SETUP LIVE STATE
	_initialize_quests()
	
	# 3. CONNECT SIGNALS
	# Listen for Money
	if GameManager.has_signal("dna_changed"):
		GameManager.connect("dna_changed", _on_dna_changed)
	
	# Listen for New Dinos (Make sure GameManager emits "dino_spawned" when buying!)
	if GameManager.has_signal("dino_spawned"):
		GameManager.connect("dino_spawned", _on_dino_event)
		
	# Listen for Research (Make sure GameManager emits "research_unlocked"!)
	if GameManager.has_signal("research_unlocked"):
		GameManager.connect("research_unlocked", _on_research_event)
	
	# Initial check (in case we loaded a save file with dinos already)
	_check_dino_count()

# --- AUTO-SCANNER ---
func _load_tasks_from_folder():
	var path = "res://resources/tasks/"
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Only load .tres files (ignore .import or folders)
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = path + file_name
				var task_res = load(full_path)
				
				if task_res is TaskData:
					print("Loaded Task: " + task_res.title)
					task_database.append(task_res)
			
			file_name = dir.get_next()
		
		# Optional: Sort them by ID so Task 1 is always first
		task_database.sort_custom(func(a, b): return a.id < b.id)
		print("Total Tasks Loaded: " + str(task_database.size()))
	else:
		print("Error: Could not find folder " + path + ". Please create it!")

# --- INITIALIZATION ---
func _initialize_quests():
	active_quests.clear()
	for task_res in task_database:
		# Create the runtime dictionary
		var q_state = {
			"data": task_res,
			"current": 0,
			"completed": false,
			"claimed": false
		}
		active_quests.append(q_state)

# --- EVENT HANDLERS ---

func _on_dna_changed(amount):
	for q in active_quests:
		if q.data.goal_type == "dna" and not q.completed:
			# If the task is "Have 100 DNA", checking current amount works.
			# If you want "Collect 100 DNA total", you need a separate counter.
			q.current = amount 
			_check_completion(q)

func _on_dino_event(_dino):
	# Whenever a dino spawns, re-count everything to be safe
	_check_dino_count()

func _on_research_event(research_id):
	for q in active_quests:
		if q.data.goal_type == "research" and not q.completed:
			# Check if the unlocked research matches the Target ID (e.g., "Upright Stance")
			if q.data.target_id == research_id:
				q.current = 1
				_check_completion(q)

# --- CHECKING LOGIC ---

func _check_dino_count():
	# 1. GET ALL DINOS
	var all_dinos = get_tree().get_nodes_in_group("dinos")
	print("\n--- QUEST DEBUG START ---")
	print("Found " + str(all_dinos.size()) + " dinos in group 'dinos'")
	
	# 2. CHECK EACH QUEST
	for q in active_quests:
		if q.data.goal_type == "dino_count" and not q.completed:
			var current_match_count = 0
			var quest_target = q.data.target_id
			
			print("Checking Quest: '" + q.data.title + "' (Looking for: '" + quest_target + "')")
			
			# 3. CHECK EACH DINO AGAINST THIS QUEST
			for dino in all_dinos:
				# Check if species_data exists
				if not "species_data" in dino:
					print("  [ERROR] Dino " + dino.name + " has NO 'species_data' variable!")
					continue
					
				var stats = dino.species_data
				if not stats:
					print("  [ERROR] Dino " + dino.name + " has empty (null) species_data!")
					continue
				
				# TRY TO FIND A NAME MATCH
				# We check both 'species_name' and 'id' in case you named the variable differently
				var dino_name = "UNKNOWN"
				if "species_name" in stats:
					dino_name = stats.species_name
				elif "id" in stats:
					dino_name = stats.id
				elif "name" in stats:
					dino_name = stats.name
				
				print("  > Found Dino: '" + dino_name + "' vs Target: '" + quest_target + "'")
				
				if dino_name == quest_target:
					current_match_count += 1
					print("    MATCH FOUND!")
			
			# 4. UPDATE
			q.current = current_match_count
			print("Final Count for this quest: " + str(current_match_count))
			_check_completion(q)
			
	print("--- QUEST DEBUG END ---\n")

func _check_completion(q):
	if q.current >= q.data.target_amount:
		if not q.completed:
			q.completed = true
			q.current = q.data.target_amount # Cap visual progress bar
			emit_signal("quests_updated")
			print("Task Completed: " + q.data.title)

# --- PUBLIC FUNCTIONS ---

func claim_reward(index):
	if index < 0 or index >= active_quests.size(): return
	
	var q = active_quests[index]
	if q.completed and not q.claimed:
		q.claimed = true
		
		# Give the DNA
		GameManager.add_dna(q.data.reward_dna)
		
		# Update UI
		emit_signal("quests_updated")
