class_name ActionButtons
extends HBoxContainer

## Action button row: Chat, Gift, Spar, Ask About

signal chat_pressed
signal gift_given(message: String, favorability_change: int)
signal spar_result(message: String, favorability_change: int)
signal ask_about_pressed

var npc: NPCData


func setup(npc_data: NPCData) -> void:
	npc = npc_data
	_build()


func _build() -> void:
	add_theme_constant_override("separation", 8)

	var chat_btn := _make_button("Chat", Color(0.2, 0.4, 0.7))
	chat_btn.pressed.connect(func() -> void: chat_pressed.emit())
	add_child(chat_btn)

	var gift_btn := _make_button("Gift", Color(0.6, 0.3, 0.6))
	gift_btn.pressed.connect(_on_gift)
	add_child(gift_btn)

	var spar_btn := _make_button("Spar", Color(0.7, 0.3, 0.2))
	spar_btn.pressed.connect(_on_spar)
	add_child(spar_btn)

	var ask_btn := _make_button("Ask About", Color(0.3, 0.5, 0.4))
	ask_btn.pressed.connect(func() -> void: ask_about_pressed.emit())
	add_child(ask_btn)


func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(90, 35)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := style.duplicate()
	pressed.bg_color = color.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed)

	return btn


func _on_gift() -> void:
	var change := randi_range(5, 10)
	npc.favorability_to_player = clampi(npc.favorability_to_player + change, 0, 100)

	var gifts := ["a spirit stone", "a healing pill", "a cultivation manual", "some rare herbs", "a jade pendant"]
	var gift_name: String = gifts[randi() % gifts.size()]

	var msg := "You gave %s %s. (+%d favorability)" % [npc.npc_name, gift_name, change]
	gift_given.emit(msg, change)


func _on_spar() -> void:
	var player_roll := randi_range(1, 20)
	var npc_roll := randi_range(1, 20)
	var change: int
	var msg: String

	if player_roll > npc_roll:
		change = 3
		npc.favorability_to_player = clampi(npc.favorability_to_player + change, 0, 100)
		msg = "You sparred with %s and won! (Roll: %d vs %d, +%d favorability)" % [npc.npc_name, player_roll, npc_roll, change]
	elif player_roll < npc_roll:
		change = -3
		npc.favorability_to_player = clampi(npc.favorability_to_player + change, 0, 100)
		msg = "You sparred with %s and lost. (Roll: %d vs %d, %d favorability)" % [npc.npc_name, player_roll, npc_roll, change]
	else:
		change = 1
		npc.favorability_to_player = clampi(npc.favorability_to_player + change, 0, 100)
		msg = "You sparred with %s — a draw! Mutual respect. (Roll: %d vs %d, +%d favorability)" % [npc.npc_name, player_roll, npc_roll, change]

	spar_result.emit(msg, change)
