extends Node

# --- CONFIGURATION ---
# PASTE YOUR SUPABASE KEYS HERE!
const PROJECT_URL = "https://hkwjzpfbptwayhgcbtfy.supabase.co"
const API_KEY = "sb_publishable_0OTkh0rsAowSoXvfj_RDnw_ry05QmZ9"

# --- SIGNALS ---
signal auth_result(success: bool, message: String)
signal user_logged_in(user_data: Dictionary)

# --- STATE ---
var _http_request: HTTPRequest
var _current_action: String = "" # "login" or "signup"
var user_token: String = ""
var user_id: String = ""

func _ready():
	# Create a node to handle web requests
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)

# --- PUBLIC FUNCTIONS ---

func sign_up(email, password):
	_current_action = "signup"
	var url = PROJECT_URL + "/auth/v1/signup"
	var body = JSON.stringify({"email": email, "password": password})
	_send_request(url, body)

func login(email, password):
	_current_action = "login"
	var url = PROJECT_URL + "/auth/v1/token?grant_type=password"
	var body = JSON.stringify({"email": email, "password": password})
	_send_request(url, body)

# --- INTERNAL LOGIC ---

func _send_request(url, body):
	var headers = [
		"Content-Type: application/json",
		"apikey: " + API_KEY
	]
	_http_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_request_completed(_result, response_code, _headers, body):
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
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
		# Note: Depending on Supabase settings, they might need to confirm email first.
		# Usually, signup returns the user object immediately if "Enable Email Confirm" is off.
		emit_signal("auth_result", true, "Account Created! Please Log In.")
		
	elif _current_action == "login":
		user_token = response["access_token"]
		user_id = response["user"]["id"]
		emit_signal("auth_result", true, "Login Successful!")
		emit_signal("user_logged_in", response["user"])
		
		# --- AUTO LOAD ---
		print("User logged in. Fetching save file...")
		load_game_from_cloud()

# --- DATABASE FUNCTIONS ---

func save_game_to_cloud(save_data: Dictionary):
	if user_id == "" or user_token == "":
		print("Not logged in!")
		return
		
	# Supabase "Upsert" (Insert or Update)
	var url = PROJECT_URL + "/rest/v1/player_saves"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + API_KEY,
		"Authorization: Bearer " + user_token,
		"Prefer: resolution=merge-duplicates" # Tells Supabase to update if ID exists
	]
	
	var body = JSON.stringify({
		"user_id": user_id,
		"save_data": save_data
	})
	
	# We use a new request node so we don't interfere with auth requests
	var db_request = HTTPRequest.new()
	add_child(db_request)
	
	# FIX: Added underscores to unused variables and renamed the response body
	db_request.request_completed.connect(func(_res, code, _head, _response_body): 
		print("Save Completed: Code " + str(code))
		db_request.queue_free()
	)
	
	db_request.request(url, headers, HTTPClient.METHOD_POST, body)

func load_game_from_cloud():
	if user_id == "" or user_token == "": return
	
	var url = PROJECT_URL + "/rest/v1/player_saves?user_id=eq." + user_id + "&select=save_data"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + API_KEY,
		"Authorization: Bearer " + user_token
	]
	
	var db_request = HTTPRequest.new()
	add_child(db_request)
	db_request.request_completed.connect(_on_load_completed)
	
	db_request.request(url, headers, HTTPClient.METHOD_GET)

func _on_load_completed(_res, code, _head, body):
	if code != 200:
		print("Error Loading: " + str(code))
		return
		
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json and json.size() > 0:
		var data = json[0]["save_data"] # Supabase returns an array
		print("Save Found! Loading...")
		GameManager.load_save_dictionary(data)
	else:
		print("No save file found for this user.")
