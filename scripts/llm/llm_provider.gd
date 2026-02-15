class_name LLMProvider
extends RefCounted

## Base class for LLM providers. Subclasses implement the actual API calls.

var api_key: String = ""
var _http_request: HTTPRequest


func setup(key: String, http_node: HTTPRequest) -> void:
	api_key = key
	_http_request = http_node


## Send a chat message. Returns the response text via callback.
## system_prompt: the system/instruction prompt
## messages: array of {"role": "user"|"assistant", "content": "..."}
## callback: Callable that receives (success: bool, response_text: String)
func chat(system_prompt: String, messages: Array, callback: Callable) -> void:
	push_error("LLMProvider.chat() not implemented")
	callback.call(false, "Not implemented")


## Generate an NPC profile from attributes. Returns JSON dict via callback.
## attributes: dict of sampled attributes
## callback: Callable that receives (success: bool, profile: Dictionary)
func generate_profile(attributes: Dictionary, callback: Callable) -> void:
	push_error("LLMProvider.generate_profile() not implemented")
	callback.call(false, {})


## Generate an image from a prompt. Returns image bytes via callback.
## prompt: text description of the image
## callback: Callable that receives (success: bool, image_data: PackedByteArray)
func generate_image(prompt: String, callback: Callable) -> void:
	push_error("LLMProvider.generate_image() not implemented")
	callback.call(false, PackedByteArray())


## Helper to make an HTTP request and connect to a response handler
func _make_request(url: String, headers: PackedStringArray, body: String, handler: Callable) -> Error:
	if not _http_request:
		push_error("HTTPRequest node not set")
		return ERR_UNCONFIGURED

	# Disconnect any existing signal connections
	if _http_request.request_completed.get_connections().size() > 0:
		for conn in _http_request.request_completed.get_connections():
			_http_request.request_completed.disconnect(conn["callable"])

	_http_request.request_completed.connect(handler, CONNECT_ONE_SHOT)
	return _http_request.request(url, headers, HTTPClient.METHOD_POST, body)
