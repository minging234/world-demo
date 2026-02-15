extends Control

## Main UI controller. Builds the full layout programmatically and manages NPC state.

const NPC_COUNT := 6

var npcs: Array[NPCData] = []
var selected_npc: NPCData = null
var npc_generator: NPCGenerator
var round_number: int = 0
var round_manager: RoundManager = RoundManager.new()

# UI references
var top_bar: HBoxContainer
var npc_buttons: Array[Button] = []
var next_round_button: Button
var left_panel: PanelContainer
var portrait_rect: TextureRect
var right_panel: VBoxContainer
var notification_log: RichTextLabel
var loading_label: Label

# Sub-panels (populated in later phases)
var profile_panel: VBoxContainer
var action_buttons: HBoxContainer
var chat_panel: VBoxContainer


func _ready() -> void:
	_build_ui()
	_start_generation()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.11, 0.15)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	# === Top Bar ===
	var top_panel := PanelContainer.new()
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.15, 0.14, 0.2)
	top_style.content_margin_left = 10
	top_style.content_margin_right = 10
	top_style.content_margin_top = 5
	top_style.content_margin_bottom = 5
	top_panel.add_theme_stylebox_override("panel", top_style)
	root_vbox.add_child(top_panel)

	top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_panel.add_child(top_bar)

	# NPC buttons will be added after generation

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# Next Round button
	next_round_button = Button.new()
	next_round_button.text = "Next Round ▶"
	next_round_button.custom_minimum_size = Vector2(120, 50)
	next_round_button.disabled = true
	next_round_button.pressed.connect(_on_next_round)
	top_bar.add_child(next_round_button)

	# === Main Content (Left + Right) ===
	var content_hbox := HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 0)
	root_vbox.add_child(content_hbox)

	# Left Panel — Portrait
	left_panel = PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 0.4
	var left_style := StyleBoxFlat.new()
	left_style.bg_color = Color(0.1, 0.09, 0.13)
	left_style.content_margin_left = 20
	left_style.content_margin_right = 20
	left_style.content_margin_top = 20
	left_style.content_margin_bottom = 20
	left_panel.add_theme_stylebox_override("panel", left_style)
	content_hbox.add_child(left_panel)

	var left_center := CenterContainer.new()
	left_panel.add_child(left_center)

	portrait_rect = TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(300, 300)
	portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	left_center.add_child(portrait_rect)

	# Right Panel — Profile + Chat area
	var right_container := PanelContainer.new()
	right_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_container.size_flags_stretch_ratio = 0.6
	var right_style := StyleBoxFlat.new()
	right_style.bg_color = Color(0.13, 0.12, 0.17)
	right_style.content_margin_left = 15
	right_style.content_margin_right = 15
	right_style.content_margin_top = 15
	right_style.content_margin_bottom = 15
	right_container.add_theme_stylebox_override("panel", right_style)
	content_hbox.add_child(right_container)

	right_panel = VBoxContainer.new()
	right_panel.add_theme_constant_override("separation", 10)
	right_container.add_child(right_panel)

	# Placeholder for right panel content
	var placeholder := Label.new()
	placeholder.text = "Select an NPC to view their profile"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	right_panel.add_child(placeholder)

	# === Bottom Bar — Notification Log ===
	var bottom_panel := PanelContainer.new()
	bottom_panel.custom_minimum_size = Vector2(0, 120)
	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color = Color(0.08, 0.07, 0.1)
	bottom_style.content_margin_left = 10
	bottom_style.content_margin_right = 10
	bottom_style.content_margin_top = 5
	bottom_style.content_margin_bottom = 5
	bottom_panel.add_theme_stylebox_override("panel", bottom_style)
	root_vbox.add_child(bottom_panel)

	var bottom_vbox := VBoxContainer.new()
	bottom_panel.add_child(bottom_vbox)

	var log_title := Label.new()
	log_title.text = "Notification Log"
	log_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	log_title.add_theme_font_size_override("font_size", 12)
	bottom_vbox.add_child(log_title)

	notification_log = RichTextLabel.new()
	notification_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notification_log.bbcode_enabled = true
	notification_log.scroll_following = true
	notification_log.add_theme_color_override("default_color", Color(0.7, 0.7, 0.8))
	bottom_vbox.add_child(notification_log)

	# Loading label (shown during generation)
	loading_label = Label.new()
	loading_label.text = "Generating NPCs..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.set_anchors_and_offsets_preset(PRESET_CENTER)
	loading_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
	loading_label.add_theme_font_size_override("font_size", 18)
	add_child(loading_label)


func _start_generation() -> void:
	npc_generator = NPCGenerator.new()
	npc_generator.generate_npcs(NPC_COUNT, func(generated_npcs: Array[NPCData]) -> void:
		npcs = generated_npcs
		loading_label.visible = false
		_populate_top_bar()
		next_round_button.disabled = false
		_log_notification("[color=yellow]World initialized with %d cultivators.[/color]" % npcs.size())
	)


func _populate_top_bar() -> void:
	# Insert NPC buttons before the spacer
	for i in npcs.size():
		var npc := npcs[i]
		var btn := _create_npc_button(npc, i)
		top_bar.add_child(btn)
		top_bar.move_child(btn, i)
		npc_buttons.append(btn)


func _create_npc_button(npc: NPCData, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(80, 60)
	btn.tooltip_text = "%s — %s" % [npc.npc_name, npc.realm]

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	btn.add_child(vbox)

	# Try to load portrait as thumbnail
	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(40, 40)
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait := _load_portrait(npc)
	if portrait:
		tex_rect.texture = portrait
	vbox.add_child(tex_rect)

	var name_label := Label.new()
	name_label.text = npc.npc_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(name_label)

	btn.pressed.connect(_on_npc_selected.bind(index))
	return btn


func _load_portrait(npc: NPCData) -> ImageTexture:
	var abs_path := ProjectSettings.globalize_path(npc.portrait_path)
	if not FileAccess.file_exists(abs_path):
		return null

	var image := Image.new()
	var err := image.load(abs_path)
	if err != OK:
		return null

	return ImageTexture.create_from_image(image)


func _on_npc_selected(index: int) -> void:
	selected_npc = npcs[index]

	# Update button highlights
	for i in npc_buttons.size():
		var style := StyleBoxFlat.new()
		if i == index:
			style.bg_color = Color(0.3, 0.25, 0.5)
			style.border_color = Color(0.6, 0.5, 0.9)
			style.set_border_width_all(2)
		else:
			style.bg_color = Color(0.2, 0.18, 0.25)
		style.set_corner_radius_all(4)
		npc_buttons[i].add_theme_stylebox_override("normal", style)

	# Update portrait
	var portrait := _load_portrait(selected_npc)
	if portrait:
		portrait_rect.texture = portrait
	else:
		portrait_rect.texture = null

	# Update right panel
	_update_right_panel()


var _current_profile: NPCProfilePanel
var _current_actions: ActionButtons
var _current_chat: ChatPanel
var _chat_manager: ChatManager = ChatManager.new()
var _chat_visible: bool = false


func _update_right_panel() -> void:
	if not selected_npc:
		return

	# Clear right panel
	for child in right_panel.get_children():
		child.queue_free()

	# Profile panel
	_current_profile = NPCProfilePanel.new()
	_current_profile.setup(selected_npc)
	right_panel.add_child(_current_profile)

	# Action buttons
	var sep2 := HSeparator.new()
	right_panel.add_child(sep2)

	_current_actions = ActionButtons.new()
	_current_actions.setup(selected_npc)
	_current_actions.gift_given.connect(_on_gift_given)
	_current_actions.spar_result.connect(_on_spar_result)
	_current_actions.chat_pressed.connect(_on_chat_pressed)
	_current_actions.ask_about_pressed.connect(_on_ask_about_pressed)
	right_panel.add_child(_current_actions)

	# Chat panel (hidden by default, shown when Chat button pressed)
	_current_chat = ChatPanel.new()
	_current_chat.setup(selected_npc, _chat_manager)
	_current_chat.favorability_changed.connect(func() -> void:
		if _current_profile:
			_current_profile.update_favorability()
	)
	_current_chat.visible = _chat_visible
	right_panel.add_child(_current_chat)


func _on_gift_given(message: String, _change: int) -> void:
	_log_notification("[color=green]%s[/color]" % message)
	if _current_profile:
		_current_profile.update_favorability()


func _on_spar_result(message: String, change: int) -> void:
	var color := "green" if change > 0 else "red"
	_log_notification("[color=%s]%s[/color]" % [color, message])
	if _current_profile:
		_current_profile.update_favorability()


func _on_chat_pressed() -> void:
	_chat_visible = not _chat_visible
	if _current_chat:
		_current_chat.visible = _chat_visible


func _on_ask_about_pressed() -> void:
	if not selected_npc:
		return

	# Show a dropdown to pick another NPC to ask about
	_show_ask_about_dialog()


func _show_ask_about_dialog() -> void:
	# Create a simple popup with NPC choices
	var popup := PopupPanel.new()
	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color(0.15, 0.14, 0.2)
	popup_style.border_color = Color(0.4, 0.35, 0.6)
	popup_style.set_border_width_all(1)
	popup_style.set_corner_radius_all(6)
	popup_style.content_margin_left = 10
	popup_style.content_margin_right = 10
	popup_style.content_margin_top = 10
	popup_style.content_margin_bottom = 10
	popup.add_theme_stylebox_override("panel", popup_style)
	add_child(popup)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	popup.add_child(vbox)

	var title := Label.new()
	title.text = "Ask %s about..." % selected_npc.npc_name
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5))
	vbox.add_child(title)

	for npc in npcs:
		if npc.id == selected_npc.id:
			continue

		var btn := Button.new()
		btn.text = npc.npc_name
		btn.custom_minimum_size = Vector2(150, 30)
		var target_npc := npc
		btn.pressed.connect(func() -> void:
			popup.hide()
			popup.queue_free()
			_ask_about_npc(target_npc)
		)
		vbox.add_child(btn)

	popup.popup_centered(Vector2(200, 250))


func _ask_about_npc(target_npc: NPCData) -> void:
	_log_notification("[color=gray]Asking %s about %s...[/color]" % [selected_npc.npc_name, target_npc.npc_name])

	var system_prompt := _chat_manager.build_system_prompt(selected_npc)
	var rel := get_or_create_relationship(selected_npc, target_npc)

	var user_msg := "What do you think of %s? (They are a %s cultivator with %s affinity. Your relationship favorability with them: %d/100)" % [
		target_npc.npc_name, target_npc.realm, target_npc.element, rel.favorability
	]

	var messages := [{"role": "user", "content": user_msg}]

	LLMManager.chat(system_prompt, messages, func(success: bool, response: String) -> void:
		if success:
			_log_notification("[color=cyan]%s says about %s: \"%s\"[/color]" % [
				selected_npc.npc_name, target_npc.npc_name, response
			])
		else:
			_log_notification("[color=red]Failed to get response: %s[/color]" % response)
	)


func _on_next_round() -> void:
	round_number += 1
	_log_notification("[color=yellow]--- Round %d ---[/color]" % round_number)

	var results := round_manager.run_round(npcs, round_number)
	if results.is_empty():
		_log_notification("[color=gray]Nothing happened this round.[/color]")
		return

	for result in results:
		var color := "green" if result["fav_change"] > 0 else "red"
		_log_notification("[color=%s]%s[/color]" % [color, result["summary"]])

	# Refresh profile panel if selected NPC was involved
	if selected_npc and _current_profile:
		_current_profile.update_favorability()


func _log_notification(bbcode_text: String) -> void:
	notification_log.append_text(bbcode_text + "\n")


## Utility: get relationship between two NPCs
func get_or_create_relationship(npc_a: NPCData, npc_b: NPCData) -> Relationship:
	var key := npc_b.id
	if npc_a.relationships.has(key):
		return npc_a.relationships[key]

	var rel := Relationship.new()
	rel.npc_a_id = npc_a.id
	rel.npc_b_id = npc_b.id
	npc_a.relationships[key] = rel
	npc_b.relationships[npc_a.id] = rel
	return rel
