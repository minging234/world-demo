class_name ChatPanel
extends VBoxContainer

## Chat UI: scrollable message history + text input + send button.

var npc: NPCData
var chat_manager: ChatManager

var scroll_container: ScrollContainer
var messages_container: VBoxContainer
var input_field: LineEdit
var send_button: Button
var _is_waiting: bool = false

signal favorability_changed


func setup(npc_data: NPCData, manager: ChatManager) -> void:
	npc = npc_data
	chat_manager = manager
	_build()
	_load_existing_history()


func _build() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 5)

	# Chat title
	var title := Label.new()
	title.text = "Chat with %s" % npc.npc_name
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	add_child(title)

	# Scrollable message area
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var scroll_style := StyleBoxFlat.new()
	scroll_style.bg_color = Color(0.08, 0.07, 0.12)
	scroll_style.set_corner_radius_all(4)
	scroll_style.content_margin_left = 8
	scroll_style.content_margin_right = 8
	scroll_style.content_margin_top = 8
	scroll_style.content_margin_bottom = 8
	var scroll_panel := PanelContainer.new()
	scroll_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_panel.add_theme_stylebox_override("panel", scroll_style)
	add_child(scroll_panel)

	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_panel.add_child(scroll_container)

	messages_container = VBoxContainer.new()
	messages_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messages_container.add_theme_constant_override("separation", 6)
	scroll_container.add_child(messages_container)

	# Input row
	var input_hbox := HBoxContainer.new()
	input_hbox.add_theme_constant_override("separation", 5)
	add_child(input_hbox)

	input_field = LineEdit.new()
	input_field.placeholder_text = "Type a message..."
	input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_field.text_submitted.connect(_on_send)
	input_hbox.add_child(input_field)

	send_button = Button.new()
	send_button.text = "Send"
	send_button.custom_minimum_size = Vector2(60, 0)
	send_button.pressed.connect(func() -> void: _on_send(input_field.text))
	var send_style := StyleBoxFlat.new()
	send_style.bg_color = Color(0.2, 0.4, 0.7)
	send_style.set_corner_radius_all(4)
	send_button.add_theme_stylebox_override("normal", send_style)
	input_hbox.add_child(send_button)


func _load_existing_history() -> void:
	var history := chat_manager.get_history(npc.id)
	for msg in history:
		if msg["role"] == "user":
			_add_message_bubble("You", msg["content"], Color(0.3, 0.35, 0.5))
		else:
			_add_message_bubble(npc.npc_name, msg["content"], Color(0.2, 0.35, 0.3))


func _on_send(text: String) -> void:
	if text.strip_edges().is_empty() or _is_waiting:
		return

	input_field.text = ""
	_is_waiting = true
	send_button.disabled = true

	_add_message_bubble("You", text, Color(0.3, 0.35, 0.5))

	# Show typing indicator
	var typing_label := Label.new()
	typing_label.text = "%s is thinking..." % npc.npc_name
	typing_label.add_theme_font_size_override("font_size", 11)
	typing_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	typing_label.name = "TypingIndicator"
	messages_container.add_child(typing_label)
	_scroll_to_bottom()

	chat_manager.send_message(npc, text, func(success: bool, response: String) -> void:
		# Remove typing indicator
		var indicator := messages_container.get_node_or_null("TypingIndicator")
		if indicator:
			indicator.queue_free()

		if success:
			_add_message_bubble(npc.npc_name, response, Color(0.2, 0.35, 0.3))

			# Apply chat effects
			var fav_change := ChatEffects.process_response(npc, response)
			if fav_change != 0:
				favorability_changed.emit()
		else:
			_add_message_bubble("System", "Failed to get response: " + response, Color(0.5, 0.2, 0.2))

		_is_waiting = false
		send_button.disabled = false
		input_field.grab_focus()
	)


func _add_message_bubble(sender: String, text: String, bg_color: Color) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var sender_label := Label.new()
	sender_label.text = sender
	sender_label.add_theme_font_size_override("font_size", 11)
	sender_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5))
	vbox.add_child(sender_label)

	var msg_label := Label.new()
	msg_label.text = text
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_font_size_override("font_size", 13)
	msg_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	vbox.add_child(msg_label)

	messages_container.add_child(panel)
	_scroll_to_bottom()


func _scroll_to_bottom() -> void:
	# Defer to next frame so layout is updated
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
