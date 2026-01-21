extends Panel

# Reference the popup we just added as a child
@onready var info_panel = $InfoPanel

# Make sure these paths match your Scene Tree exactly!
@onready var how_to_play_btn = $VBoxContainer/HowToPlayBtn
@onready var terms_btn = $VBoxContainer/TermsBtn

# --- DEFINE YOUR TEXT HERE ---
# We use BBCode ([b], [color]) to make the text look nice.
const HOW_TO_PLAY_TEXT = """
[b]1. Build Your Park[/b]
Buy dinosaurs from the Market to start generating DNA.

[b]2. Evolve[/b]
Use DNA to [color=yellow]Research[/color] new evolutionary traits. Unlocking nodes like 'Upright Stance' allows you to buy better dinosaurs.

[b]3. Complete Tasks[/b]
Check the Quest Menu for tasks. Completing them gives huge DNA bonuses!

[b]4. Manage Habitats[/b]
Buy habitat decorations to boost the efficiency of your dinosaurs.
"""

const TERMS_TEXT = """
[b]Triassic Evolution Terms[/b]

1. This game is a personal project created for educational purposes.
2. No personal data is collected or stored on external servers.
3. Dinosaur logic is simulated and does not represent real biological timeframes.
4. By playing, you agree to have fun and evolve responsibly!

[i]Version 1.0.0[/i]
"""

func _ready():
	# Connect buttons
	how_to_play_btn.pressed.connect(_on_how_to_play_clicked)
	terms_btn.pressed.connect(_on_terms_clicked)
	
	# If you have a Close button for the Settings Panel itself, connect it here too:
	# $CloseButton.pressed.connect(func(): hide())

func _on_how_to_play_clicked():
	# Re-use the same popup, just change the text!
	info_panel.setup_popup("How to Play", HOW_TO_PLAY_TEXT)

func _on_terms_clicked():
	info_panel.setup_popup("Terms & Conditions", TERMS_TEXT)
