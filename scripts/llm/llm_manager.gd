extends Node

## Singleton that manages LLM providers and request queuing.

var config: Dictionary = {}
var _chat_provider: LLMProvider
var _profile_provider: LLMProvider
var _image_provider: LLMProvider

var _request_queue: Array[Dictionary] = []
var _is_processing: bool = false

# HTTP request nodes (one per provider to allow concurrent different-type requests)
var _chat_http: HTTPRequest
var _profile_http: HTTPRequest
var _image_http: HTTPRequest


func _ready() -> void:
	_chat_http = HTTPRequest.new()
	_profile_http = HTTPRequest.new()
	_image_http = HTTPRequest.new()
	# Increase download buffer for image responses
	_image_http.download_chunk_size = 65536
	add_child(_chat_http)
	add_child(_profile_http)
	add_child(_image_http)

	_load_config()


func _load_config() -> void:
	var config_path := "res://config/llm_config.json"
	if not FileAccess.file_exists(config_path):
		push_warning("LLM config not found at %s. Using example config." % config_path)
		config_path = "res://config/llm_config.json.example"

	var file := FileAccess.open(config_path, FileAccess.READ)
	if not file:
		push_error("Failed to open LLM config")
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("Failed to parse LLM config JSON")
		return

	config = json.data
	_setup_providers()


func _setup_providers() -> void:
	var keys: Dictionary = config.get("api_keys", {})

	_chat_provider = _create_provider(config.get("chat_provider", "claude"), keys)
	if _chat_provider:
		_chat_provider.setup(keys.get(config.get("chat_provider", "claude"), ""), _chat_http)

	_profile_provider = _create_provider(config.get("profile_provider", "claude"), keys)
	if _profile_provider:
		_profile_provider.setup(keys.get(config.get("profile_provider", "claude"), ""), _profile_http)

	_image_provider = _create_provider(config.get("image_provider", "gemini"), keys)
	if _image_provider:
		_image_provider.setup(keys.get(config.get("image_provider", "gemini"), ""), _image_http)


func _create_provider(provider_name: String, _keys: Dictionary) -> LLMProvider:
	match provider_name:
		"claude":
			return ClaudeProvider.new()
		"openai":
			return OpenAIProvider.new()
		"gemini":
			return GeminiProvider.new()
		_:
			push_error("Unknown LLM provider: " + provider_name)
			return null


## Public API

func chat(system_prompt: String, messages: Array, callback: Callable) -> void:
	if _chat_provider:
		_chat_provider.chat(system_prompt, messages, callback)
	else:
		callback.call(false, "No chat provider configured")


func generate_profile(attributes: Dictionary, callback: Callable) -> void:
	if _profile_provider:
		_profile_provider.generate_profile(attributes, callback)
	else:
		callback.call(false, {})


func generate_image(prompt: String, callback: Callable) -> void:
	if _image_provider:
		_image_provider.generate_image(prompt, callback)
	else:
		callback.call(false, PackedByteArray())


func is_configured() -> bool:
	return _chat_provider != null
