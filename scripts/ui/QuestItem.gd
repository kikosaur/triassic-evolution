extends Panel

@onready var title_lbl = $HBoxContainer/VBoxContainer/TitleLbl
@onready var desc_lbl = $HBoxContainer/VBoxContainer/DescLbl
@onready var prog_lbl = $HBoxContainer/VBoxContainer/ProgressLbl
@onready var claim_btn = $HBoxContainer/ClaimBtn

var my_index = -1

func setup(q_state, index):
	my_index = index
	var data = q_state.data
	
	title_lbl.text = data.title
	desc_lbl.text = data.description
	prog_lbl.text = str(q_state.current) + " / " + str(data.target_amount)
	
	# --- 1. FORCE CONNECTION (The Fix) ---
	# This ensures the button actually calls the function below
	if not claim_btn.pressed.is_connected(_on_claim_clicked):
		claim_btn.pressed.connect(_on_claim_clicked)
	
	# --- 2. UPDATE BUTTON STATE ---
	if q_state.claimed:
		claim_btn.text = "DONE"
		claim_btn.disabled = true
		modulate = Color(0.7, 0.7, 0.7, 0.5) # Dim it out
	elif q_state.completed:
		claim_btn.text = "CLAIM"
		claim_btn.disabled = false
		modulate = Color(1, 1, 1, 1) # Bright
	else:
		claim_btn.text = "LOCKED"
		claim_btn.disabled = true
		modulate = Color(1, 1, 1, 1)

# --- 3. THE FUNCTION ---
func _on_claim_clicked():
	AudioManager.play_sfx("success")
	print("Button Clicked! Asking Manager to claim index: " + str(my_index))
	QuestManager.claim_reward(my_index)
