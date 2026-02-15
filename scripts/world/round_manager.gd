class_name RoundManager
extends RefCounted

## Manages round-based NPC-NPC interactions using weighted random tables and templates.

# Interaction types with weights and favorability changes
const INTERACTIONS := [
	{"type": "friendly_chat", "weight": 30, "fav_change": 2,
		"templates": [
			"{a} and {b} had a friendly chat about sword forms",
			"{a} discussed cultivation techniques with {b}",
			"{a} and {b} shared stories about their adventures"
		]},
	{"type": "train_together", "weight": 20, "fav_change": 3,
		"templates": [
			"{a} trained together with {b} in the practice grounds",
			"{a} and {b} sparred and exchanged pointers",
			"{a} helped {b} practice their {element_b} techniques"
		]},
	{"type": "argue", "weight": 15, "fav_change": -3,
		"templates": [
			"{a} argued with {b} over training methods",
			"{a} and {b} had a heated disagreement about sect rules",
			"{a} criticized {b}'s cultivation approach"
		]},
	{"type": "ignore", "weight": 20, "fav_change": -1,
		"templates": [
			"{a} and {b} crossed paths but ignored each other",
			"{a} walked past {b} without a word",
			"{a} avoided {b} during the morning assembly"
		]},
	{"type": "share_meal", "weight": 10, "fav_change": 4,
		"templates": [
			"{a} shared a meal with {b} at the dining hall",
			"{a} and {b} enjoyed tea together in the garden",
			"{a} invited {b} to share some spirit fruits"
		]},
	{"type": "compete", "weight": 5, "fav_change": -2,
		"templates": [
			"{a} competed with {b} in a cultivation contest",
			"{a} and {b} clashed over a rare resource",
			"{a} challenged {b} to prove their superiority"
		]}
]

var _total_weight: int = 0


func _init() -> void:
	for interaction in INTERACTIONS:
		_total_weight += interaction["weight"]


## Run a round: pick NPC pairs, roll interactions, return results
func run_round(npcs: Array[NPCData], round_num: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	if npcs.size() < 2:
		return results

	# Pick 2-3 random pairs
	var pair_count := randi_range(2, mini(3, npcs.size() / 2))
	var used_npcs: Array[String] = []

	for i in pair_count:
		var pair := _pick_pair(npcs, used_npcs)
		if pair.is_empty():
			break

		var npc_a: NPCData = pair[0]
		var npc_b: NPCData = pair[1]
		used_npcs.append(npc_a.id)
		used_npcs.append(npc_b.id)

		# Roll interaction type
		var interaction := _roll_interaction()
		var fav_change: int = interaction["fav_change"]

		# Get or create relationship and apply change
		var rel := _get_or_create_relationship(npc_a, npc_b)
		rel.adjust_favorability(fav_change)
		rel.add_contact(interaction["type"], "", round_num)

		# Generate summary from template
		var templates: Array = interaction["templates"]
		var template: String = templates[randi() % templates.size()]
		var summary := template.replace("{a}", npc_a.npc_name).replace("{b}", npc_b.npc_name)
		summary = summary.replace("{element_a}", npc_a.element).replace("{element_b}", npc_b.element)

		var sign := "+" if fav_change > 0 else ""
		summary += " (%s%d)" % [sign, fav_change]

		results.append({
			"npc_a": npc_a,
			"npc_b": npc_b,
			"type": interaction["type"],
			"fav_change": fav_change,
			"summary": summary
		})

	return results


func _pick_pair(npcs: Array[NPCData], used: Array[String]) -> Array:
	var available: Array[NPCData] = []
	for npc in npcs:
		if npc.id not in used:
			available.append(npc)

	if available.size() < 2:
		return []

	var idx_a := randi() % available.size()
	var npc_a := available[idx_a]
	available.remove_at(idx_a)

	var idx_b := randi() % available.size()
	var npc_b := available[idx_b]

	return [npc_a, npc_b]


func _roll_interaction() -> Dictionary:
	var roll := randi() % _total_weight
	var cumulative := 0

	for interaction in INTERACTIONS:
		cumulative += interaction["weight"]
		if roll < cumulative:
			return interaction

	return INTERACTIONS[0]


func _get_or_create_relationship(npc_a: NPCData, npc_b: NPCData) -> Relationship:
	var key := npc_b.id
	if npc_a.relationships.has(key):
		return npc_a.relationships[key]

	var rel := Relationship.new()
	rel.npc_a_id = npc_a.id
	rel.npc_b_id = npc_b.id
	npc_a.relationships[key] = rel
	npc_b.relationships[npc_a.id] = rel
	return rel
