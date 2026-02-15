class_name ChatEffects
extends RefCounted

## Post-chat favorability adjustment using simple keyword matching.

const POSITIVE_KEYWORDS := [
	"thank", "friend", "help", "kind", "respect", "admire",
	"agree", "wonderful", "great", "excellent", "happy",
	"pleased", "honored", "grateful"
]

const NEGATIVE_KEYWORDS := [
	"hate", "annoying", "fool", "stupid", "leave",
	"enemy", "disgust", "weak", "pathetic", "boring",
	"disrespect", "insult"
]


## Analyze NPC response and adjust favorability
static func process_response(npc: NPCData, response: String) -> int:
	var lower := response.to_lower()
	var positive_count := 0
	var negative_count := 0

	for keyword in POSITIVE_KEYWORDS:
		if lower.contains(keyword):
			positive_count += 1

	for keyword in NEGATIVE_KEYWORDS:
		if lower.contains(keyword):
			negative_count += 1

	var change := 0
	if positive_count > negative_count:
		change = mini(positive_count - negative_count, 3)
	elif negative_count > positive_count:
		change = -mini(negative_count - positive_count, 3)

	if change != 0:
		npc.favorability_to_player = clampi(npc.favorability_to_player + change, 0, 100)

	return change
