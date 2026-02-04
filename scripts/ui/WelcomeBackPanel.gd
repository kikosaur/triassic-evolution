extends Panel

@onready var time_label = $MarginContainer/VBoxContainer/TimeLabel
@onready var money_label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var btn_collect = $MarginContainer/VBoxContainer/Button

func _ready():
	visible = false
	btn_collect.pressed.connect(func(): visible = false)
	
	# Listen for the signal from GameManager
	GameManager.connect("offline_earnings_calculated", _on_earnings)
	
	# CHECK PENDING (Fixes race condition)
	if GameManager.pending_offline_earnings > 0:
		_on_earnings(GameManager.pending_offline_earnings, GameManager.pending_offline_time)
		# Clear after showing
		GameManager.pending_offline_earnings = 0
		GameManager.pending_offline_time = 0

func _on_earnings(amount, seconds):
	# FIX: Use 60.0 to force float math, then convert to int
	var minutes = int(seconds / 60.0)
	var hours = int(minutes / 60.0)
	
	if hours > 0:
		time_label.text = "Away for " + str(hours) + " hours"
	else:
		time_label.text = "Away for " + str(minutes) + " minutes"
		
	money_label.text = "+ " + str(amount) + " DNA"
	visible = true
