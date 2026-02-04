extends Panel

@onready var dna_label = %DNALabel
@onready var fossil_label = %FossilLabel
@onready var dna_info_popup = %DNAInfoPopup
@onready var fossil_info_popup = %FossilInfoPopup
@onready var active_dino_label = %ActiveDinoLabel
@onready var biome_label = %BiomeLabel

func _ready():
	GameManager.connect("dna_changed", _update_dna)
	GameManager.connect("fossils_changed", _update_fossils)
	GameManager.connect("dinosaur_spawned", _on_dino_count_changed)
	GameManager.connect("dinosaur_died", _on_dino_count_changed)
	GameManager.connect("habitat_updated", _on_habitat_changed)
	
	_update_dna(GameManager.current_dna)
	_update_fossils(GameManager.fossils)
	_update_dino_count()
	_update_biome_text()
	_update_year(GameManager.current_year)
	GameManager.connect("year_advanced", _update_year)
	
	# Connect Settings Button
	var btn_settings = find_child("BtnSettings", true, false)
	if btn_settings:
		btn_settings.pressed.connect(_on_settings_pressed)
	
	# Connect section containers for click-anywhere behavior
	var dna_section = find_child("DNASection", true, false)
	if dna_section:
		dna_section.gui_input.connect(_on_dna_section_input)
	
	var fossil_section = find_child("FossilSection", true, false)
	if fossil_section:
		fossil_section.gui_input.connect(_on_fossil_section_input)

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

func _on_dino_count_changed(_ignored = null):
	_update_dino_count()
	
func _update_dino_count():
	var count = get_tree().get_nodes_in_group("dinos").size()
	# Optional: Include pending buffer? For UI, let's keep it simple or match strict logic
	# matching can_spawn_dino logic:
	var total = count + GameManager.pending_dino_load_data.size()
	active_dino_label.text = "Active: %d/%d" % [total, GameManager.MAX_DINO_COUNT]
	
	if total >= GameManager.MAX_DINO_COUNT:
		active_dino_label.add_theme_color_override("font_color", Color.RED)
	else:
		active_dino_label.add_theme_color_override("font_color", Color.WHITE)

func _on_habitat_changed(_v, _c):
	_update_biome_text()
	
func _update_biome_text():
	var phase = GameManager.get_current_biome_phase()
	var b_name = "Desert"
	var color = Color(1.0, 0.8, 0.6) # Desert Orange
	
	if phase == 2:
		b_name = "Oasis"
		color = Color(0.4, 0.8, 1.0) # Oasis Blue
	elif phase == 3:
		b_name = "Forest"
		color = Color(0.4, 1.0, 0.4) # Forest Green
		
	biome_label.text = "Biome: " + b_name
	biome_label.add_theme_color_override("font_color", color)

# Helper function to center a popup on the viewport
func _center_popup_on_viewport(popup: Control):
	var viewport_size = get_viewport_rect().size
	var popup_size = popup.size
	
	# Calculate center position
	var center_x = (viewport_size.x - popup_size.x) / 2.0
	var center_y = (viewport_size.y - popup_size.y) / 2.0
	
	# Set position (global position for proper centering)
	popup.global_position = Vector2(center_x, center_y)

# DNA button press and hold
func _on_dna_button_down():
	if dna_info_popup.has_method("show_dna_info"):
		dna_info_popup.show_dna_info()
	else:
		dna_info_popup.show()
	
	# Center on viewport
	_center_popup_on_viewport(dna_info_popup)
	dna_info_popup.move_to_front()

func _on_dna_button_up():
	dna_info_popup.hide()

func _on_fossil_button_down():
	fossil_info_popup.show()
	
	# Center on viewport
	_center_popup_on_viewport(fossil_info_popup)
	fossil_info_popup.move_to_front()

func _on_fossil_button_up():
	fossil_info_popup.hide()

# Section-wide input handlers (click anywhere in section)
func _on_dna_section_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_dna_button_down()
			else:
				_on_dna_button_up()

func _on_fossil_section_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_fossil_button_down()
			else:
				_on_fossil_button_up()
