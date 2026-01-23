extends Panel

@onready var dna_label = %DNALabel
@onready var fossil_label = %FossilLabel
@onready var dna_info_popup = %DNAInfoPopup
@onready var fossil_info_popup = %FossilInfoPopup

func _ready():
	GameManager.connect("dna_changed", _update_dna)
	GameManager.connect("fossils_changed", _update_fossils)
	
	_update_dna(GameManager.current_dna)
	_update_fossils(GameManager.fossils)
	_update_year(GameManager.current_year)
	_update_year(GameManager.current_year)
	GameManager.connect("year_advanced", _update_year)
	
	# Connect Settings Button
	var btn_settings = find_child("BtnSettings", true, false)
	if btn_settings:
		btn_settings.pressed.connect(_on_settings_pressed)

func _on_settings_pressed():
	# Find the SettingsPanel in the scene tree (it's likely a sibling or in UI_Layer)
	var main_node = get_tree().root.get_node_or_null("MainGame")
	if main_node:
		var settings_panel = main_node.find_child("SettingsPanel", true, false)
		if settings_panel:
			settings_panel.show()
			settings_panel.move_to_front()
			AudioManager.play_sfx("click")
		else:
			print("TopPanel: SettingsPanel node not found in MainGame!")
	else:
		# Fallback if testing scene isolated
		print("TopPanel: MainGame root not found!")

func _update_year(amount: int):
	# Optional: Format as "Year X" or "X Years"
	# Optional: Format as "Year X" or "X Years"
	var year_lbl = find_child("YearLabel", true, false)
	if year_lbl:
		year_lbl.text = "Year " + str(amount)

func update_dps_label(amount: int):
	# Using find_child for safety if path changes again
	var rate_lbl = find_child("RateLabel", true, false)
	if rate_lbl:
		rate_lbl.text = "+ " + GameManager.format_number(amount) + "/s"

func _update_dna(amount):
	dna_label.text = GameManager.format_number(amount)

func _update_fossils(amount):
	fossil_label.text = GameManager.format_number(amount)

# DNA button press and hold
func _on_dna_button_down():
	if dna_info_popup.has_method("show_dna_info"):
		dna_info_popup.show_dna_info()
	else:
		dna_info_popup.show()
	dna_info_popup.move_to_front()

func _on_dna_button_up():
	dna_info_popup.hide()

func _on_fossil_button_down():
	fossil_info_popup.show()
	fossil_info_popup.move_to_front()

func _on_fossil_button_up():
	fossil_info_popup.hide()
