class_name NPCData
extends Resource

@export var id: String = ""
@export var npc_name: String = ""
@export var age: int = 20
@export var gender: String = ""
@export var realm: String = ""
@export var element: String = ""
@export var personality: Array[String] = []
@export var backstory_tags: Array[String] = []
@export var backstory: String = ""
@export var speaking_style: String = ""
@export var portrait_prompt: String = ""
@export var portrait_path: String = ""

# Runtime state
var favorability_to_player: int = 50
var relationships: Dictionary = {} # npc_id -> Relationship


func get_favorability_label() -> String:
	if favorability_to_player <= 20:
		return "Hostile"
	elif favorability_to_player <= 40:
		return "Cold"
	elif favorability_to_player <= 60:
		return "Neutral"
	elif favorability_to_player <= 80:
		return "Friendly"
	else:
		return "Devoted"


func get_element_emoji() -> String:
	match element:
		"Fire": return "🔥"
		"Water": return "💧"
		"Wood": return "🌿"
		"Metal": return "⚔️"
		"Earth": return "🪨"
		_: return ""


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": npc_name,
		"age": age,
		"gender": gender,
		"realm": realm,
		"element": element,
		"personality": personality,
		"backstory_tags": backstory_tags,
		"backstory": backstory,
		"speaking_style": speaking_style,
		"portrait_prompt": portrait_prompt,
		"portrait_path": portrait_path,
		"favorability_to_player": favorability_to_player
	}


static func from_dict(data: Dictionary) -> NPCData:
	var npc := NPCData.new()
	npc.id = data.get("id", "")
	npc.npc_name = data.get("name", "")
	npc.age = data.get("age", 20)
	npc.gender = data.get("gender", "")
	npc.realm = data.get("realm", "")
	npc.element = data.get("element", "")
	if data.has("personality"):
		for p in data["personality"]:
			npc.personality.append(p)
	if data.has("backstory_tags"):
		for t in data["backstory_tags"]:
			npc.backstory_tags.append(t)
	npc.backstory = data.get("backstory", "")
	npc.speaking_style = data.get("speaking_style", "")
	npc.portrait_prompt = data.get("portrait_prompt", "")
	npc.portrait_path = data.get("portrait_path", "")
	npc.favorability_to_player = data.get("favorability_to_player", 50)
	return npc
