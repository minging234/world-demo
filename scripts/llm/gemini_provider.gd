class_name GeminiProvider
extends LLMProvider

const CHAT_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
const IMAGE_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp-image-generation:generateContent"

var _pending_callback: Callable
var _pending_image_callback: Callable


func chat(system_prompt: String, messages: Array, callback: Callable) -> void:
	_pending_callback = callback

	var contents := []
	# Add system instruction as first user turn context
	for msg in messages:
		contents.append({
			"role": "user" if msg["role"] == "user" else "model",
			"parts": [{"text": msg["content"]}]
		})

	var body := {
		"system_instruction": {"parts": [{"text": system_prompt}]},
		"contents": contents,
		"generationConfig": {"maxOutputTokens": 300}
	}

	var url := CHAT_API_URL + "?key=" + api_key
	var headers := PackedStringArray(["Content-Type: application/json"])

	var err := _make_request(url, headers, JSON.stringify(body), _on_chat_response)
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
	if data.has("candidates") and data["candidates"].size() > 0:
		var parts: Array = data["candidates"][0]["content"]["parts"]
		var text := ""
		for part in parts:
			if part.has("text"):
				text += part["text"]
		_pending_callback.call(true, text)
	else:
		_pending_callback.call(false, "No candidates in response")


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

		var json_text := _extract_json(text)
		var json := JSON.new()
		var err := json.parse(json_text)
		if err != OK:
			callback.call(false, {})
			return

		callback.call(true, json.data as Dictionary)
	)


func generate_image(prompt: String, callback: Callable) -> void:
	_pending_image_callback = callback

	var body := {
		"contents": [{
			"parts": [{"text": prompt}]
		}],
		"generationConfig": {
			"responseModalities": ["TEXT", "IMAGE"]
		}
	}

	var url := IMAGE_API_URL + "?key=" + api_key
	var headers := PackedStringArray(["Content-Type: application/json"])

	var err := _make_request(url, headers, JSON.stringify(body), _on_image_response)
	if err != OK:
		callback.call(false, PackedByteArray())


func _on_image_response(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		var err_text := body.get_string_from_utf8()
		push_error("Gemini image API error %d: %s" % [response_code, err_text])
		_pending_image_callback.call(false, PackedByteArray())
		return

	var json := JSON.new()
	var parse_err := json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		_pending_image_callback.call(false, PackedByteArray())
		return

	var data: Dictionary = json.data
	if data.has("candidates") and data["candidates"].size() > 0:
		var parts: Array = data["candidates"][0]["content"]["parts"]
		for part in parts:
			if part.has("inlineData"):
				var b64_data: String = part["inlineData"]["data"]
				var image_bytes := Marshalls.base64_to_raw(b64_data)
				_pending_image_callback.call(true, image_bytes)
				return

	_pending_image_callback.call(false, PackedByteArray())


func _extract_json(text: String) -> String:
	var start := text.find("{")
	var end := text.rfind("}")
	if start >= 0 and end > start:
		return text.substr(start, end - start + 1)
	return text
