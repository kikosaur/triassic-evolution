extends Node
## AuthManager - Handles Supabase authentication and cloud save/load.
## Autoload singleton accessible globally.

# --- CONFIGURATION (Loaded from secrets.cfg) ---
var _project_url: String = ""
var _api_key: String = ""
var _config_loaded: bool = false

# --- SIGNALS ---
signal auth_result(success: bool, message: String)
signal user_logged_in(user_data: Dictionary)
signal save_data_loaded(success: bool)

# --- STATE ---
var _http_request: HTTPRequest
var _current_action: String = "" # "login" or "signup"
var user_token: String = ""
var user_id: String = ""

# --- LOGGING (Set to false for production) ---
const DEBUG_MODE: bool = false
const SESSION_FILE: String = "user://session.data"

func _ready() -> void:
	# Load secrets from config file
	_load_secrets()
	
	# Create a node to handle web requests
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	
	# Try to restore session
	load_session()

func _load_secrets() -> void:
	var config = ConfigFile.new()
	
	# DEBUG: List files to see if secrets.cfg exists
	if DEBUG_MODE:
		pass
		# var dir = DirAccess.open("res://")
		# if dir:
		# 	dir.list_dir_begin()
		# 	var file_name = dir.get_next()
		# 	print("--- ROOT DIRECTORY ---")
		# 	while file_name != "":
		# 		print(file_name)
		# 		file_name = dir.get_next()
		# 	print("--- END ROOT ---")
	var err = config.load("res://secrets.cfg")
	
	if err != OK:
		push_error("AuthManager: Failed to load secrets.cfg! Authentication will not work.")
		return
	
	_project_url = config.get_value("supabase", "url", "")
	_api_key = config.get_value("supabase", "key", "")
	
	if _project_url == "" or _api_key == "":
		push_warning("AuthManager: Secrets loaded but keys are empty! Using fallback.")
		# Fallback for debugging if file load fails (Hardcoded safety net)
		_project_url = "https://hkwjzpfbptwayhgcbtfy.supabase.co"
		_api_key = "sb_publishable_0OTkh0rsAowSoXvfj_RDnw_ry05QmZ9"
	else:
		if DEBUG_MODE:
			print("AuthManager: Secrets loaded successfully.")
			
	_config_loaded = true

	_config_loaded = true

# --- SESSION MANAGEMENT ---

func save_session(id: String, token: String) -> void:
	var file = FileAccess.open(SESSION_FILE, FileAccess.WRITE)
	if file:
		var data = {
			"user_id": id,
			"user_token": token
		}
		file.store_string(JSON.stringify(data))
		if DEBUG_MODE:
			print("AuthManager: Session saved.")

func load_session() -> void:
	if not FileAccess.file_exists(SESSION_FILE):
		return
		
	var file = FileAccess.open(SESSION_FILE, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.parse_string(content)
		if json:
			user_id = json.get("user_id", "")
			user_token = json.get("user_token", "")
			if DEBUG_MODE:
				print("AuthManager: Session restored for ", user_id)

func delete_session() -> void:
	if FileAccess.file_exists(SESSION_FILE):
		DirAccess.remove_absolute(SESSION_FILE)
		if DEBUG_MODE:
			print("AuthManager: Session deleted.")

# --- PUBLIC FUNCTIONS ---

func sign_up(email: String, password: String, full_name: String, dob: String, username: String) -> void:
	if not _config_loaded:
		emit_signal("auth_result", false, "Configuration not loaded!")
		return
	
	_current_action = "signup"
	var url = _project_url + "/auth/v1/signup"
	
	# Supabase expects 'data' inside 'options' for user metadata
	var body_data = {
		"email": email,
		"password": password,
		"data": {
			"full_name": full_name,
			"dob": dob,
			"username": username
		}
	}
	var body = JSON.stringify(body_data)
	_send_request(url, body)

func login(email: String, password: String) -> void:
	if not _config_loaded:
		emit_signal("auth_result", false, "Configuration not loaded!")
		return
	
	_current_action = "login"
	var url = _project_url + "/auth/v1/token?grant_type=password"
	var body = JSON.stringify({"email": email, "password": password})
	_send_request(url, body)

func logout() -> void:
	delete_session() # Clear save
	user_token = ""
	user_id = ""
	GameManager.reset_game_state() # Reset persistent data
	if DEBUG_MODE:
		print("AuthManager: User logged out.")

# --- INTERNAL LOGIC ---

func _send_request(url: String, body: String) -> void:
	var headers = [
		"Content-Type: application/json",
		"apikey: " + _api_key
	]
	_http_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_string = body.get_string_from_utf8()
	
	# Debug logging (only in debug mode, never log sensitive data)
	if DEBUG_MODE:
		print("AuthManager: Response code ", response_code)
	
	var json = JSON.new()
	var parse_result = json.parse(body_string)
	
	if parse_result != OK:
		emit_signal("auth_result", false, "Error parsing server response.")
		return
		
	var response = json.get_data()
	
	# CHECK FOR ERRORS
	if response_code >= 400:
		var error_msg = "Unknown Error"
		if "error_description" in response:
			error_msg = response.error_description
		elif "msg" in response:
			error_msg = response.msg
		emit_signal("auth_result", false, error_msg)
		return
	
	# SUCCESS HANDLER
	if _current_action == "signup":
		emit_signal("auth_result", true, "Account Created! Please Log In.")
		
	elif _current_action == "login":
		user_token = response["access_token"]
		user_id = response["user"]["id"]
		save_session(user_id, user_token) # Persist login
		emit_signal("auth_result", true, "Login Successful!")
		emit_signal("user_logged_in", response["user"])
		
		# Auto-load is now handled by LoadingScreen!
		# load_game_from_cloud()

# --- DATABASE FUNCTIONS ---

func save_game_to_cloud(save_data: Dictionary) -> void:
	if user_id == "" or user_token == "":
		if DEBUG_MODE:
			print("AuthManager: Not logged in, cannot save.")
		return
		
	# Supabase "Upsert" (Insert or Update)
	var url = _project_url + "/rest/v1/player_saves"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + _api_key,
		"Authorization: Bearer " + user_token,
		"Prefer: resolution=merge-duplicates"
	]
	
	var body = JSON.stringify({
		"user_id": user_id,
		"save_data": save_data
	})
	
	# Use a new request node to avoid interference
	var db_request = HTTPRequest.new()
	add_child(db_request)
	
	db_request.request_completed.connect(func(_res: int, code: int, _head: PackedStringArray, _response_body: PackedByteArray):
		if DEBUG_MODE:
			print("AuthManager: Save completed with code ", code)
		db_request.queue_free()
	)
	
	db_request.request(url, headers, HTTPClient.METHOD_POST, body)

func load_game_from_cloud() -> void:
	if user_id == "" or user_token == "":
		return
	
	var url = _project_url + "/rest/v1/player_saves?user_id=eq." + user_id + "&select=save_data"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + _api_key,
		"Authorization: Bearer " + user_token
	]
	
	var db_request = HTTPRequest.new()
	add_child(db_request)
	db_request.request_completed.connect(_on_load_completed)
	
	db_request.request(url, headers, HTTPClient.METHOD_GET)

func _on_load_completed(_res: int, code: int, _head: PackedStringArray, body: PackedByteArray) -> void:
	# 1. Check for Token Expiry (401)
	if code == 401 or code == 403:
		if DEBUG_MODE:
			print("AuthManager: Session expired or invalid. Logging out.")
		delete_session() # Clear the bad token
		user_id = ""
		user_token = ""
		emit_signal("save_data_loaded", false) # Signal FAILURE
		return

	if code != 200:
		if DEBUG_MODE:
			print("AuthManager: Error loading save, code ", code)
		# Fallback: Proceed as if new user (or offline)
		emit_signal("save_data_loaded", true)
		return
		
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json and json.size() > 0:
		var data = json[0]["save_data"]
		if DEBUG_MODE:
			print("AuthManager: Save found, loading...")
		GameManager.load_save_dictionary(data)
		emit_signal("save_data_loaded", true)
	else:
		if DEBUG_MODE:
			print("AuthManager: No save file found for this user.")
		
		# Ensure we start fresh (clear any old data in memory)
		GameManager.reset_game_state()
		
		# SUCCESS: New user loaded (empty state)
		emit_signal("save_data_loaded", true)
		
# --- LOCAL SAVE (BACKUP / EXTERNAL) ---

const LOCAL_SAVE_FILE: String = "user://offline_save.json"

func save_game_local(save_data: Dictionary) -> void:
	var file = FileAccess.open(LOCAL_SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		if DEBUG_MODE:
			print("AuthManager: Local backup saved.")

func load_game_local() -> bool:
	if not FileAccess.file_exists(LOCAL_SAVE_FILE):
		return false
		
	var file = FileAccess.open(LOCAL_SAVE_FILE, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.parse_string(content)
		if json:
			if DEBUG_MODE:
				print("AuthManager: Local save found, loading...")
			GameManager.load_save_dictionary(json)
			return true
	return false
