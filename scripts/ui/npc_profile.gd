class_name NPCProfilePanel
extends VBoxContainer

## Displays NPC profile info and favorability hearts.

var npc: NPCData
var favorability_label: Label
var hearts_label: Label


func setup(npc_data: NPCData) -> void:
	npc = npc_data
	_build()


func _build() -> void:
	add_theme_constant_override("separation", 8)

	# Name
	var name_label := Label.new()
	name_label.text = npc.npc_name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.6))
	add_child(name_label)

	# Realm
	_add_info_row("Realm", npc.realm)
	_add_info_row("Element", "%s %s" % [npc.element, npc.get_element_emoji()])
	_add_info_row("Age", str(npc.age))
	_add_info_row("Gender", npc.gender)
	_add_info_row("Personality", ", ".join(npc.personality))

	# Favorability with hearts
	var fav_hbox := HBoxContainer.new()
	fav_hbox.add_theme_constant_override("separation", 8)
	add_child(fav_hbox)

	var fav_title := Label.new()
	fav_title.text = "Favorability:"
	fav_title.add_theme_font_size_override("font_size", 14)
	fav_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	fav_hbox.add_child(fav_title)

	hearts_label = Label.new()
	hearts_label.add_theme_font_size_override("font_size", 14)
	fav_hbox.add_child(hearts_label)

	favorability_label = Label.new()
	favorability_label.add_theme_font_size_override("font_size", 12)
	favorability_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	fav_hbox.add_child(favorability_label)

	update_favorability()

	# Separator
	var sep := HSeparator.new()
	add_child(sep)

	# Backstory
	var backstory_title := Label.new()
	backstory_title.text = "Backstory"
	backstory_title.add_theme_font_size_override("font_size", 12)
	backstory_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	add_child(backstory_title)

	var backstory_text := Label.new()
	backstory_text.text = npc.backstory
	backstory_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	backstory_text.add_theme_font_size_override("font_size", 13)
	backstory_text.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	add_child(backstory_text)


func _add_info_row(label_text: String, value_text: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	add_child(hbox)

	var label := Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 90
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	hbox.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 14)
	value.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	hbox.add_child(value)


func update_favorability() -> void:
	if not npc:
		return

	# Hearts display: 5 hearts, filled based on favorability
	var filled := int(npc.favorability_to_player / 20.0)
	var hearts := ""
	for i in 5:
		hearts += "♥" if i < filled else "♡"

	hearts_label.text = hearts
	hearts_label.add_theme_color_override("font_color",
		Color(0.9, 0.2, 0.3) if filled >= 3 else Color(0.7, 0.5, 0.5))

	favorability_label.text = "(%d/100 — %s)" % [npc.favorability_to_player, npc.get_favorability_label()]
