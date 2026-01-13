extends Node2D

@onready var click_zone = $ClickZone
@onready var dino_container = $DinoContainer
@onready var btn_spawn = $UI_Layer/BtnSpawnArchosaur
@onready var background = $Background

# DRAG TEXTURES HERE IN INSPECTOR!
@export var phase_1_tex: Texture2D # Desert [cite: 19]
@export var phase_2_tex: Texture2D # Oasis [cite: 21]
@export var phase_3_tex: Texture2D # Jungle [cite: 23]

# EXISTING EXPORTS
@export var dino_scene: PackedScene 
@export var archosaur_res: Resource 

# RESEARCH
@onready var research_menu = $UI_Layer/ResearchMenu
@onready var btn_research = $UI_Layer/BtnToggleResearch

@onready var extinction_panel = $UI_Layer/ExtinctionPanel

func _ready():
	print("Main Game Started")
	click_zone.pressed.connect(_on_background_clicked)
	btn_spawn.pressed.connect(_on_buy_pressed)
	
	# Listen for Habitat Changes
	GameManager.connect("habitat_updated", _check_phase_change)
	
	btn_research.pressed.connect(func(): research_menu.visible = !research_menu.visible)
	
	GameManager.connect("extinction_triggered", _show_extinction)

func _on_background_clicked():
	GameManager.add_dna(5) # Increased to 5 to make testing faster!

func _on_buy_pressed():
	if GameManager.try_spend_dna(archosaur_res.base_dna_cost):
		spawn_dino(archosaur_res)

func spawn_dino(species):
	var new_dino = dino_scene.instantiate()
	new_dino.species_data = species
	new_dino.position = Vector2(640, 500)
	dino_container.add_child(new_dino)

func _check_phase_change(veg, _critter):
	# System A: Ecological Stages [cite: 17]
	if veg <= 30:
		background.texture = phase_1_tex # Origins
	elif veg <= 60:
		background.texture = phase_2_tex # Oasis
	else:
		background.texture = phase_3_tex # Deep Jungle

func _show_extinction():
	extinction_panel.visible = true
	# Optional: Play a sound or shake screen here
