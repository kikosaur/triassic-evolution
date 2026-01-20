extends Panel

@onready var quest_list = $ScrollContainer/QuestList
var item_scene = preload("res://scenes/ui/QuestItem.tscn") # Make sure path is right!

func _ready():
	visible = false
	QuestManager.connect("quests_updated", _refresh_list)
	$Button.pressed.connect(func(): visible = false)

func show_panel():
	visible = true
	_refresh_list()

func _refresh_list():
	# Clear old items
	for child in quest_list.get_children():
		child.queue_free()
	
	# Create new items
	# CHANGE 1: Use 'active_quests' instead of 'quests'
	for i in range(QuestManager.active_quests.size()):
		var q_state = QuestManager.active_quests[i] # Get the dictionary {data, current, etc}
		
		var item = item_scene.instantiate()
		quest_list.add_child(item)
		
		# CHANGE 2: Pass the whole state object
		item.setup(q_state, i)
