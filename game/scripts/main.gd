extends Control
const Data = preload("res://scripts/level_data.gd")
const World = preload("res://scripts/world.gd")
const Voice = preload("res://scripts/voice.gd")
var voice: Node
var sound_enabled := true
var sound_button: Button
var menu_sound_toggle: CheckButton
var begin_pending := false
var announcement_time := 0.0
var return_warning_armed := false
var previous_voice_row := 19
const MAZES = ["res://levels/moonlit_oasis.json", "res://levels/pharaohs_courtyard.json", "res://levels/violet_mire.json"]
const BUILTINS = MAZES + ["res://levels/little_frog_crossing.json"]
const HUMAN_TITLE = "Not as Hard as It Looks"
const HUMAN_LEVELS = ["res://levels/not_as_hard/Hardbutt.json", "res://levels/not_as_hard/Gloopbutt.json", "res://levels/not_as_hard/Treebutt.json", "res://levels/not_as_hard/Frogbutt.json"]
const BONUS_LEVELS = ["res://levels/bonus/Shelby.json"]
const SET_TITLES = {"baby": "Baby Mode", "human": HUMAN_TITLE, "bonus": "Bonus"}
const HAT_NAMES = {"none": "No hat", "pharaoh": "Pharaoh headdress", "baby": "Baby frog hat"}
const INK = Color("f7f0d8")
const MUTED = Color("b7c8b9")
const LIME = Color("d5ec8d")
var world: Node3D
var view: SubViewport
var view_container: SubViewportContainer
var sidebar: PanelContainer
var overlay: Control
var overlay_panel: PanelContainer
var overlay_box: VBoxContainer
var status_label: Label
var time_label: Label
var mode_label: Label
var edit_button: Button
var pause_button: Button
var map_button: Button
var retro_filter: ShaderMaterial
var level_banner: Label
var name_field: LineEdit
var size_picker: OptionButton
var exit_preview := false
var preview_toggle: CheckButton
var pending_result := ""
var pending_set_complete := false
var pending_earned_hat := false
var theme_picker: OptionButton
var saved_picker: OptionButton
var tool_label: Label
var inspector: VBoxContainer
var undo_button: Button
var redo_button: Button
var level: Dictionary = {}
var library: Array = []
var slot_id := ""
var builtin_index := 0
var mode := "menu"
var tool := "floor"
var selection := ""
var undo_stack: Array = []
var redo_stack: Array = []
var stroke := false
var stroke_changed := false
var last_cell := Vector2i(-1, -1)
var deaths := 0
var hat := "pharaoh"
var unlocked_hats: Array = ["none", "pharaoh"]
var completed_stages: Array = []
var completed_human_stages: Array = []
var completed_bonus_stages: Array = []
var last_cleared_stages: Dictionary = {}
var campaign_set := "baby"
var campaign_level := false
var checkpoint_spawn: Array = []
var checkpoint_history: Array = []
var hat_button: Button
var paused := false
var ui_busy := false
var last_view_size := Vector2.ZERO
var last_render_size := Vector2i.ZERO
var thumb := Vector2.ZERO
var touch_index := -1
var touch_origin := Vector2.ZERO
var touch_knob: Control
var joystick: Control
var poll_timer := 0.0
var test_mode := false
var test_runner: RefCounted
var browser_test := false
var probe_timer := 0.0
var mobile_ui := false
var compatibility_mode := false

func _ready() -> void:
	compatibility_mode = "--compat" in OS.get_cmdline_args() or "--compat" in OS.get_cmdline_user_args()
	World.Art.compatibility_mode = compatibility_mode
	mobile_ui = DisplayServer.is_touchscreen_available()
	resize_mobile_ui()
	test_mode = "--integration-test" in OS.get_cmdline_user_args()
	browser_test = OS.is_debug_build() and ("--browser-test" in OS.get_cmdline_user_args() or "--browser-test" in OS.get_cmdline_args())
	make_theme()
	load_profile()
	voice = Voice.new()
	add_child(voice)
	voice.set_enabled(sound_enabled)
	load_library()
	build_ui()
	load_builtin(0)
	show_menu()
	if OS.has_feature("web"):
		RenderingServer.frame_post_draw.connect(notify_web_ready, CONNECT_ONE_SHOT)
	if test_mode:
		test_runner = preload("res://tests/integration.gd").new()
		test_runner.call_deferred("run", self)

func notify_web_ready() -> void:
	JavaScriptBridge.eval("if (window.hopanBoot) window.hopanBoot.ready();", true)

func make_theme() -> void:
	var t := Theme.new()
	t.default_font_size = 15
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", LIME)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_color", "TextEdit", INK)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := panel_style(Color("305346") if state == "hover" else Color("203e33"), 7)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		if state == "focus":
			style.border_color = LIME
			style.set_border_width_all(2)
		t.set_stylebox(state, "Button", style)
	for type_name in ["LineEdit", "TextEdit"]:
		var style := panel_style(Color("10291f"), 5)
		style.content_margin_left = 9
		style.content_margin_top = 7
		style.content_margin_bottom = 7
		t.set_stylebox("normal", type_name, style)
		t.set_color("caret_color", type_name, LIME)
	t.set_stylebox("panel", "PopupMenu", panel_style(Color("1c382d"), 6))
	theme = t

func panel_style(color: Color, radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = Color(0.8, 0.9, 0.7, 0.16)
	return style

func label(text: String, size: int = 15, color: Color = INK) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	return item

func button(parent: Node, text: String, callback: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 44 if mobile_ui else 42
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(callback)
	if primary:
		var style := panel_style(LIME, 7)
		style.content_margin_left = 15
		style.content_margin_right = 15
		b.add_theme_stylebox_override("normal", style)
		b.add_theme_color_override("font_color", Color("18352b"))
	parent.add_child(b)
	return b

func row(parent: Node) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 8)
	parent.add_child(r)
	return r

func margin(parent: Node, padding: int = 16) -> MarginContainer:
	var m := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + side, padding)
	parent.add_child(m)
	return m

func paragraph(parent: Node, text: String, size: int = 14) -> Label:
	var l := label(text, mini(size, 12) if mobile_ui else size, MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("10281f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", panel_style(Color("132c23"), 0))
	root.add_child(header)
	var top := row(margin(header, 10))
	top.add_child(label("hopán", 28, LIME))
	mode_label = label("", 13, MUTED)
	top.add_child(mode_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	button(top, "Menu", show_menu)
	sound_button = button(top, "Sound: On" if sound_enabled else "Sound: Off", func(): set_sound_enabled(not sound_enabled))
	sound_button.add_theme_font_size_override("font_size", 13)
	hat_button = button(top, "Hat", toggle_hat)
	hat_button.tooltip_text = str(HAT_NAMES[hat]) + " · Cycle unlocked hats"
	map_button = button(top, "Map", toggle_map)
	map_button.tooltip_text = "M: inspect the overhead map; the world pauses"
	pause_button = button(top, "Pause", toggle_pause)
	edit_button = button(top, "Editor", func():
		if mode == "edit":
			playtest()
		else:
			enter_editor(), true)
	var center := HBoxContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 0)
	root.add_child(center)
	sidebar = PanelContainer.new()
	sidebar.custom_minimum_size.x = 280
	sidebar.add_theme_stylebox_override("panel", panel_style(Color("18372b"), 0))
	center.add_child(sidebar)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(scroll)
	var side_margin := margin(scroll, 14)
	side_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tools := VBoxContainer.new()
	tools.add_theme_constant_override("separation", 9)
	side_margin.add_child(tools)
	tools.add_child(label("MAZE WORKSHOP", 12, LIME))
	name_field = LineEdit.new()
	name_field.max_length = 80
	name_field.placeholder_text = "Level name"
	name_field.text_submitted.connect(func(_s: String): commit_name(); name_field.release_focus())
	name_field.focus_exited.connect(commit_name)
	tools.add_child(name_field)
	theme_picker = OptionButton.new()
	theme_picker.add_item("Egyptian ruins")
	theme_picker.add_item("Purple Swamp-Woods")
	theme_picker.item_selected.connect(change_theme)
	tools.add_child(theme_picker)
	size_picker = OptionButton.new()
	size_picker.add_item("Standard · 17 × 13")
	size_picker.add_item("Large · 21 × 16 · +52% area")
	size_picker.tooltip_text = "Size for the next new maze. Your current level stays intact."
	tools.add_child(size_picker)
	var new_row := row(tools)
	button(new_row, "New Egypt", func(): new_level("egypt"))
	button(new_row, "New Swamp", func(): new_level("swamp"))
	var saves := row(tools)
	button(saves, "Save", save_level, true)
	button(saves, "Duplicate", duplicate_level)
	saved_picker = OptionButton.new()
	saved_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	saved_picker.item_selected.connect(load_saved)
	tools.add_child(saved_picker)
	var io := row(tools)
	button(io, "Export JSON", export_json)
	button(io, "Import", import_dialog)
	var history := row(tools)
	undo_button = button(history, "Undo", undo)
	redo_button = button(history, "Redo", redo)
	tool_label = label("", 13, LIME)
	tools.add_child(tool_label)
	var palette := GridContainer.new()
	palette.columns = 2
	palette.add_theme_constant_override("h_separation", 6)
	palette.add_theme_constant_override("v_separation", 6)
	tools.add_child(palette)
	for entry in [["floor", "Floor"], ["path", "Path"], ["wall", "Wall"], ["cheese_wall", "Cheese wall"], ["water", "Water"], ["road", "Road"], ["car", "Car"], ["patrol_car", "Patrol car"], ["log", "Log"], ["spawn", "Frog start"], ["exit", "Exit gate"], ["checkpoint", "Checkpoint"], ["pillar", "Pillar"], ["tree", "Tree"], ["mushroom", "Mushroom"], ["decoration", "Pot"], ["critter", "Critter"], ["seam_worm", "Seam worm"], ["emitter", "Dart trap"], ["select", "Select"], ["erase", "Erase"], ["route", "Patrol route"]]:
		var key: String = entry[0]
		var b := button(palette, entry[1], func(): set_tool(key))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 13)
		b.custom_minimum_size.y = 32
		var compact := panel_style(Color("203e33"), 6)
		compact.content_margin_top = 4
		compact.content_margin_bottom = 4
		b.add_theme_stylebox_override("normal", compact)
	inspector = VBoxContainer.new()
	inspector.add_theme_constant_override("separation", 8)
	tools.add_child(inspector)
	paragraph(tools, "Click or drag to paint. Select an object to edit it. Right-click erases. R rotates. Ctrl+Z / Ctrl+Y undo / redo. Space playtests.", 12)
	view_container = SubViewportContainer.new()
	view_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view_container.stretch = true
	view_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	retro_filter = ShaderMaterial.new()
	retro_filter.shader = preload("res://shaders/retro_screen.gdshader")
	center.add_child(view_container)
	view = SubViewport.new()
	view.size = Vector2i(1000, 680)
	view.handle_input_locally = false
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view_container.add_child(view)
	world = World.new()
	world.touch_mode = mobile_ui
	view.add_child(world)
	world.finished.connect(on_finished)
	world.checkpoint_reached.connect(func(point: Array):
		checkpoint_spawn = point.duplicate()
		if point not in checkpoint_history:
			checkpoint_history.append(point.duplicate())
		status("Checkpoint reached! Retry will return you here."))
	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override("panel", panel_style(Color("132c23"), 0))
	root.add_child(footer)
	var bottom := row(margin(footer, 9))
	status_label = label("", 13, MUTED)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bottom.add_child(status_label)
	time_label = label("", 13, LIME)
	bottom.add_child(time_label)
	level_banner = label("", 23, Color("f5e8ae"))
	level_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_banner.add_theme_color_override("font_outline_color", Color("17243a"))
	level_banner.add_theme_constant_override("outline_size", 6)
	add_child(level_banner)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.07, 0.055, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var overlay_scroll := ScrollContainer.new()
	overlay_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(overlay_scroll)
	var align := CenterContainer.new()
	align.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	align.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_scroll.add_child(align)
	overlay_panel = PanelContainer.new()
	overlay_panel.custom_minimum_size.x = minf(560, get_window().content_scale_size.x - 24) if mobile_ui else 560
	overlay_panel.add_theme_stylebox_override("panel", panel_style(Color("193a2e"), 16))
	align.add_child(overlay_panel)
	overlay_box = VBoxContainer.new()
	overlay_box.add_theme_constant_override("separation", 8 if mobile_ui else 14)
	margin(overlay_panel, 16 if mobile_ui else 28).add_child(overlay_box)
	build_joystick()
	refresh_library_picker()
	set_tool("floor")

func build_joystick() -> void:
	joystick = Control.new()
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(34, -205)
	joystick.size = Vector2(138, 138)
	add_child(joystick)
	var base := Panel.new()
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.size = Vector2(138, 138)
	base.add_theme_stylebox_override("panel", panel_style(Color(0.8, 0.92, 0.65, 0.16), 69))
	joystick.add_child(base)
	touch_knob = Panel.new()
	touch_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_knob.size = Vector2(54, 54)
	touch_knob.position = Vector2(42, 42)
	touch_knob.add_theme_stylebox_override("panel", panel_style(Color(0.83, 0.94, 0.55, 0.7), 27))
	joystick.add_child(touch_knob)
	var hint := label("MOVE", 11, LIME)
	hint.position = Vector2(50, 145)
	joystick.add_child(hint)

func reset_overlay(title: String, subtitle: String = "") -> void:
	for child in overlay_box.get_children():
		overlay_box.remove_child(child)
		child.queue_free()
	overlay_box.add_child(label("H O P O C A L Y P S E", 12, LIME))
	var heading := label(title, 26 if mobile_ui else 36)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_box.add_child(heading)
	if not subtitle.is_empty():
		paragraph(overlay_box, subtitle)
	overlay.show()
	reset_touch()

func show_menu() -> void:
	begin_pending = false
	voice.clear()
	world.halted = true
	edit_button.hide()
	reset_overlay("Pharaoh Frog Hopán")
	overlay_box.add_child(label("Level sets", 16, MUTED))
	add_set_selector("baby", "Difficulty 1")
	if human_set_unlocked():
		add_set_selector("human", "Difficulty 2")
	if BONUS_LEVELS.any(func(path: String): return FileAccess.file_exists(path)):
		add_set_selector("bonus", "Difficulty: Unrated")
	preview_toggle = CheckButton.new()
	preview_toggle.text = "Exit Preview"
	preview_toggle.tooltip_text = "At stage start, sweep to the exit and back. Hazards and the timer wait."
	preview_toggle.button_pressed = exit_preview
	preview_toggle.toggled.connect(set_exit_preview)
	overlay_box.add_child(preview_toggle)
	menu_sound_toggle = CheckButton.new()
	menu_sound_toggle.text = "Sound"
	menu_sound_toggle.button_pressed = sound_enabled
	menu_sound_toggle.toggled.connect(set_sound_enabled)
	overlay_box.add_child(menu_sound_toggle)
	button(overlay_box, "Level editor · Create a maze", func(): enter_editor())
	if not library.is_empty():
		var custom := OptionButton.new()
		custom.add_item("Play a saved custom level…")
		for item in library:
			custom.add_item(item.level.name)
		custom.item_selected.connect(func(i: int):
			if i > 0:
				load_library_entry(i - 1)
				start_play(false))
		overlay_box.add_child(custom)
	if mode != "menu":
		button(overlay_box, "Continue " + ("editing" if mode == "edit" else "playing"), func():
			overlay.hide()
			world.halted = false
			paused = false
			edit_button.visible = mode == "edit"
			joystick.visible = mobile_ui and mode in ["play", "test"])
	paragraph(overlay_box, "WASD / arrows · touch joystick on mobile\nM: overhead map   R: retry   Esc: pause", 12)
	joystick.hide()

func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	voice.set_enabled(enabled)
	if is_instance_valid(sound_button):
		sound_button.text = "Sound: On" if enabled else "Sound: Off"
	if is_instance_valid(menu_sound_toggle):
		menu_sound_toggle.set_pressed_no_signal(enabled)
	save_profile()

func human_set_unlocked() -> bool:
	return completed_stages.size() == BUILTINS.size()

func campaign_paths() -> Array:
	return paths_for_set(campaign_set)

func play_builtin(index: int, set_key: String = "baby") -> void:
	if load_builtin(index, set_key):
		start_play(false)

func load_builtin(index: int, set_key: String = "baby") -> bool:
	if set_key not in SET_TITLES or (set_key == "human" and not human_set_unlocked()):
		status("Complete Baby Mode to unlock " + HUMAN_TITLE + ".")
		return false
	var paths: Array = paths_for_set(set_key)
	if index < 0 or index >= paths.size():
		return false
	var loaded := Data.load_json(paths[index])
	if loaded.is_empty():
		status("Could not load the bundled level.")
		return false
	campaign_set = set_key
	builtin_index = index
	campaign_level = true
	level = loaded
	slot_id = ""
	undo_stack.clear()
	redo_stack.clear()
	selection = ""
	deaths = 0
	world.load_level(level, false, hat)
	sync_editor()
	return true

func start_play(from_editor: bool = true) -> void:
	pending_result = ""
	commit_name()
	var error := Data.validate(level)
	if not error.is_empty():
		status(error)
		return
	if not Data.reachable(level):
		status("The exit is blocked. Connect the route with dry ground or rideable log lanes.")
		return
	mode = "test" if from_editor else "play"
	checkpoint_spawn = []
	checkpoint_history = []
	paused = false
	sidebar.hide()
	overlay.hide()
	world.load_level(level, false, hat)
	world.halted = false
	map_button.text = "Map"
	map_button.show()
	configure_view()
	if exit_preview:
		world.begin_exit_preview()
	mode_label.text = "PLAYTEST" if from_editor else ((str(SET_TITLES[campaign_set]).to_upper() + " · %d / %d") % [builtin_index + 1, campaign_paths().size()] if campaign_level else "CUSTOM LEVEL")
	edit_button.hide()
	pause_button.text = "Pause"
	pause_button.show()
	joystick.visible = DisplayServer.is_touchscreen_available()
	status(level.name + (" · Reach checkpoints to save your place for retries." if level.has("checkpoint") or not level.get("checkpoints", []).is_empty() else " · WASD / arrows to move. M: map. R: retry."))
	reset_touch()
	start_announcements()

func enter_editor() -> void:
	begin_pending = false
	voice.clear()
	pending_result = ""
	campaign_level = false
	checkpoint_spawn = []
	checkpoint_history = []
	mode = "edit"
	paused = false
	sidebar.show()
	overlay.hide()
	joystick.hide()
	pause_button.hide()
	map_button.hide()
	world.load_level(level, true, hat)
	configure_view()
	mode_label.text = "WORKSHOP"
	edit_button.text = "Playtest ▶"
	edit_button.show()
	sync_editor()
	status("Build your maze. Space: playtest · Save keeps a local copy · Export creates portable JSON.")

func playtest() -> void:
	start_play(true)

func retry() -> void:
	pending_result = ""
	paused = false
	overlay.hide()
	world.load_level(level, false, hat)
	world.restore_checkpoints(checkpoint_history)
	if not checkpoint_spawn.is_empty():
		world.player.position = world.cell_position(checkpoint_spawn)
		world.crossing.checkpoint_claimed = true
		world.fit_camera()
	world.halted = false
	map_button.text = "Map"
	configure_view()
	reset_touch()
	joystick.visible = DisplayServer.is_touchscreen_available()
	status(level.name + " · A fresh hop. R to retry.")
	start_announcements(true)

func on_finished(reason: String) -> void:
	if not pending_result.is_empty():
		return
	begin_pending = false
	voice.clear()
	var progress: Array = progress_for_set()
	if reason == "LEVEL COMPLETE!" and mode == "play" and campaign_level:
		if builtin_index not in progress:
			progress.append(builtin_index)
		last_cleared_stages[campaign_set] = builtin_index
		save_profile()
	var set_complete := reason == "LEVEL COMPLETE!" and mode == "play" and campaign_level and progress.size() == campaign_paths().size()
	var earned_hat := set_complete and campaign_set == "baby" and "baby" not in unlocked_hats
	if set_complete and campaign_set == "baby":
		voice.say("baby_win")
	if earned_hat:
		unlock_baby_hat()
		voice.say("baby_frog")
	pending_result = reason
	pending_set_complete = set_complete
	pending_earned_hat = earned_hat
	if reason != "LEVEL COMPLETE!":
		deaths += 1
		voice.say(voice.death_cue(reason, world.death_cause))
	reset_touch()
	joystick.hide()

func update_result_presentation() -> void:
	if pending_result.is_empty():
		return
	if world.result != pending_result:
		pending_result = ""
		return
	var delay := 2.2 if pending_result == "LEVEL COMPLETE!" else 1.6
	if world.result_time < delay or world.halted or overlay.visible:
		return
	var reason := pending_result
	pending_result = ""
	present_result(reason, pending_set_complete, pending_earned_hat)

func present_result(reason: String, set_complete: bool, earned_hat: bool) -> void:
	var complete_title: String = str(SET_TITLES.get(campaign_set, "Level")).to_upper() + " COMPLETE!"
	reset_overlay(complete_title if set_complete else reason, "%.1f seconds  ·  %d deaths" % [world.elapsed, deaths])
	if reason != "LEVEL COMPLETE!":
		paragraph(overlay_box, {"CROAKED!": "That critter had other plans.", "SPLASHED!": "Ride the logs to stay above the water.", "HIT!": "Ancient security systems still work.", "SQUISHED!": "Wait on the bank for a wider gap in traffic."}.get(reason, ""))
	else:
		paragraph(overlay_box, "One small frog. One magnificent escape.")
		if mode == "play" and campaign_level:
			if set_complete:
				if campaign_set == "human":
					paragraph(overlay_box, "All four human-made stages cleared! " + HUMAN_TITLE + ".")
				elif campaign_set == "baby":
					paragraph(overlay_box, "All four Baby Mode stages cleared! " + HUMAN_TITLE + " is unlocked.")
					button(overlay_box, "Start · " + HUMAN_TITLE, func(): play_builtin(0, "human"), true)
				else:
					paragraph(overlay_box, "Bonus set cleared!")
				if earned_hat:
					paragraph(overlay_box, "Unlocked: Baby frog hat! Equipped now. Press Hat to cycle your unlocked hats.")
		if mode == "play" and campaign_level and builtin_index < campaign_paths().size() - 1:
			button(overlay_box, "Next level →", func(): play_builtin(builtin_index + 1, campaign_set), true)
	button(overlay_box, "Retry · R", retry, true)
	button(overlay_box, "Menu", show_menu)
	joystick.hide()

func toggle_pause() -> void:
	if mode not in ["play", "test"] or not world.result.is_empty():
		return
	paused = not paused
	world.halted = paused
	reset_touch()
	if paused:
		reset_overlay("Taking a breather.", "The maze will wait. So will the critters.")
		button(overlay_box, "Resume", toggle_pause, true)
		button(overlay_box, "Menu", show_menu)
	else:
		overlay.hide()
		joystick.visible = DisplayServer.is_touchscreen_available()
	pause_button.text = "Resume" if paused else "Pause"

func toggle_map() -> void:
	if mode not in ["play", "test"] or overlay.visible or not world.result.is_empty():
		return
	world.set_map_view(not world.map_view)
	reset_touch()
	map_button.text = "3D view" if world.map_view else "Map"
	joystick.visible = mobile_ui and not world.map_view
	configure_view()
	status("Overhead map · World paused. M or 3D view returns to the frog." if world.map_view else level.name + " · M: map. R: retry.")

func configure_view() -> void:
	var retro: bool = not world.editing and not world.map_view
	view_container.stretch_shrink = maxi(1, roundi(view_container.size.y / 240.0)) if retro else 1
	view_container.material = retro_filter if retro and not compatibility_mode else null
	retro_filter.set_shader_parameter("source_size", Vector2(view.size))

func viewport_position(global: Vector2) -> Vector2:
	return (global - view_container.global_position) * Vector2(view.size) / view_container.size.max(Vector2.ONE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(world) and mode in ["play", "test"] and world.active and not paused and not overlay.visible:
		toggle_pause()

func set_exit_preview(enabled: bool) -> void:
	exit_preview = enabled
	if not enabled and is_instance_valid(world):
		world.cancel_exit_preview()
	save_profile()

func toggle_hat() -> void:
	var index := unlocked_hats.find(hat)
	hat = unlocked_hats[(index + 1) % unlocked_hats.size()]
	world.player.set_hat(hat)
	hat_button.tooltip_text = str(HAT_NAMES[hat]) + " · Cycle unlocked hats"
	save_profile()
	status(str(HAT_NAMES[hat]) + " · Hat cycles your unlocked headwear.")
	if hat == "baby" and not voice.busy():
		voice.say("baby_frog")

func unlock_baby_hat() -> void:
	if completed_stages.size() != BUILTINS.size():
		return
	if "baby" not in unlocked_hats:
		unlocked_hats.append("baby")
		hat = "baby"
		world.player.set_hat(hat)
		if is_instance_valid(hat_button):
			hat_button.tooltip_text = "Baby frog hat · Cycle unlocked hats"
		save_profile()

func save_profile() -> void:
	var profile := ConfigFile.new()
	profile.set_value("settings", "exit_preview", exit_preview)
	profile.set_value("settings", "recorded_voices", sound_enabled)
	profile.set_value("hats", "baby_unlocked", "baby" in unlocked_hats)
	profile.set_value("hats", "equipped", hat)
	profile.set_value("baby_mode", "completed", completed_stages)
	profile.set_value("not_as_hard", "completed", completed_human_stages)
	profile.set_value("bonus", "completed", completed_bonus_stages)
	profile.set_value("sets", "last_cleared", last_cleared_stages)
	var file_saved := profile.save("user://profile.cfg") == OK
	var browser_saved := false
	if OS.has_feature("web"):
		# IndexedDB filesystem sync is asynchronous. Keep the small profile durable
		# immediately as well, so a quick reload cannot restore an older hat/clear.
		var payload := JSON.stringify({"version": 1, "baby": completed_stages, "human": completed_human_stages, "bonus": completed_bonus_stages, "last_cleared": last_cleared_stages, "hat": hat, "preview": exit_preview, "sound": sound_enabled})
		browser_saved = bool(JavaScriptBridge.eval("(function(){try{localStorage.setItem('hopan.profile.v1', " + JSON.stringify(payload) + ");return true;}catch(e){return false;}})()", true))
	if not file_saved and not browser_saved:
		status("Could not save progress on this device.")

func load_profile() -> void:
	unlocked_hats = ["none", "pharaoh"]
	completed_stages = []
	completed_human_stages = []
	completed_bonus_stages = []
	last_cleared_stages = {}
	hat = "pharaoh"
	var profile := ConfigFile.new()
	var file_loaded := profile.load("user://profile.cfg") == OK
	var browser_loaded := false
	if OS.has_feature("web"):
		var stored: Variant = JavaScriptBridge.eval("(function(){try{return localStorage.getItem('hopan.profile.v1');}catch(e){return null;}})()", true)
		if stored is String and stored.length() < 16384:
			var parsed := JSON.new()
			var backup: Variant = Data.normalize(parsed.data) if parsed.parse(stored) == OK else null
			if backup is Dictionary and backup.get("version") == 1 and backup.get("baby") is Array and backup.get("human") is Array and backup.get("hat") in HAT_NAMES and backup.get("preview") is bool:
				profile.set_value("baby_mode", "completed", backup.baby)
				profile.set_value("not_as_hard", "completed", backup.human)
				if backup.get("bonus") is Array:
					profile.set_value("bonus", "completed", backup.bonus)
				if backup.get("last_cleared") is Dictionary:
					profile.set_value("sets", "last_cleared", backup.last_cleared)
				profile.set_value("hats", "equipped", backup.hat)
				profile.set_value("settings", "exit_preview", backup.preview)
				if backup.get("sound") is bool:
					profile.set_value("settings", "recorded_voices", backup.sound)
				browser_loaded = true
	if not file_loaded and not browser_loaded:
		return
	exit_preview = profile.get_value("settings", "exit_preview", false) == true
	sound_enabled = profile.get_value("settings", "recorded_voices", true) == true
	var saved_stages: Variant = profile.get_value("baby_mode", "completed", [])
	if saved_stages is Array:
		for value in saved_stages:
			if value is int and value >= 0 and value < BUILTINS.size() and value not in completed_stages:
				completed_stages.append(value)
	var saved_human: Variant = profile.get_value("not_as_hard", "completed", [])
	if saved_human is Array:
		for value in saved_human:
			if value is int and value >= 0 and value < HUMAN_LEVELS.size() and value not in completed_human_stages:
				completed_human_stages.append(value)
	var saved_bonus: Variant = profile.get_value("bonus", "completed", [])
	if saved_bonus is Array:
		for value in saved_bonus:
			if value is int and value >= 0 and value < BONUS_LEVELS.size() and value not in completed_bonus_stages:
				completed_bonus_stages.append(value)
	var saved_last: Variant = profile.get_value("sets", "last_cleared", {})
	if saved_last is Dictionary:
		for set_key in SET_TITLES:
			var value: Variant = saved_last.get(set_key)
			if value is int and value in progress_for_set(set_key):
				last_cleared_stages[set_key] = value
	# Version 4 granted this hat on entry. Only completed sets qualify now;
	# keep all legitimate stage progress and other equipped hats intact.
	if completed_stages.size() == BUILTINS.size():
		unlocked_hats.append("baby")
	var saved_hat: Variant = profile.get_value("hats", "equipped", "pharaoh")
	hat = str(saved_hat) if saved_hat in unlocked_hats else "pharaoh"
	if browser_loaded:
		save_profile()

func status(text: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = text

func sync_editor() -> void:
	if level.is_empty():
		return
	ui_busy = true
	name_field.text = level.name
	theme_picker.select(0 if level.theme == "egypt" else 1)
	undo_button.disabled = undo_stack.is_empty()
	redo_button.disabled = redo_stack.is_empty()
	ui_busy = false
	refresh_inspector()

func commit_name() -> void:
	if ui_busy or level.is_empty() or not is_instance_valid(name_field):
		return
	var text := name_field.text.strip_edges()
	if text.is_empty():
		name_field.text = level.name
	elif level.name != text:
		record_undo()
		level.name = text

func change_theme(index: int) -> void:
	if ui_busy:
		return
	record_undo()
	level.theme = "egypt" if index == 0 else "swamp"
	rebuild()

func record_undo() -> void:
	undo_stack.append(level.duplicate(true))
	if undo_stack.size() > 80:
		undo_stack.pop_front()
	redo_stack.clear()
	undo_button.disabled = false
	redo_button.disabled = true

func undo() -> void:
	if mode != "edit" or undo_stack.is_empty():
		return
	redo_stack.append(level.duplicate(true))
	level = undo_stack.pop_back()
	selection = ""
	rebuild()
	status("Undid the last edit.")

func redo() -> void:
	if mode != "edit" or redo_stack.is_empty():
		return
	undo_stack.append(level.duplicate(true))
	level = redo_stack.pop_back()
	selection = ""
	rebuild()
	status("Redid the last edit.")

func set_tool(key: String) -> void:
	tool = key
	tool_label.text = "TOOL  /  " + key.replace("_", " ").to_upper()
	if key == "route":
		status("Select a critter or patrol car, then draw waypoints on its permitted terrain.")

func rebuild() -> void:
	world.load_level(level, true, hat)
	sync_editor()
	if not selected_object().is_empty():
		world.show_route(selected_object())

func selected_object() -> Dictionary:
	for obj in level.get("objects", []):
		if obj.id == selection:
			return obj
	return {}

func object_at(cell: Vector2i) -> int:
	for i in range(level.objects.size() - 1, -1, -1):
		var p: Array = level.objects[i].get("seam_anchor", level.objects[i].pos) if level.objects[i].get("behavior") == "seam_patrol" else level.objects[i].pos
		if Vector2i(int(p[0]), int(p[1])) == cell:
			return i
	return -1

func edit_cell(cell: Vector2i, erase: bool = false) -> void:
	if not world.inside(cell):
		return
	var point: Array = [cell.x, cell.y]
	var index := object_at(cell)
	if tool == "select" and not erase:
		selection = level.objects[index].id if index >= 0 else ""
		refresh_inspector()
		world.show_route(selected_object())
		return
	if tool == "route" and not erase:
		var obj := selected_object()
		if obj.is_empty() or obj.type not in ["critter", "patrol_car"]:
			status("Select a critter or patrol car, then choose Patrol route.")
			return
		if level.tiles[cell.y][cell.x] in ["wall", "cheese_wall", "water"]:
			status("Waypoints need dry, open terrain.")
			return
		if obj.type == "patrol_car":
			var previous: Array = obj.get("waypoints", [])[-1] if not obj.get("waypoints", []).is_empty() else obj.pos
			if not Data.road_segment_open(level, previous, point):
				status("Car patrols need connected road cells. Add a waypoint at each turn.")
				return
		if obj.get("behavior") == "seam_patrol":
			point = [cell.x + 0.5, cell.y + 0.5]
			var previous: Array = obj.get("waypoints", [])[-1] if not obj.get("waypoints", []).is_empty() else obj.pos
			if not Data.seam_point_open(level, point) or not Data.seam_segment_open(level, previous, point):
				status("Follow an open tile edge. Add a corner before turning; seam worms snap to the lower-right corner of each clicked tile.")
				return
		if obj.get("waypoints", []).size() >= 64:
			return
		record_undo()
		if obj.type == "critter" and obj.get("behavior") != "seam_patrol":
			obj.behavior = "patrol"
		if not obj.has("waypoints"):
			obj.waypoints = []
		obj.waypoints.append(point)
		rebuild()
		return
	if tool == "checkpoint" and not erase:
		if point == level.spawn or point == level.exit or not Data.checkpoint_open(level, point):
			status("Checkpoints need clear, safe ground away from the start and exit.")
			return
		if point in level.get("checkpoints", []) or point == level.get("checkpoint", []):
			return
		if level.get("checkpoints", []).size() >= 16:
			status("A level supports up to 16 editor checkpoints.")
			return
		record_undo()
		if not level.has("checkpoints"):
			level.checkpoints = []
		level.checkpoints.append(point)
		rebuild()
		status("Checkpoint placed. Reach the flag during play; erase removes it.")
		return
	if not stroke_changed:
		record_undo()
		stroke_changed = true
	if (erase or tool == "erase") and (point in level.get("checkpoints", []) or point == level.get("checkpoint", [])):
		if point in level.get("checkpoints", []):
			level.checkpoints.erase(point)
		if point == level.get("checkpoint", []):
			level.erase("checkpoint")
		rebuild()
		return
	var checkpoint_cell: bool = point in level.get("checkpoints", []) or point == level.get("checkpoint", [])
	if checkpoint_cell and (tool in ["wall", "cheese_wall", "water", "road", "spawn", "exit", "pillar", "tree", "emitter"]):
		status("Erase or move the checkpoint before blocking its safe tile.")
		return
	if erase or tool == "erase":
		if index >= 0:
			level.objects.remove_at(index)
			selection = ""
		else:
			level.tiles[cell.y][cell.x] = "floor"
	elif tool in Data.TILES:
		if tool in ["wall", "cheese_wall", "water"] and (point == level.spawn or point == level.exit):
			status("Move the frog or exit before painting a hazard here.")
			return
		level.tiles[cell.y][cell.x] = tool
		if tool in ["wall", "cheese_wall", "water"]:
			for i in range(level.objects.size() - 1, -1, -1):
				if level.objects[i].pos == point or (level.objects[i].get("behavior") == "seam_patrol" and not Data.seam_point_open(level, level.objects[i].pos)):
					level.objects.remove_at(i)
	elif tool in ["spawn", "exit"]:
		if point == level.get("exit" if tool == "spawn" else "spawn"):
			status("The start and exit need different cells.")
			return
		level.tiles[cell.y][cell.x] = "path"
		if index >= 0:
			level.objects.remove_at(index)
		level[tool] = point
	elif tool in Data.OBJECTS or tool == "seam_worm":
		var terrain: String = level.tiles[cell.y][cell.x]
		if (tool == "log" and terrain != "water") or (tool in ["car", "patrol_car"] and terrain != "road"):
			status("Logs belong on water. Cars belong on road lanes.")
			return
		if point == level.spawn or point == level.exit or terrain in ["wall", "cheese_wall"] or (terrain == "water" and tool != "log"):
			status("Place objects on dry terrain away from the start and exit.")
			return
		if index >= 0 or level.objects.size() >= 180:
			return
		if tool == "seam_worm":
			point = [cell.x + 0.5, cell.y + 0.5]
			if not Data.seam_point_open(level, point):
				status("Place a seam worm at a corner surrounded by four open, dry tiles.")
				return
		var obj := {"id": "object_%d_%d" % [Time.get_ticks_usec(), level.objects.size()], "type": "critter" if tool == "seam_worm" else tool, "pos": point, "rotation": 0, "solid": tool in ["pillar", "tree", "emitter"]}
		if tool in ["critter", "seam_worm"]:
			obj.merge({"behavior": "seam_patrol" if tool == "seam_worm" else "wander", "speed": 1.6, "waypoints": []})
		if tool == "seam_worm":
			obj.seam_anchor = [cell.x, cell.y]
		if tool == "emitter":
			obj.interval = 2.5
		if tool in ["car", "patrol_car", "log"]:
			obj.merge({"length": 4.6 if tool == "log" else 1.5, "speed": 1.0, "direction": 1})
		if tool == "patrol_car":
			obj.merge({"axis": "east_west", "waypoints": [], "length": 1.0}, true)
		level.objects.append(obj)
		selection = obj.id
	rebuild()

func refresh_inspector() -> void:
	for child in inspector.get_children():
		inspector.remove_child(child)
		child.queue_free()
	var obj := selected_object()
	if obj.is_empty():
		return
	inspector.add_child(label("SELECTED / " + str(obj.type).to_upper(), 12, LIME))
	var rot := SpinBox.new()
	rot.min_value = 0
	rot.max_value = 270
	rot.step = 90
	rot.suffix = "° rotation"
	rot.value = fposmod(float(obj.get("rotation", 0)), 360)
	rot.value_changed.connect(func(v: float): change_property("rotation", v))
	inspector.add_child(rot)
	if obj.type == "critter":
		var behavior := OptionButton.new()
		behavior.add_item("Wander")
		behavior.add_item("Patrol")
		behavior.select(0 if obj.behavior == "wander" else 1)
		behavior.item_selected.connect(func(i: int): change_property("behavior", "wander" if i == 0 else "patrol"))
		if obj.get("behavior") == "seam_patrol":
			behavior.queue_free()
			paragraph(inspector, "SEAM WORM · Blue with gold bands\nRoute along tile edges; click lower-right corners. Rotate to move around the placement tile.", 12)
		else:
			inspector.add_child(behavior)
		var speed := SpinBox.new()
		speed.min_value = 0.3
		speed.max_value = 5
		speed.step = 0.1
		speed.value = obj.get("speed", 1.6)
		speed.suffix = "speed"
		speed.value_changed.connect(func(v: float): change_property("speed", v))
		inspector.add_child(speed)
		var route_controls := row(inspector)
		var draw_route := button(route_controls, "Draw route", func(): set_tool("route"))
		draw_route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var loop_toggle := CheckBox.new()
		loop_toggle.name = "PatrolLoop"
		loop_toggle.text = "Loop"
		loop_toggle.add_theme_font_size_override("font_size", 12)
		loop_toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		loop_toggle.tooltip_text = "Repeat the route. Off: stop at the last waypoint."
		loop_toggle.button_pressed = obj.get("patrol_loop", true)
		loop_toggle.toggled.connect(func(enabled: bool): change_property("patrol_loop", enabled))
		route_controls.add_child(loop_toggle)
		if obj.get("behavior") != "seam_patrol":
			button(inspector, "North–south loop", make_north_south_loop)
		button(inspector, "Clear route (%d points)" % obj.get("waypoints", []).size(), func(): change_property("waypoints", []))
	if obj.type == "emitter":
		var interval := SpinBox.new()
		interval.min_value = 0.5
		interval.max_value = 10
		interval.step = 0.25
		interval.value = obj.get("interval", 2.5)
		interval.suffix = "sec / shot"
		interval.value_changed.connect(func(v: float): change_property("interval", v))
		inspector.add_child(interval)
		paragraph(inspector, "0° fires north · 90° west\n180° south · 270° east", 11)
	if obj.type in ["car", "patrol_car", "log"]:
		for field in [["length", 1.0, 1.0 if obj.type == "patrol_car" else 6.0, "cells long"], ["speed", 0.3, 4.0, "lane speed"]]:
			var key: String = field[0]
			var value := SpinBox.new()
			value.min_value = field[1]
			value.max_value = field[2]
			value.step = 0.1
			value.value = obj.get(key, 1.5 if key == "length" else 1.0)
			value.suffix = field[3]
			value.value_changed.connect(func(v: float): change_property(key, v))
			inspector.add_child(value)
		var direction_text := "right →" if obj.get("direction", 1) == 1 else "← left"
		if obj.type == "patrol_car":
			direction_text = ("south" if obj.get("direction",1) == 1 else "north") if obj.get("axis") == "north_south" else ("east" if obj.get("direction",1) == 1 else "west")
		button(inspector, "Direction: " + direction_text, func(): change_property("direction", -int(obj.get("direction", 1))))
		if obj.type == "patrol_car":
			var axis_picker := OptionButton.new()
			axis_picker.add_item("East–west")
			axis_picker.add_item("North–south")
			axis_picker.select(1 if obj.get("axis") == "north_south" else 0)
			axis_picker.item_selected.connect(func(i: int): change_property("axis", "east_west" if i == 0 else "north_south"))
			inspector.add_child(axis_picker)
			paragraph(inspector, "Road only · Turns back at walls or road ends. A drawn route overrides the axis.",12)
			button(inspector, "Draw car patrol", func(): set_tool("route"))
			button(inspector, "Clear car route (%d points)" % obj.get("waypoints", []).size(),func(): change_property("waypoints", []))

	if obj.type in ["mushroom", "decoration"]:
		var solid := CheckBox.new()
		solid.text = "Blocks movement"
		solid.button_pressed = obj.get("solid", false)
		solid.toggled.connect(func(v: bool): change_property("solid", v))
		inspector.add_child(solid)
	button(inspector, "Remove object", func():
		record_undo()
		level.objects.erase(obj)
		selection = ""
		rebuild())

func change_property(key: String, value: Variant) -> void:
	var obj := selected_object()
	if obj.is_empty():
		return
	if key == "solid" and value == true and (obj.pos in level.get("checkpoints", []) or obj.pos == level.get("checkpoint", [])):
		status("Move the checkpoint before making this object solid.")
		return
	if key == "rotation" and obj.get("behavior") == "seam_patrol":
		rotate_seam_worm(obj, float(value))
		return
	record_undo()
	obj[key] = value
	rebuild()

func rotate_seam_worm(obj: Dictionary, degrees: float) -> void:
	var anchor: Array = obj.get("seam_anchor", [floori(float(obj.pos[0])), floori(float(obj.pos[1]))])
	var pivot := Vector2(anchor[0], anchor[1])
	var angle := -deg_to_rad(degrees - float(obj.get("rotation", 0)))
	var rotated: Array = []
	for point in [obj.pos] + obj.get("waypoints", []):
		var offset := (Vector2(point[0], point[1]) - pivot).rotated(angle)
		var next := (pivot + offset).snapped(Vector2(0.5, 0.5))
		rotated.append([next.x, next.y])
	var route := rotated.duplicate(true)
	if obj.get("patrol_loop", true) and rotated.size() > 2:
		route.append(rotated[1])
	for i in range(route.size()):
		if not Data.seam_point_open(level, route[i]) or (i > 0 and not Data.seam_segment_open(level, route[i - 1], route[i])):
			refresh_inspector()
			status("Rotation blocked: the worm and route need clear, dry tile seams inside the level.")
			return
	record_undo()
	obj.seam_anchor = anchor.duplicate()
	obj.pos = rotated[0]
	if obj.has("waypoints"):
		obj.waypoints = rotated.slice(1)
	obj.rotation = fposmod(degrees, 360)
	rebuild()

func load_library() -> void:
	var stored: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://library.json")) if FileAccess.file_exists("user://library.json") else []
	if stored is Array:
		for item in stored:
			if item is Dictionary and item.get("id") is String and Data.validate(item.get("level")) == "":
				library.append(Data.normalize(item))

func refresh_library_picker() -> void:
	saved_picker.clear()
	saved_picker.add_item("Load a local level…")
	for item in library:
		saved_picker.add_item(str(item.level.name))

func save_level() -> void:
	commit_name()
	var error := Data.validate(level)
	if not error.is_empty():
		status(error)
		return
	if slot_id.is_empty():
		slot_id = "level_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	var found := false
	for item in library:
		if item.id == slot_id:
			item.level = level.duplicate(true)
			found = true
	if not found:
		library.append({"id": slot_id, "level": level.duplicate(true)})
	var f := FileAccess.open("user://library.pending.json", FileAccess.WRITE)
	if f == null:
		status("Local save failed. Export JSON to keep a portable copy.")
		return
	f.store_string(JSON.stringify(library, "\t"))
	f.close()
	if DirAccess.rename_absolute("user://library.pending.json", "user://library.json") != OK:
		status("Could not finish the local save. Export JSON to keep a backup.")
		return
	refresh_library_picker()
	status("Saved locally: " + level.name + ". Export JSON for a backup outside this browser.")

func duplicate_level() -> void:
	record_undo()
	level = level.duplicate(true)
	level.name = str(level.name).left(72) + " (copy)"
	slot_id = ""
	sync_editor()
	save_level()

func load_saved(index: int) -> void:
	if index > 0:
		load_library_entry(index - 1)
		enter_editor()

func load_library_entry(index: int) -> void:
	campaign_level = false
	level = library[index].level.duplicate(true)
	slot_id = library[index].id
	selection = ""
	undo_stack.clear()
	redo_stack.clear()
	deaths = 0
	sync_editor()

func export_json() -> void:
	commit_name()
	var text := JSON.stringify(level, "\t")
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), level.name.validate_filename() + ".json", "application/json")
		status("Downloaded portable level JSON.")
	else:
		var dialog := FileDialog.new()
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		dialog.add_filter("*.json", "Hopán level")
		dialog.current_file = level.name.validate_filename() + ".json"
		dialog.file_selected.connect(func(path: String):
			status("Exported " + path if Data.save_json(path, level) == OK else "Could not export to that path.")
			dialog.queue_free())
		add_child(dialog)
		dialog.popup_centered_ratio(0.75)

func import_dialog() -> void:
	reset_overlay("Import a level", "Open a JSON file, or paste exported Hopán level JSON below. Importing creates an unsaved copy; your local saves remain available.")
	var text := TextEdit.new()
	text.custom_minimum_size.y = 160
	text.placeholder_text = "Paste version 1 level JSON…"
	overlay_box.add_child(text)
	button(overlay_box, "Import pasted JSON", func(): import_text(text.text), true)
	button(overlay_box, "Open JSON file", open_import_file)
	button(overlay_box, "Cancel", func(): overlay.hide())

func open_import_file() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""(function(){const input=document.createElement('input');input.type='file';input.accept='.json,application/json';input.onchange=()=>{const f=input.files[0];if(!f)return;if(f.size>2000000){window.hopanImportError='File is too large (2 MB maximum).';return;}const r=new FileReader();r.onload=()=>window.hopanImported=r.result;r.readAsText(f);};input.click();})();""", true)
	else:
		var dialog := FileDialog.new()
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.add_filter("*.json", "Hopán level")
		dialog.file_selected.connect(func(path: String): import_text(FileAccess.get_file_as_string(path)); dialog.queue_free())
		add_child(dialog)
		dialog.popup_centered_ratio(0.75)

func import_text(text: String) -> bool:
	if text.length() > 2000000:
		status("File is too large (2 MB maximum).")
		return false
	var data: Variant = JSON.parse_string(text)
	var error := Data.validate(data)
	if not error.is_empty():
		status(error)
		# Show the error inside the dialog, too.
		paragraph(overlay_box, error)
		return false
	record_undo()
	level = Data.normalize(data)
	slot_id = ""
	selection = ""
	enter_editor()
	status("Imported " + str(level.name) + ". Save to keep a local copy.")
	return true

func new_level(theme_name: String = "egypt") -> void:
	record_undo()
	level = Data.blank("My magnificent maze", theme_name, 21 if size_picker.selected == 1 else 17, 16 if size_picker.selected == 1 else 13)
	slot_id = ""
	selection = ""
	enter_editor()

func reset_touch() -> void:
	thumb = Vector2.ZERO
	touch_index = -1
	if is_instance_valid(touch_knob):
		touch_knob.position = Vector2(42, 42)

func _process(delta: float) -> void:
	if not is_instance_valid(world) or level.is_empty():
		return
	if browser_test:
		probe_timer += delta
		if probe_timer > 0.2:
			probe_timer = 0
			publish_browser_probe()
	if view_container.size != last_view_size or view.size != last_render_size:
		last_view_size = view_container.size
		last_render_size = view.size
		configure_view()
		world.fit_camera()
	update_result_presentation()
	update_announcements(delta)
	level_banner.visible = mode in ["play", "test"] and not world.map_view and not overlay.visible
	level_banner.text = ("EXIT PREVIEW · MAP TO SKIP" if mobile_ui else "EXIT PREVIEW · SPACE TO SKIP") if world.intro_active else str(level.name).to_upper()
	level_banner.position = view_container.global_position + Vector2(0, 10)
	level_banner.size = Vector2(view_container.size.x, 38)
	var focused := get_viewport().gui_get_focus_owner()
	var typing := focused is LineEdit or focused is TextEdit
	var movement := Vector2.ZERO
	if mode in ["play", "test"] and not overlay.visible and not typing and not world.map_view:
		movement = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		if thumb.length() > 0.05:
			movement = thumb
	world.input_vector = movement.limit_length()
	time_label.text = "%.1fs  /  %d croaks" % [world.elapsed, deaths] if mode in ["play", "test"] else "%d × %d · v1 JSON" % [level.width, level.height]
	if mode == "edit" and not overlay.visible:
		var local := viewport_position(get_global_mouse_position())
		var cell: Vector2i = world.pick(local)
		world.show_cursor(cell if view_container.get_global_rect().has_point(get_global_mouse_position()) else Vector2i(-1, -1))
	if OS.has_feature("web"):
		poll_timer += delta
		if poll_timer > 0.3:
			poll_timer = 0
			resize_mobile_ui()
			var imported: Variant = JavaScriptBridge.eval("window.hopanImported || ''", true)
			if imported is String and not imported.is_empty():
				JavaScriptBridge.eval("window.hopanImported = ''", true)
				import_text(imported)
			var error: Variant = JavaScriptBridge.eval("window.hopanImportError || ''", true)
			if error is String and not error.is_empty():
				paragraph(overlay_box, error)
				JavaScriptBridge.eval("window.hopanImportError = ''", true)
			if bool(JavaScriptBridge.eval("document.hidden", true)) and world.active and not paused and not overlay.visible:
				toggle_pause()

func resize_mobile_ui() -> void:
	if not mobile_ui:
		return
	var desired := DisplayServer.window_get_size()
	if OS.has_feature("web"):
		desired = Vector2i(int(JavaScriptBridge.eval("window.innerWidth", true)), int(JavaScriptBridge.eval("window.innerHeight", true)))
	if desired.x > 0 and desired.y > 0 and get_window().content_scale_size != desired:
		get_window().content_scale_size = desired
		if is_instance_valid(overlay_panel):
			overlay_panel.custom_minimum_size.x = minf(560, desired.x - 24)

func publish_browser_probe() -> void:
	# Read-only diagnostics in explicitly requested debug exports. Browser tests
	# still interact through actual mouse, keyboard and touch events.
	var buttons: Array = []
	for node in find_children("*", "Button", true, false):
		if node.is_visible_in_tree() and (not overlay.visible or overlay.is_ancestor_of(node)):
			var rect: Rect2 = node.get_global_rect()
			buttons.append({"text": node.text, "x": rect.get_center().x, "y": rect.get_center().y})
	var cells: Array = []
	for z in range(int(level.height)):
		var cell_row: Array = []
		for x in range(int(level.width)):
			var p: Vector2 = world.camera.unproject_position(world.cell_position([x, z])) * view_container.size / Vector2(view.size) + view_container.global_position
			cell_row.append([p.x, p.y])
		cells.append(cell_row)
	var state := {"mode": mode, "overlay": overlay.visible, "paused": paused, "result": world.result, "elapsed": world.elapsed, "deaths": deaths,
		"campaign_set": campaign_set, "completed_bonus_stages": completed_bonus_stages, "human_set_unlocked": human_set_unlocked(), "completed_human_stages": completed_human_stages,
		"hat": hat, "unlocked_hats": unlocked_hats, "completed_stages": completed_stages, "checkpoint": checkpoint_spawn, "stage": builtin_index,
		"player": [world.player.position.x, world.player.position.z], "map": level, "buttons": buttons, "cells": cells,
		"ui_size": [size.x, size.y], "saved": library.size(), "tool": tool, "selection": selection, "fps": Engine.get_frames_per_second(),
		"voice_history": voice.history, "voice_playing": voice.player.playing, "voice_queue": voice.queue, "voice_gesture": voice.gesture_received, "sound_enabled": sound_enabled, "begin_pending": begin_pending, "return_warning_armed": return_warning_armed,
		"exit_preview": exit_preview, "intro_active": world.intro_active, "intro_time": world.intro_time, "result_time": world.result_time,
		"camera_target": [world.camera_target.x, world.camera_target.y, world.camera_target.z], "pose_y": world.player.visual.position.y,
		"compatibility_mode": compatibility_mode, "map_view": world.map_view, "projection": world.camera.projection, "render_size": [view.size.x, view.size.y], "retro": view_container.material != null}
	JavaScriptBridge.eval("window.hopanState = " + JSON.stringify(state), true)

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) and event.is_pressed():
		voice.unlock()
	if not is_instance_valid(world):
		return
	if world.intro_active and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		world.cancel_exit_preview()
		get_viewport().set_input_as_handled()
		return
	var focused := get_viewport().gui_get_focus_owner()
	if event is InputEventKey and event.pressed and not event.echo and not (focused is LineEdit or focused is TextEdit):
		if event.keycode == KEY_ESCAPE:
			if mode in ["play", "test"]:
				toggle_pause()
			elif overlay.visible:
				overlay.hide()
			else:
				show_menu()
		if mode in ["play", "test"] and event.keycode == KEY_R:
			retry()
		if mode in ["play", "test"] and event.keycode == KEY_M:
			toggle_map()
		if mode == "edit" and not overlay.visible:
			if event.ctrl_pressed or event.meta_pressed:
				if event.keycode == KEY_Z:
					redo() if event.shift_pressed else undo()
				elif event.keycode == KEY_Y:
					redo()
				elif event.keycode == KEY_S:
					save_level()
			elif event.keycode == KEY_SPACE:
				playtest()
			elif event.keycode == KEY_R and not selected_object().is_empty():
				change_property("rotation", fposmod(float(selected_object().get("rotation", 0)) + 90, 360))
	if event is InputEventScreenTouch and mode in ["play", "test"] and not overlay.visible and not world.map_view:
		if event.pressed and touch_index == -1 and event.position.x < size.x * 0.5:
			touch_index = event.index
			touch_origin = event.position
			joystick.global_position = touch_origin - Vector2(69, 69)
			joystick.show()
		elif event.index == touch_index and not event.pressed:
			reset_touch()
	if event is InputEventScreenDrag and event.index == touch_index:
		thumb = ((event.position - touch_origin) / 52).limit_length()
		touch_knob.position = Vector2(42, 42) + thumb * 42
	if mode != "edit" or overlay.visible:
		return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			if not event.pressed:
				stroke = false
				last_cell = Vector2i(-1, -1)
			elif view_container.get_global_rect().has_point(event.position):
				stroke = true
				stroke_changed = false
				last_cell = world.pick(viewport_position(event.position))
				edit_cell(last_cell, event.button_index == MOUSE_BUTTON_RIGHT)
	elif event is InputEventMouseMotion and stroke and view_container.get_global_rect().has_point(event.position):
		var cell: Vector2i = world.pick(viewport_position(event.position))
		if cell != last_cell and tool not in ["select", "route", "spawn", "exit"]:
			last_cell = cell
			edit_cell(cell, Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))

func start_announcements(restarting: bool = false) -> void:
	voice.clear()
	begin_pending = true
	announcement_time = 0.0
	return_warning_armed = false
	previous_voice_row = world.position_cell(world.player.position).y
	if restarting or not campaign_level or mode != "play":
		return
	if campaign_set == "baby":
		voice.say("baby_mode")
		if builtin_index == 3:
			voice.say("traffic_start")
	elif campaign_set == "human":
		if builtin_index == 1:
			voice.say("gloopbutt")
		elif builtin_index == 3:
			voice.say("frogbutt")

func update_announcements(delta: float) -> void:
	if mode not in ["play", "test"] or not world.active or world.halted or world.map_view or overlay.visible:
		return
	announcement_time += delta
	if begin_pending and announcement_time >= 1.0 and not world.intro_active and not voice.busy():
		begin_pending = false
		voice.say("begin")
	if world.intro_active or not campaign_level or campaign_set != "baby" or builtin_index != 3:
		return
	var current_row: int = world.position_cell(world.player.position).y
	# Final road occupies rows 7–9; row 10 is its near safe bank.
	if current_row >= 7 and current_row <= 9:
		return_warning_armed = true
	if return_warning_armed and previous_voice_row <= 9 and current_row >= 10:
		return_warning_armed = false
		voice.say("traffic_return")
	previous_voice_row = current_row

func make_north_south_loop() -> void:
	var obj := selected_object()
	if mode != "edit" or obj.is_empty() or obj.type != "critter":
		return
	var x := int(obj.pos[0])
	var north := int(obj.pos[1])
	var south := north
	while patrol_cell_open(Vector2i(x, north - 1)):
		north -= 1
	while patrol_cell_open(Vector2i(x, south + 1)):
		south += 1
	if north == south:
		status("No open north–south route here. Draw waypoints around obstacles instead.")
		return
	record_undo()
	obj.behavior = "patrol"
	obj.patrol_loop = true
	obj.waypoints = [[x, north], [x, south]]
	rebuild()
	status("North–south loop set. The worm repeats between the two clear endpoints.")

func patrol_cell_open(cell: Vector2i) -> bool:
	if not world.inside(cell) or level.tiles[cell.y][cell.x] in ["wall", "cheese_wall", "water"] or [cell.x, cell.y] in [level.spawn, level.exit]:
		return false
	for obj in level.objects:
		if obj.pos == [cell.x, cell.y] and (obj.type in ["pillar", "tree", "emitter"] or obj.get("solid", false)):
			return false
	return true

func paths_for_set(set_key: String) -> Array:
	match set_key:
		"baby": return BUILTINS
		"human": return HUMAN_LEVELS
		"bonus": return BONUS_LEVELS
	return []

func progress_for_set(set_key: String = "") -> Array:
	match campaign_set if set_key.is_empty() else set_key:
		"human": return completed_human_stages
		"bonus": return completed_bonus_stages
	return completed_stages

func set_start_index(set_key: String) -> int:
	var paths := paths_for_set(set_key)
	var progress := progress_for_set(set_key)
	if progress.is_empty() or progress.size() >= paths.size():
		return 0
	return int(last_cleared_stages.get(set_key, progress[-1]))

func add_set_selector(set_key: String, difficulty: String) -> void:
	var header := row(overlay_box)
	var main_button := button(header, str(SET_TITLES[set_key]), func(): play_builtin(set_start_index(set_key), set_key), set_key == "baby")
	main_button.name = "Set_" + set_key
	main_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_button.add_theme_font_size_override("font_size", 17 if mobile_ui else 20)
	main_button.tooltip_text = "Replay your most recent clear; a complete set restarts from stage 1."
	var expand := button(header, "+", func(): pass)
	expand.name = "Expand_" + set_key
	expand.custom_minimum_size.x = 44
	expand.tooltip_text = "Choose a stage in " + str(SET_TITLES[set_key])
	paragraph(overlay_box, difficulty, 12)
	var stages := VBoxContainer.new()
	stages.name = "Stages_" + set_key
	stages.add_theme_constant_override("separation", 5)
	overlay_box.add_child(stages)
	stages.hide()
	expand.pressed.connect(func():
		stages.visible = not stages.visible
		expand.text = "-" if stages.visible else "+")
	var paths := paths_for_set(set_key)
	for i in range(paths.size()):
		var index := i
		var stage := Data.load_json(paths[i])
		if not stage.is_empty():
			button(stages, "Play · " + str(stage.name), func(): play_builtin(index, set_key))
