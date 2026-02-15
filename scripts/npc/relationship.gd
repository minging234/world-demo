class_name Relationship
extends Resource

@export var npc_a_id: String = ""
@export var npc_b_id: String = ""
@export var favorability: int = 50
@export var contact_history: Array[Dictionary] = []


func add_contact(type: String, summary: String, round_num: int) -> void:
	contact_history.append({
		"type": type,
		"round": round_num,
		"summary": summary
	})


func adjust_favorability(amount: int) -> void:
	favorability = clampi(favorability + amount, 0, 100)


func get_favorability_label() -> String:
	if favorability <= 20:
		return "Hostile"
	elif favorability <= 40:
		return "Cold"
	elif favorability <= 60:
		return "Neutral"
	elif favorability <= 80:
		return "Friendly"
	else:
		return "Devoted"


func get_last_interaction_summary() -> String:
	if contact_history.is_empty():
		return "No prior interactions"
	return contact_history[-1].get("summary", "")
