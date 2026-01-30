extends Control
## TutorialOverlay.gd

@onready var label = $Panel/Label
@onready var highlight_rect = $HighlightRect
@onready var next_btn = $Panel/Button

# Target UI nodes (We will find them by name/group or have them registered)
# ideally, we map "Ids" to specific positions.

func _ready():
	TutorialManager.step_changed.connect(_on_step_changed)
	next_btn.pressed.connect(func(): TutorialManager.next_step())
	
	# Initial update if data exists
	if TutorialManager.current_step >= 0:
		_on_step_changed(TutorialManager.current_step, TutorialManager.steps[TutorialManager.current_step])

	# SAFETY: Force Dimmer to ignore mouse clicks
	# The dimmer might be defaulting to STOP, blocking buttons underneath
	$Dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HighlightRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_step_changed(_index, data):
	# Add center tags for RichTextLabel styling
	label.text = "[center]" + data["text"] + "[/center]"
	
	# Move Highlight
	var highlight_id = data["highlight"]
	_move_highlight(highlight_id)

func _move_highlight(id: String):
	# Default: Center screen if not found
	var target_rect = Rect2(get_viewport_rect().size / 2 - Vector2(100, 100), Vector2(200, 200))
	
	# --- LOCATE UI ELEMENTS ---
	# This logic searches the MainGame tree for specific named buttons
	# It allows the tutorial to point at things dynamically.
	var main_game = get_tree().root.get_node_or_null("MainGame")
	var target_node = null
	
	if main_game:
		if id == "quest_btn":
			target_node = main_game.find_child("BtnTasks", true, false)
		elif id == "quest_panel":
			target_node = main_game.find_child("QuestPanel", true, false)
		elif id == "research_btn":
			target_node = main_game.find_child("BtnToggleResearch", true, false)
		elif id == "shop_btn":
			target_node = main_game.find_child("BtnToggleShop", true, false)
		elif id == "museum_btn":
			target_node = main_game.find_child("BtnMuseum", true, false)
		elif id == "habitat_bars":
			target_node = main_game.find_child("HabitatPanel", true, false)
		elif id == "dino_container":
			target_node = main_game.find_child("DinoContainer", true, false)
	
	# Only attempt to track size if it's a UI Control
	if target_node and target_node.is_visible_in_tree() and target_node is Control:
		# Get Global Rect
		var pos = target_node.get_global_position()
		var target_size = target_node.size
		target_rect = Rect2(pos, target_size)
		
	# Animate highlighter
	var tween = create_tween()
	tween.tween_property(highlight_rect, "position", target_rect.position, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(highlight_rect, "size", target_rect.size, 0.5).set_trans(Tween.TRANS_CUBIC)
