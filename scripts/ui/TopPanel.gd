extends Panel

@onready var dna_label = $DNALabel
@onready var fossil_label = $FossilLabel # NEW
@onready var ui = TextureRect

func _ready():
	GameManager.connect("dna_changed", _update_dna)
	GameManager.connect("fossils_changed", _update_fossils) # NEW
	
	_update_dna(GameManager.current_dna)
	_update_fossils(GameManager.fossils)

func _update_dna(amount):
	dna_label.text = GameManager.format_number(amount)

func _update_fossils(amount):
	fossil_label.text = GameManager.format_number(amount)
