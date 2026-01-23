extends Panel

const ITEM_SCENE = preload("res://scenes/ui/QuestItem.tscn")

@onready var list_container = $ScrollContainer/QuestList
@onready var close_btn = $CloseBtn

func _ready():
	close_btn.pressed.connect(_on_close_pressed)
	
	# Update whenever the manager says so
	QuestManager.connect("quests_updated", _refresh_ui)
	
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

func _on_visibility_changed():
	var scroll = $ScrollContainer
	if visible:
		scroll.visible = true
		scroll.process_mode = PROCESS_MODE_INHERIT
	else:
		scroll.visible = false
		scroll.process_mode = PROCESS_MODE_DISABLED
	

	# Initial draw - Defer to avoid viewport null error
	# _refresh_ui() 

func _refresh_ui():
	# Guard: Only update if visible to prevent ScrollContainer errors in background
	if not visible: return

	# 1. Clear old items
	for child in list_container.get_children():
		child.queue_free()
	
	# 2. Create new items
	var all_quests = QuestManager.active_quests
	
	for i in range(all_quests.size()):
		var q_state = all_quests[i]
		
		# Optional: Only show unclaimed quests (remove this if you want to see history)
		# if q_state.claimed: continue 
		
		var item = ITEM_SCENE.instantiate()
		list_container.add_child(item)
		item.setup(q_state, i)

func show_panel():
	# 1. Force the manager to re-check everything right now
	QuestManager._recalculate_all()
	
	# 2. Show the window FIRST (so _refresh_ui passes the visibility check)
	show()
	
	# 3. Re-draw the visual list
	_refresh_ui()

func _on_close_pressed():
	AudioManager.play_sfx("click")
	hide() # This is the same as visible = false
	# Optional: AudioManager.play_sfx("ui_click")
