extends Node

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
	var folder_path = "res://resources/tasks/"
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(folder_path + file_name)
				if res is TaskData:
					var state = {
						"data": res,
						"current": 0,
						"completed": false,
						"claimed": false
					}
					active_quests.append(state)
			
			file_name = dir.get_next()
		
		# Sort by ID
		active_quests.sort_custom(func(a, b): return a.data.id < b.data.id)
		
		# Run an initial check after a short delay to let Dinos load
		await get_tree().create_timer(0.1).timeout
		_recalculate_all()
	else:
		print("ERROR: Could not find folder " + folder_path)

# --- CHECKING LOGIC ---

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
		# Only process "Counter" type quests
		if q.data.goal_type == "dino_count" and not q.completed:
			var count = 0
			var target_name = q.data.target_id.strip_edges() # "Archosaur"
			
			# 1. COUNT THE DINOS
			for dino in all_dinos:
				var found_name = ""
				
				# Smart Check: Look in Resource first, then Variable
				if "species_data" in dino and dino.species_data != null:
					found_name = dino.species_data.species_name
				elif "species_name" in dino:
					found_name = dino.species_name
				
				# Compare
				if found_name == target_name:
					count += 1
			
			# 2. UPDATE THE QUEST DATA
			if q.current != count:
				q.current = count
				something_changed = true
				print("Quest Updated: " + q.data.title + " is now " + str(count))
				_check_complete(q)

	# 3. TELL THE UI TO REFRESH
	if something_changed:
		emit_signal("quests_updated")

func _check_complete(q):
	if q.current >= q.data.target_amount:
		if not q.completed:
			q.completed = true
			q.current = q.data.target_amount
			# Note: We don't emit here because the calling function handles the emit
			print("COMPLETED QUEST: " + q.data.title)

# --- REWARD SYSTEM ---
func claim_reward(index):
	if index < 0 or index >= active_quests.size(): return
	
	var q = active_quests[index]
	if q.completed and not q.claimed:
		q.claimed = true
		GameManager.add_dna(q.data.reward_dna)
		emit_signal("quests_updated")
