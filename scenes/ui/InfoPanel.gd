extends Panel

# Notice the paths now include "MarginContainer"
@onready var title_lbl = $MarginContainer/VBoxContainer/TitleLabel
@onready var content_text = $MarginContainer/VBoxContainer/ScrollContainer/ContentText
@onready var close_btn = $MarginContainer/VBoxContainer/CloseButton

func _ready():
	# Connect the close button signal
	close_btn.pressed.connect(func(): hide())

func setup_popup(title: String, text: String):
	title_lbl.text = title
	content_text.text = text
	
	# Reset scroll to top every time we open it
	var scroll = $MarginContainer/VBoxContainer/ScrollContainer
	scroll.visible = true
	scroll.scroll_vertical = 0
	
	show()
	move_to_front() # Bring to frontfront
