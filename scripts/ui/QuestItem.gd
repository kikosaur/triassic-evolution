extends Panel

@onready var title_lbl = $HBoxContainer/VBoxContainer/TitleLbl
@onready var desc_lbl = $HBoxContainer/VBoxContainer/DescLbl  # <-- ADD THIS
@onready var progress_lbl = $HBoxContainer/VBoxContainer/ProgressLbl
@onready var btn_claim = $HBoxContainer/BtnClaim
@onready var icon_check = $HBoxContainer/IconCheck

var quest_index: int = -1

func setup(q_state, index):
	quest_index = index
	var data = q_state.data # Access the Resource inside the dictionary
	
	title_lbl.text = data.title
	desc_lbl.text = data.description
	progress_lbl.text = str(q_state.current) + " / " + str(data.target_amount)
	
	if q_state.claimed:
		btn_claim.visible = false
		icon_check.visible = true
		modulate = Color(0.5, 0.5, 0.5)
	elif q_state.completed:
		btn_claim.visible = true
		btn_claim.text = "Claim " + str(data.reward_dna)
		icon_check.visible = false
		modulate = Color(1, 1, 1)
	else:
		btn_claim.visible = false
		icon_check.visible = false
		modulate = Color(1, 1, 1)

func _on_btn_claim_pressed():
	QuestManager.claim_reward(quest_index)
