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
