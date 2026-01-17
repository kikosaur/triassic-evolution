extends Panel

@onready var email_input = $VBoxContainer/EmailInput
@onready var pass_input = $VBoxContainer/PassInput
@onready var status_label = $VBoxContainer/StatusLabel
@onready var btn_login = $VBoxContainer/HBoxContainer/BtnLogin
@onready var btn_signup = $VBoxContainer/HBoxContainer/BtnSignup

func _ready():
	# Connect Buttons
	btn_login.pressed.connect(_on_login_pressed)
	btn_signup.pressed.connect(_on_signup_pressed)
	
	# Listen to AuthManager
	AuthManager.auth_result.connect(_on_auth_result)
	AuthManager.connect("user_logged_in", _on_user_logged_in)

func _on_login_pressed():
	if email_input.text == "" or pass_input.text == "":
		status_label.text = "Please fill in all fields."
		return
		
	status_label.text = "Logging in..."
	status_label.modulate = Color.YELLOW
	AuthManager.login(email_input.text, pass_input.text)

func _on_signup_pressed():
	if email_input.text == "" or pass_input.text == "":
		status_label.text = "Please fill in all fields."
		return
		
	status_label.text = "Creating Account..."
	status_label.modulate = Color.YELLOW
	AuthManager.sign_up(email_input.text, pass_input.text)

func _on_auth_result(success, message):
	status_label.text = message
	if success:
		status_label.modulate = Color.GREEN
		if "Login Successful" in message:
			await get_tree().create_timer(1.0).timeout
			visible = false # Hide panel on success
	else:
		status_label.modulate = Color.RED

func _on_btn_save_pressed():
	var data = GameManager.get_save_dictionary()
	AuthManager.save_game_to_cloud(data)

func _on_btn_load_pressed():
	AuthManager.load_game_from_cloud()

func _on_user_logged_in(_user_data):
	# Hide the panel after a short delay so they see "Login Successful"
	await get_tree().create_timer(1.5).timeout
	visible = false
