class_name ClaudeProvider
extends LLMProvider

const API_URL = "https://api.anthropic.com/v1/messages"
const MODEL = "claude-sonnet-4-5-20250929"

var _pending_callback: Callable


func chat(system_prompt: String, messages: Array, callback: Callable) -> void:
	_pending_callback = callback

	var body := {
		"model": MODEL,
		"max_tokens": 300,
		"system": system_prompt,
		"messages": messages
	}

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"x-api-key: " + api_key,
		"anthropic-version: 2023-06-01"
	])

	var err := _make_request(API_URL, headers, JSON.stringify(body), _on_chat_response)
	if err != OK:
		callback.call(false, "HTTP request failed: " + str(err))


func _on_chat_response(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		var err_text := body.get_string_from_utf8()
		_pending_callback.call(false, "API error %d: %s" % [response_code, err_text])
		return

	var json := JSON.new()
	var parse_err := json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		_pending_callback.call(false, "JSON parse error")
		return

	var data: Dictionary = json.data
	if data.has("content") and data["content"].size() > 0:
		var text: String = data["content"][0].get("text", "")
		_pending_callback.call(true, text)
	else:
		_pending_callback.call(false, "No content in response")


func generate_profile(attributes: Dictionary, callback: Callable) -> void:
	var system_prompt := "You are a xianxia world-building assistant. Generate a character profile in JSON format."

	var user_msg := """Generate a xianxia character profile given these attributes:
- Gender: %s
- Age: %d
- Cultivation Realm: %s
- Elemental Affinity: %s
- Personality Traits: %s
- Backstory Tags: %s

Return ONLY a JSON object with these fields:
{
  "name": "Chinese xianxia-style name (2-3 characters)",
  "backstory": "2-3 sentence backstory",
  "speaking_style": "Brief description of how they speak",
  "portrait_prompt": "anime portrait prompt for image generation"
}""" % [
		attributes.get("gender", ""),
		attributes.get("age", 20),
		attributes.get("realm", ""),
		attributes.get("element", ""),
		", ".join(attributes.get("personality", [])),
		", ".join(attributes.get("backstory_tags", []))
	]

	var messages := [{"role": "user", "content": user_msg}]
	chat(system_prompt, messages, func(success: bool, text: String) -> void:
		if not success:
			callback.call(false, {})
			return

		# Extract JSON from response
		var json_text := _extract_json(text)
		var json := JSON.new()
		var err := json.parse(json_text)
		if err != OK:
			callback.call(false, {})
			return

		callback.call(true, json.data as Dictionary)
	)


func _extract_json(text: String) -> String:
	# Try to find JSON block in the response
	var start := text.find("{")
	var end := text.rfind("}")
	if start >= 0 and end > start:
		return text.substr(start, end - start + 1)
	return text
