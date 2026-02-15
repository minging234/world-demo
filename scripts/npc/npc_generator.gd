class_name NPCGenerator
extends RefCounted

## Generates NPCs by sampling from attribute pools and calling LLM for profiles.

var pools: Dictionary = {}
var _npc_counter: int = 0

signal npc_generated(npc: NPCData)
signal generation_complete(npcs: Array)


func _init() -> void:
	_load_pools()


func _load_pools() -> void:
	var file := FileAccess.open("res://config/npc_pools.json", FileAccess.READ)
	if not file:
		push_error("Failed to load NPC pools config")
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("Failed to parse NPC pools JSON")
		return

	pools = json.data


## Sample random attributes from pools
func sample_attributes() -> Dictionary:
	var attrs := {}

	attrs["gender"] = _pick_random(pools.get("genders", ["Male", "Female"]))
	attrs["realm"] = _pick_random(pools.get("realms", []))
	attrs["element"] = _pick_random(pools.get("elements", []))

	# Pick 2-3 personality traits
	var all_traits: Array = pools.get("personality_traits", [])
	var trait_count := randi_range(2, 3)
	var traits: Array[String] = []
	var available := all_traits.duplicate()
	for i in trait_count:
		if available.is_empty():
			break
		var idx := randi() % available.size()
		traits.append(available[idx])
		available.remove_at(idx)
	attrs["personality"] = traits

	# Pick 1-2 backstory tags
	var all_tags: Array = pools.get("backstory_tags", [])
	var tag_count := randi_range(1, 2)
	var tags: Array[String] = []
	available = all_tags.duplicate()
	for i in tag_count:
		if available.is_empty():
			break
		var idx := randi() % available.size()
		tags.append(available[idx])
		available.remove_at(idx)
	attrs["backstory_tags"] = tags

	# Age: weighted toward younger
	var age_config: Dictionary = pools.get("age_range", {"min": 16, "max": 200, "weight_young": 0.7})
	var age_min: int = age_config.get("min", 16)
	var age_max: int = age_config.get("max", 200)
	var weight_young: float = age_config.get("weight_young", 0.7)

	if randf() < weight_young:
		attrs["age"] = randi_range(age_min, 30)
	else:
		attrs["age"] = randi_range(31, age_max)

	return attrs


## Generate a single NPC with LLM profile
func generate_npc(callback: Callable) -> void:
	_npc_counter += 1
	var attrs := sample_attributes()
	var npc_id := "npc_%03d" % _npc_counter

	LLMManager.generate_profile(attrs, func(success: bool, profile: Dictionary) -> void:
		var npc := NPCData.new()
		npc.id = npc_id
		npc.age = attrs["age"]
		npc.gender = attrs["gender"]
		npc.realm = attrs["realm"]
		npc.element = attrs["element"]
		npc.personality.assign(attrs["personality"])
		npc.backstory_tags.assign(attrs["backstory_tags"])

		if success and profile.size() > 0:
			npc.npc_name = profile.get("name", _generate_fallback_name())
			npc.backstory = profile.get("backstory", "A mysterious cultivator.")
			npc.speaking_style = profile.get("speaking_style", "Speaks plainly.")
			npc.portrait_prompt = profile.get("portrait_prompt", "")
		else:
			# Fallback: generate without LLM
			npc.npc_name = _generate_fallback_name()
			npc.backstory = "A %s cultivator of the %s realm with %s affinity." % [
				npc.gender.to_lower(), npc.realm, npc.element
			]
			npc.speaking_style = "Speaks in a manner befitting a %s personality." % ", ".join(npc.personality)

		npc.portrait_path = "res://assets/portraits/%s.png" % npc_id

		# Try to generate portrait, fall back to placeholder
		_generate_portrait(npc, func() -> void:
			callback.call(npc)
		)
	)


## Generate multiple NPCs sequentially
func generate_npcs(count: int, callback: Callable) -> void:
	var npcs: Array[NPCData] = []
	_generate_next(count, npcs, callback)


func _generate_next(remaining: int, npcs: Array[NPCData], callback: Callable) -> void:
	if remaining <= 0:
		callback.call(npcs)
		return

	generate_npc(func(npc: NPCData) -> void:
		npcs.append(npc)
		print("Generated NPC: %s (%s, %s, %s)" % [npc.npc_name, npc.realm, npc.element, ", ".join(npc.personality)])
		_generate_next(remaining - 1, npcs, callback)
	)


func _generate_portrait(npc: NPCData, callback: Callable) -> void:
	if npc.portrait_prompt.is_empty():
		npc.portrait_prompt = _build_portrait_prompt(npc)

	LLMManager.generate_image(npc.portrait_prompt, func(success: bool, image_data: PackedByteArray) -> void:
		if success and image_data.size() > 0:
			_save_portrait(npc, image_data)
		else:
			_create_placeholder_portrait(npc)
		callback.call()
	)


func _build_portrait_prompt(npc: NPCData) -> String:
	var age_desc := "young" if npc.age < 25 else ("middle-aged" if npc.age < 60 else "elderly")
	var gender_desc := "female" if npc.gender == "Female" else "male"
	return "anime portrait, %s %s, %s, %s color theme, xianxia robes, detailed face, clean background" % [
		age_desc, gender_desc, npc.element, npc.element.to_lower()
	]


func _save_portrait(npc: NPCData, image_data: PackedByteArray) -> void:
	var dir := DirAccess.open("res://")
	if dir and not dir.dir_exists("assets/portraits"):
		dir.make_dir_recursive("assets/portraits")

	# Try to save as PNG
	var image := Image.new()
	var err := image.load_png_from_buffer(image_data)
	if err != OK:
		# Try JPEG
		err = image.load_jpg_from_buffer(image_data)
	if err != OK:
		push_warning("Failed to load image for %s, using placeholder" % npc.npc_name)
		_create_placeholder_portrait(npc)
		return

	var save_path := npc.portrait_path.replace("res://", "")
	var abs_path := ProjectSettings.globalize_path("res://") + save_path
	image.save_png(abs_path)


func _create_placeholder_portrait(npc: NPCData) -> void:
	# Create a simple colored rectangle with the NPC's element color
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var color := _get_element_color(npc.element)
	image.fill(color)

	# Draw initials area (darker center)
	var darker := color.darkened(0.3)
	for x in range(64, 192):
		for y in range(64, 192):
			image.set_pixel(x, y, darker)

	var dir := DirAccess.open("res://")
	if dir and not dir.dir_exists("assets/portraits"):
		dir.make_dir_recursive("assets/portraits")

	var save_path := npc.portrait_path.replace("res://", "")
	var abs_path := ProjectSettings.globalize_path("res://") + save_path
	image.save_png(abs_path)


func _get_element_color(element: String) -> Color:
	match element:
		"Fire": return Color(0.8, 0.2, 0.1)
		"Water": return Color(0.1, 0.3, 0.8)
		"Wood": return Color(0.2, 0.7, 0.3)
		"Metal": return Color(0.7, 0.7, 0.75)
		"Earth": return Color(0.6, 0.4, 0.2)
		_: return Color(0.5, 0.5, 0.5)


var _fallback_names := [
	"林清霜", "赵无极", "白玉京", "沈墨", "柳如烟",
	"陈星河", "苏若兰", "韩冰", "张天行", "杨紫萱",
	"周云深", "吴明月", "孙灵犀", "李剑心", "王暮雪"
]
var _fallback_name_idx: int = 0


func _generate_fallback_name() -> String:
	var name_val: String = _fallback_names[_fallback_name_idx % _fallback_names.size()]
	_fallback_name_idx += 1
	return name_val


func _pick_random(arr: Array) -> Variant:
	if arr.is_empty():
		return ""
	return arr[randi() % arr.size()]
