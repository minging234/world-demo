class_name ChatManager
extends RefCounted

## Manages chat context, history, and system prompt building for NPC conversations.

const MAX_HISTORY := 20

# Per-NPC chat histories: npc_id -> Array of {"role": ..., "content": ...}
var _histories: Dictionary = {}


func get_history(npc_id: String) -> Array:
	if not _histories.has(npc_id):
		_histories[npc_id] = []
	return _histories[npc_id]


func build_system_prompt(npc: NPCData) -> String:
	var prompt := """You are %s, a %s cultivator with %s affinity.
Age: %d. Gender: %s.
Personality: %s.
Backstory: %s
Speaking style: %s

Current favorability toward the player: %d/100 (%s).

Guidelines:
- Respond fully in character
- Keep responses under 3 sentences
- Reference your cultivation, element, or backstory naturally when relevant
- Your attitude should reflect your current favorability level""" % [
		npc.npc_name,
		npc.realm,
		npc.element,
		npc.age,
		npc.gender,
		", ".join(npc.personality),
		npc.backstory,
		npc.speaking_style,
		npc.favorability_to_player,
		npc.get_favorability_label()
	]

	return prompt


func send_message(npc: NPCData, player_message: String, callback: Callable) -> void:
	var history := get_history(npc.id)

	# Add player message to history
	history.append({"role": "user", "content": player_message})

	# Trim to sliding window
	while history.size() > MAX_HISTORY:
		history.pop_front()

	var system_prompt := build_system_prompt(npc)

	LLMManager.chat(system_prompt, history, func(success: bool, response: String) -> void:
		if success:
			history.append({"role": "assistant", "content": response})
			# Trim again after adding response
			while history.size() > MAX_HISTORY:
				history.pop_front()

		callback.call(success, response)
	)


func clear_history(npc_id: String) -> void:
	_histories.erase(npc_id)
