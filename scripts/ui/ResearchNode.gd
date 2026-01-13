extends Control

@export var my_data: ResearchDef
@export var parent_node: Control # Link this in Inspector!

@onready var btn = $BtnNode
@onready var lbl_name = $NameLabel
@onready var lbl_cost = $CostLabel
@onready var line = $LinkLine

func _ready():
	btn.pressed.connect(_on_click)
	
	# Draw line to parent
	if parent_node:
		line.clear_points()
		line.add_point(size / 2) # My Center
		# Parent Center (Relative)
		var target = parent_node.position - position + (parent_node.size / 2)
		line.add_point(target)

func _process(_delta):
	_update_visuals()

func _update_visuals():
	if not my_data: return
	
	var is_unlocked = GameManager.is_research_unlocked(my_data)
	var parent_unlocked = true
	if my_data.parent_research:
		parent_unlocked = GameManager.is_research_unlocked(my_data.parent_research)
	
	if is_unlocked:
		modulate = Color(1, 1, 1) # Normal
		lbl_cost.text = "OWNED"
		lbl_name.text = my_data.display_name
	elif parent_unlocked:
		modulate = Color(0.7, 0.7, 0.7) # Gray (Available)
		# CHANGED: Show DNA Cost
		lbl_cost.text = str(my_data.dna_cost) + " DNA"
		lbl_name.text = "???"
	else:
		modulate = Color(0.2, 0.2, 0.2) # Dark (Locked)
		lbl_cost.text = "LOCKED"
		lbl_name.text = "LOCKED"

func _on_click():
	# CHANGED: Just call the manager, it handles the spending check now
	GameManager.try_unlock_research(my_data)
