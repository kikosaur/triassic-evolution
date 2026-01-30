extends Control

# Login UI
@onready var login_email = $LoginPanel/VBoxContainer/EmailEdit
@onready var login_pass = $LoginPanel/VBoxContainer/PasswordEdit
@onready var login_btn = $LoginPanel/VBoxContainer/LoginBtn
@onready var create_account_btn = $LoginPanel/VBoxContainer/CreateAccountBtn
@onready var message_lbl = %MessageLabel

# Signup UI
@onready var signup_popup = %SignupPopup
@onready var sign_name = %NameEdit
@onready var sign_dob = %DOBEdit
@onready var sign_user = %UsernameEdit
@onready var sign_email = %EmailEdit
@onready var sign_pass = %PasswordEdit
@onready var register_btn = $SignupPopup/VBoxContainer/RegisterBtn
@onready var cancel_btn = $SignupPopup/VBoxContainer/CancelBtn

func _ready():
	# Signals
	login_btn.pressed.connect(_on_login_pressed)
	create_account_btn.pressed.connect(_on_create_account_pressed)
	
	register_btn.pressed.connect(_on_register_pressed)
	cancel_btn.pressed.connect(_on_cancel_signup)
	
	AuthManager.auth_result.connect(_on_auth_result)
	
func _on_login_pressed():
	var email = login_email.text.strip_edges()
	var password = login_pass.text.strip_edges()
	
	if email == "" or password == "":
		_show_message("Please fill in fields.", false)
		return
		
	_show_message("Logging in...", true)
	AuthManager.login(email, password)

func _on_create_account_pressed():
	# Open Popup
	signup_popup.visible = true
	_clear_signup_inputs()

func _on_cancel_signup():
	signup_popup.visible = false

func _on_register_pressed():
	# Validation
	var full_name = sign_name.text.strip_edges()
	var dob = sign_dob.text.strip_edges()
	var username = sign_user.text.strip_edges()
	var email = sign_email.text.strip_edges()
	var password = sign_pass.text.strip_edges()
	
	if full_name == "" or dob == "" or username == "" or email == "" or password == "":
		_show_message("All fields are required.", false)
		return

	# Validate Date Format (YYYY-MM-DD)
	var date_regex = RegEx.new()
	date_regex.compile("^\\d{4}-\\d{2}-\\d{2}$")
	if not date_regex.search(dob):
		_show_message("Invalid Date! Use YYYY-MM-DD", false)
		return
		
	# Basic Email Validation
	if "@" not in email or "." not in email:
		_show_message("Invalid Email Address.", false)
		return


	# Call AuthManager
	_show_message("Creating Account...", true)
	AuthManager.sign_up(email, password, full_name, dob, username)

func _on_auth_result(success: bool, message: String):
	_show_message(message, success)
	
	if success:
		if signup_popup.visible:
			# If we were signing up, close popup and ask to login
			signup_popup.visible = false
			_show_message("Account Created! Please Log In.", true)
			# Fill email for convenience?
			login_email.text = sign_email.text
			login_pass.text = ""
		else:
			# Login Success -> Go to Loading
			get_tree().change_scene_to_file("res://scenes/ui/LoadingScreen.tscn")

func _show_message(msg: String, is_good: bool):
	message_lbl.text = msg
	if is_good:
		message_lbl.modulate = Color.GREEN
	else:
		message_lbl.modulate = Color.RED

func _clear_signup_inputs():
	sign_name.text = ""
	sign_dob.text = ""
	sign_user.text = ""
	sign_email.text = ""
	sign_pass.text = ""
