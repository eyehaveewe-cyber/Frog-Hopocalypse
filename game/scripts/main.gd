extends Control
const Data = preload("res://scripts/level_data.gd")
const LibrarySafety = preload("res://scripts/library_safety.gd")
const LibraryCompat = preload("res://scripts/library_compat.gd")
const LibraryMerge = preload("res://scripts/library_merge.gd")
const LibraryMirror = preload("res://scripts/library_mirror.gd")
const World = preload("res://scripts/world.gd")
const Voice = preload("res://scripts/voice.gd")
const HopAudio = preload("res://scripts/hop_audio.gd")
var hop_audio: Node
var hop_volume_slider: HSlider
var hop_animation_button: Button
var hop_palette_button: Button
var voice: Node
var sound_enabled := true
var skin := "green"
var skin_button: Button
var sound_button: Button
var menu_sound_toggle: CheckButton
var begin_pending := false
var announcement_time := 0.0
var return_warning_armed := false
var previous_voice_row := 19
const MAZES = ["res://levels/moonlit_oasis.json", "res://levels/pharaohs_courtyard.json", "res://levels/violet_mire.json"]
const BUILTINS = ["res://levels/moonlit_oasis.json", "res://levels/pharaohs_courtyard.json", "res://levels/violet_mire.json", "res://levels/little_frog_crossing.json"]
const HUMAN_TITLE = "Not as Hard as It Looks"
const HUMAN_LEVELS = ["res://levels/not_as_hard/Hardbutt.json", "res://levels/not_as_hard/Gloopbutt.json", "res://levels/not_as_hard/Treebutt.json", "res://levels/not_as_hard/Frogbutt.json"]
const TILE_LEVELS = ["res://levels/tile_hop/big_hop_boulevard.json", "res://levels/tile_hop/your_move_crossing.json", "res://levels/tile_hop/shardwater_sanctuary.json", "res://levels/tile_hop/seed_vault.json", "res://levels/tile_hop/twenty_five_terraces.json"]
const MOVE_DEMO = "res://levels/bonus/your_move_hopan.json"
const BONUS_LEVELS = ["res://levels/bonus/Shelby.json", MOVE_DEMO, "res://levels/bonus/Cramerton.json"]
const SYNC_LEVELS = ["res://levels/your_move/one_step_ahead.json", "res://levels/your_move/needle_clock.json", "res://levels/your_move/shard_switchyard.json", "res://levels/your_move/stillwater_circuit.json", "res://levels/your_move/rush_hourglass.json"]
const NYC_LEVELS = ["res://levels/nyc_01_central_park.json", "res://levels/nyc_02_brownstone_blocks.json", "res://levels/nyc_03_east_river_piers.json", "res://levels/nyc_04_broadway.json", "res://levels/nyc_05_midtown_rush_hour.json", "res://levels/nyc_06_brooklyn_skate_circle.json"]
const STREETLIFE_LEVELS = ["res://levels/streetlife_01_stoop_patrol.json", "res://levels/streetlife_02_newsstand_weave.json", "res://levels/streetlife_03_ferry_railwalk.json", "res://levels/streetlife_04_banked_boulevard.json", "res://levels/streetlife_05_sanitation_courts.json", "res://levels/streetlife_06_block_party.json"]
const JOURNEY_LEVELS = ["res://levels/city_journey_01_blocks_park.json", "res://levels/city_journey_02_skate_escape.json", "res://levels/city_journey_03_frozen_blocks.json"]
var city_progress := {"nyc": [], "streetlife": [], "city_journey": []}
const SET_TITLES = {"baby": "Baby Mode", "human": HUMAN_TITLE, "bonus": "Bonus", "tile": "Tile Hop", "sync": "Moves When You Move", "nyc": "New York City", "streetlife": "NYC Streetlife", "city_journey": "City Journey"}
const HAT_NAMES = {"none": "No hat", "pharaoh": "Pharaoh headdress", "baby": "Baby frog hat", "hourglass": "Hourglass pyramid hat", "morning": "Morning suit + top hat"}
const INK = Color("f7f0d8")
const MUTED = Color("b7c8b9")
const LIME = Color("d5ec8d")
var world: Node3D
var view: SubViewport
var view_container: SubViewportContainer
var sidebar: PanelContainer
var overlay: Control
var overlay_panel: PanelContainer
var overlay_layout: MarginContainer
var overlay_shade: ColorRect
var splash_art: TextureRect
var splash_menu = false
const LevelRules = preload("res://scripts/level_rules.gd")
const RULE_INK = preload("res://art/rules/hopan-rule-ink.ttf")
const LandmarkModels = preload("res://scripts/landmark_models.gd")
const SCENERY_DEMOS = ["res://levels/scenery/temple_shore.json", "res://levels/scenery/heron_marsh.json", "res://levels/scenery/temple_horizon_1x.json", "res://levels/scenery/temple_horizon_80x.json", "res://levels/scenery/courtyard_gardens.json", "res://levels/scenery/jungle_river.json"]
const CHARGE_DEMO = "res://levels/tile_hop/charge_trial.json"
var return_editor_button: Button
var rule_button: Button
var hop_rule_picker: OptionButton
var hop_charge_picker: SpinBox
var seen_rule_ids: Array = []
var pending_rule_ids: Array = []
var rule_notice_open = false
var rule_previous_halt = false
var rule_notices_enabled = true
const SPLASH_WIDE = preload("res://art/splash/hopan-wide.png")
const SPLASH_COMPACT = preload("res://art/splash/hopan-compact.png")
const SPLASH_PORTRAIT = preload("res://art/splash/hopan-portrait.png")
const SPLASH_LAYERED_WIDE = preload("res://art/splash/hopan-layered-wide.png")
const SPLASH_LAYERED_COMPACT = preload("res://art/splash/hopan-layered-compact.png")
const SPLASH_LAYERED_PORTRAIT = preload("res://art/splash/hopan-layered-portrait.png")
const SPLASH_ALTERNATE_CHANCE := 0.15
var splash_variant := "wrapped"
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
var themed_tool_buttons: Dictionary = {}
var saved_picker: OptionButton
var tool_label: Label
var inspector: VBoxContainer
var undo_button: Button
var redo_button: Button
var level: Dictionary = {}
var library: Array = []
var library_safety_error := ""
var library_opaque: Array = []
var library_mirror_seen: Variant = null
var library_mirror_state: Variant = null
var library_mirror_used := false
var slot_id := ""
var editor_saved_snapshot: Dictionary = {}
var pending_editor_navigation: Callable
var editor_leave_open := false
var editor_session_active := false
var last_browser_unsaved := false
var editor_navigation_bypass := false
var editor_change_counts: Dictionary = {}
var editor_autosave_due := false
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
var completed_tile_stages: Array = []
var completed_sync_stages: Array = []
var long_hop_button: Button
var brake_button: Button
var grind_button: Button
var skate_grind_touch := false
var skate_jump_touch := false
var skate_brake_touch := false
var long_hop_indicator: Label
var long_hop_help: Label
var checkpoint_hop_state: Dictionary = {}
var tile_mode_toggle: CheckButton
var movement_toggle: CheckButton
var draw_distance_picker: SpinBox
var last_cleared_stages: Dictionary = {}
var campaign_set := "baby"
var campaign_level := false
var checkpoint_spawn: Array = []
var checkpoint_history: Array = []
var hat_button: Button
var restart_confirmation_open := false
var paused := false
var ui_busy := false
var last_view_size := Vector2.ZERO
var last_render_size := Vector2i.ZERO
var thumb := Vector2.ZERO
var touch_index := -1
var tile_touch_queued := false
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
	choose_splash_variant()
	make_theme()
	load_profile()
	voice = Voice.new()
	add_child(voice)
	voice.set_enabled(sound_enabled)
	hop_audio = HopAudio.new()
	add_child(hop_audio)
	hop_audio.set_enabled(sound_enabled)
	library_safety_error = LibrarySafety.protect("user://library.json", "user://nyc-library.json")
	if OS.has_feature("web") and library_safety_error.is_empty():
		library_safety_error = LibraryMirror.protect_nyc("user://nyc-library.json")
	load_library()
	import_city_library()
	build_ui()
	load_builtin(0)
	show_menu()
	if not library_safety_error.is_empty():
		status(library_safety_error)
		paragraph(overlay_box, library_safety_error)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.hopanEditorUnsaved=false;window.addEventListener('beforeunload',function(e){if(window.hopanEditorUnsaved){e.preventDefault();e.returnValue='';}});",true)
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
	long_hop_button = button(self, "Long hop", activate_long_hop)
	long_hop_button.add_theme_font_size_override("font_size",13)
	long_hop_button.toggle_mode = true
	long_hop_button.button_down.connect(func():
		if level.get("city_journey",{}).get("movement") == "skate": skate_jump_touch = true)
	long_hop_button.button_up.connect(func(): skate_jump_touch = false)
	long_hop_button.tooltip_text = "Tap or press Space, then choose a direction. Shift + direction also works."
	long_hop_button.focus_mode = Control.FOCUS_NONE
	long_hop_button.custom_minimum_size = Vector2(166,64)
	long_hop_help = label("",12,LIME)
	long_hop_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	long_hop_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	long_hop_help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	long_hop_help.add_theme_color_override("font_outline_color",Color("14243a"))
	long_hop_help.add_theme_constant_override("outline_size",4)
	add_child(long_hop_help)
	# Large thumb target below the view; empty taps explain the current rule.
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style: StyleBox = long_hop_button.get_theme_stylebox(state).duplicate()
		style.content_margin_top = 3
		style.content_margin_bottom = 19
		long_hop_button.add_theme_stylebox_override(state, style)
	long_hop_indicator = label("READY", 10, LIME)
	long_hop_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	long_hop_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	long_hop_button.add_child(long_hop_indicator)
	long_hop_indicator.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	long_hop_indicator.offset_top = -18
	long_hop_indicator.offset_bottom = -2
	long_hop_button.hide()
	brake_button = button(self, "Brake · Shift", func(): pass)
	brake_button.focus_mode = Control.FOCUS_NONE
	brake_button.button_down.connect(func(): skate_brake_touch = true)
	brake_button.button_up.connect(func(): skate_brake_touch = false)
	brake_button.hide()
	grind_button = button(self,"Grind · G",func(): pass)
	grind_button.focus_mode = Control.FOCUS_NONE
	grind_button.button_down.connect(func(): skate_grind_touch = true)
	grind_button.button_up.connect(func(): skate_grind_touch = false)
	grind_button.hide()
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
	for title in Data.THEME_NAMES:
		theme_picker.add_item(title)
	theme_picker.item_selected.connect(change_theme)
	tools.add_child(theme_picker)
	size_picker = OptionButton.new()
	size_picker.add_item("Standard · 17 × 13")
	size_picker.add_item("Large · 21 × 16 · +52% area")
	size_picker.add_item("Tour · 33 × 49")
	size_picker.tooltip_text = "Size for the next new maze. Your current level stays intact."
	tools.add_child(size_picker)
	tile_mode_toggle = CheckButton.new()
	tile_mode_toggle.text = "Tile-hop mode"
	tile_mode_toggle.tooltip_text = "Cardinal tile movement for the frog, enemies, cars, logs and darts."
	tile_mode_toggle.toggled.connect(func(value: bool): set_level_rule("game_mode", "tile" if value else "hopan"))
	tools.add_child(tile_mode_toggle)
	movement_toggle = CheckButton.new()
	movement_toggle.text = "Move with me"
	movement_toggle.tooltip_text = "Hazards advance only with your movement. Works in both modes."
	movement_toggle.toggled.connect(func(value: bool): set_level_rule("move_with_me",value))
	tools.add_child(movement_toggle)
	tools.add_child(label("Level rules", 13, LIME))
	hop_rule_picker = OptionButton.new()
	hop_rule_picker.add_item("Free long hops")
	hop_rule_picker.add_item("Charged long hops")
	hop_rule_picker.add_item("Fragment long hops · 3 pieces")
	hop_rule_picker.add_item("Power-up long hops · Hop seed")
	hop_rule_picker.item_selected.connect(func(index: int): change_hop_rule("long_hop", ["free","charged","fragments","powerup"][index]))
	tools.add_child(hop_rule_picker)
	hop_charge_picker = SpinBox.new()
	hop_charge_picker.min_value = 1
	hop_charge_picker.max_value = 25
	hop_charge_picker.step = 1
	hop_charge_picker.value = 10
	hop_charge_picker.suffix = "short hops to recharge"
	hop_charge_picker.value_changed.connect(func(value: float): change_hop_rule("charge_hops", int(value)))
	tools.add_child(hop_charge_picker)

	draw_distance_picker = SpinBox.new()
	draw_distance_picker.min_value = 10
	draw_distance_picker.max_value = 30
	draw_distance_picker.step = 1
	draw_distance_picker.suffix = "tiles visible"
	draw_distance_picker.value_changed.connect(func(value: float): set_level_rule("draw_distance",value))
	tools.add_child(draw_distance_picker)
	var background_toggle := CheckButton.new()
	background_toggle.text = "Background view"
	background_toggle.tooltip_text = "Zoom out to place landmarks in the surrounding water."
	background_toggle.toggled.connect(func(value: bool):
		world.background_view = value
		world.fit_camera())
	tools.add_child(background_toggle)
	button(tools, "Scenery demos", show_scenery_demos)
	button(tools, "Movement demos", show_movement_demos)
	var new_row := row(tools)
	button(new_row, "New Egypt", func(): new_level("egypt"))
	button(new_row, "New Swamp", func(): new_level("swamp"))
	button(tools, "New Mexico", func(): new_level("mexico"))
	button(tools, "New Honduras", func(): new_level("honduras"))
	button(tools, "New NYC", func(): new_level("nyc"))
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
	for entry in [["floor", "Floor"], ["path", "Path"], ["wall", "Wall"], ["cheese_wall", "Cheese wall"], ["water", "Water"], ["road", "Road"], ["car", "Car"], ["patrol_car", "Patrol car"], ["log", "Log"], ["spawn", "Frog start"], ["exit", "Exit gate"], ["checkpoint", "Checkpoint"], ["hop_fragment", "Hop fragment"], ["hop_seed", "Hop seed"], ["pillar", "Pillar"], ["tree", "Tree"], ["mushroom", "Mushroom"], ["decoration", "Pot"], ["landmark_sphinx", "Sphinx"], ["landmark_osiris", "Osiris statue"], ["landmark_pyramid", "Pyramid"], ["landmark_moss_tree", "Moss tree"], ["landmark_heron", "Heron"], ["backdrop", "Distant backdrop"], ["critter", "Critter"], ["roach", "Roach"], ["skater", "Skater"], ["city_prop", "Street prop"], ["seam_worm", "Seam worm"], ["spike_ball", "Spike ball"], ["emitter", "Dart trap"], ["select", "Select"], ["erase", "Erase"], ["route", "Patrol route"]]:
		var key: String = entry[0]
		var b := button(palette, entry[1], func(): set_tool(key))
		if key in ["tree", "pillar", "decoration"]: themed_tool_buttons[key] = b
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
	world.hint_changed.connect(status)
	world.hop_started.connect(func(big: bool):
		long_hop_button.set_pressed_no_signal(false)
		hop_audio.play_event("takeoff", voice.busy(), big))
	world.hop_landed.connect(func(_big: bool): hop_audio.play_event("landing", voice.busy()))
	world.checkpoint_reached.connect(func(point: Array):
		checkpoint_spawn = point.duplicate()
		checkpoint_hop_state = world.tile_rules.checkpoint_state() if world.tile_rules != null else {}
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
	move_child(long_hop_button, get_child_count()-1)
	move_child(long_hop_help, get_child_count()-1)
	move_child(brake_button, get_child_count()-1)
	move_child(grind_button, get_child_count()-1)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	splash_art = TextureRect.new()
	splash_art.texture = SPLASH_WIDE
	splash_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	splash_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	splash_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	splash_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_art.hide()
	overlay.add_child(splash_art)
	var shade := ColorRect.new()
	overlay_shade = shade
	shade.color = Color(0.025, 0.07, 0.055, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var overlay_scroll := ScrollContainer.new()
	overlay_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(overlay_scroll)
	var align := MarginContainer.new()
	overlay_layout = align
	align.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	align.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_scroll.add_child(align)
	overlay_panel = PanelContainer.new()
	overlay_panel.custom_minimum_size.x = minf(560, get_window().content_scale_size.x - 24) if mobile_ui else 560
	overlay_panel.add_theme_stylebox_override("panel", panel_style(Color("193a2e"), 16))
	overlay_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	overlay_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	align.add_child(overlay_panel)
	overlay_box = VBoxContainer.new()
	overlay_box.add_theme_constant_override("separation", 8 if mobile_ui else 14)
	margin(overlay_panel, 16 if mobile_ui else 28).add_child(overlay_box)
	build_joystick()
	return_editor_button = button(self, "Back to editor", return_to_editor)
	return_editor_button.name = "ReturnToEditor"
	return_editor_button.custom_minimum_size = Vector2(180, 44)
	return_editor_button.tooltip_text = "End this playtest and return to your level. Unsaved edits are kept."
	return_editor_button.hide()
	rule_button = button(self, "Rules", func(): show_level_rules(false))
	rule_button.custom_minimum_size = Vector2(72, 44)
	rule_button.tooltip_text = "Level rules · F1"
	for state in ["normal", "hover", "pressed", "focus"]:
		var rule_style := panel_style(Color(0.03, 0.10, 0.09, 0.42 if state == "normal" else 0.9), 4)
		rule_style.border_color = Color(0.85, 0.95, 0.7, 0.7)
		rule_button.add_theme_stylebox_override(state, rule_style)
	rule_button.hide()
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

static func splash_variant_for(roll: float, forced: String = "") -> String:
	if forced == "4":
		return "layered"
	if forced == "6":
		return "wrapped"
	return "layered" if roll < SPLASH_ALTERNATE_CHANCE else "wrapped"

func choose_splash_variant() -> void:
	# One cosmetic roll per launch; never consume gameplay/voice RNG or save it.
	var forced := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--splash="):
			forced = argument.trim_prefix("--splash=")
	if OS.has_feature("web"):
		forced = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('splash') || ''", true))
	var cosmetic_rng := RandomNumberGenerator.new()
	cosmetic_rng.randomize()
	splash_variant = splash_variant_for(cosmetic_rng.randf(), forced)

func configure_splash_layout() -> void:
	if not is_instance_valid(splash_art):
		return
	var viewport_size := get_window().content_scale_size
	var portrait := viewport_size.y > viewport_size.x
	if splash_variant == "layered":
		splash_art.texture = SPLASH_LAYERED_PORTRAIT if portrait else (SPLASH_LAYERED_COMPACT if mobile_ui else SPLASH_LAYERED_WIDE)
	else:
		splash_art.texture = SPLASH_PORTRAIT if portrait else (SPLASH_COMPACT if mobile_ui else SPLASH_WIDE)
	var edge := 12 if mobile_ui else 32
	for side in ["left", "right", "bottom"]:
		overlay_layout.add_theme_constant_override("margin_" + side, edge if splash_menu else 0)
	overlay_layout.add_theme_constant_override("margin_top", int(viewport_size.y * 0.47) if splash_menu and portrait else (edge if splash_menu else 0))
	overlay_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if not splash_menu or portrait else Control.SIZE_SHRINK_END
	overlay_panel.custom_minimum_size.x = minf(500 if splash_menu else 560, viewport_size.x - edge * 2)

func reset_overlay(title: String, subtitle: String = "") -> void:
	skin_button = null
	hop_animation_button = null
	hop_palette_button = null
	hop_volume_slider = null
	restart_confirmation_open = false
	rule_notice_open = false
	splash_menu = false
	splash_art.hide()
	overlay_shade.color = Color(0.025, 0.07, 0.055, 0.82)
	overlay_panel.add_theme_stylebox_override("panel", panel_style(Color("193a2e"), 16))
	configure_splash_layout()
	for child in overlay_box.get_children():
		overlay_box.remove_child(child)
		child.queue_free()
	if not title.is_empty():
		overlay_box.add_child(label("H O P O C A L Y P S E", 12, LIME))
		var heading := label(title, 26 if mobile_ui else 36)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		overlay_box.add_child(heading)
	if not subtitle.is_empty():
		paragraph(overlay_box, subtitle)
	overlay.show()
	reset_touch()

func show_menu() -> void:
	if request_editor_navigation(show_menu): return
	editor_session_active = false
	hop_audio.clear()
	begin_pending = false
	voice.clear()
	world.halted = true
	edit_button.hide()
	reset_overlay("")
	splash_menu = true
	splash_art.show()
	overlay_shade.color = Color(0, 0, 0, 0)
	var menu_style := panel_style(Color(0.035, 0.10, 0.12, 0.93), 12)
	menu_style.border_color = Color(0.72, 0.70, 0.43, 0.35)
	overlay_panel.add_theme_stylebox_override("panel", menu_style)
	configure_splash_layout()
	overlay_box.add_child(label("P H A R A O H   F R O G", 14, Color("e1c786")))
	var title := label("Hopán", 54 if mobile_ui else 72, Color("f2dc9b"))
	title.add_theme_color_override("font_shadow_color", Color("142f34"))
	title.add_theme_constant_override("shadow_offset_y", 3)
	overlay_box.add_child(title)
	button(overlay_box, "Play Baby Mode", func(): play_builtin(set_start_index("baby"),"baby"), true)
	button(overlay_box, "Levels", show_levels)
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
	button(overlay_box, "Hop feel comparison", show_hop_comparison)
	button(overlay_box, "Level editor · Create a maze", func(): enter_editor())
	skin_button = button(overlay_box, "Skin: " + skin.replace("_", " ").capitalize(), toggle_skin)
	skin_button.tooltip_text="Clear 2/4/6/8/10 distinct levels for orange, yellow, spotted, white-bellied purple and gummy. Six also earns the morning suit."
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
			editor_session_active = mode in ["edit", "test"]
			overlay.hide()
			world.halted = false
			paused = false
			edit_button.visible = mode == "edit"
			joystick.visible = mobile_ui and mode in ["play", "test"])
	paragraph(overlay_box, "WASD / arrows · touch joystick on mobile\nM: overhead map   R: retry   Esc: pause", 12)
	# Keep keyboard traversal within the visible splash actions, rather than
	# tabbing to the obscured gameplay header or editor controls underneath.
	var controls := overlay_box.find_children("*", "BaseButton", true, false)
	for i in range(controls.size()):
		controls[i].focus_next = controls[i].get_path_to(controls[(i + 1) % controls.size()])
		controls[i].focus_previous = controls[i].get_path_to(controls[(i - 1 + controls.size()) % controls.size()])
	if not controls.is_empty():
		call_deferred("focus_splash_action")
	joystick.hide()

func show_levels() -> void:
	reset_overlay("Levels", "Start with Baby Mode, or choose a level set below.")
	button(overlay_box,"Back",show_menu)
	for key in SET_TITLES:
		var locked: bool = (key == "human" and not human_set_unlocked()) or (key in ["tile","sync"] and not tile_mode_unlocked())
		if locked:
			paragraph(overlay_box,str(SET_TITLES[key])+" · Complete "+("Baby Mode" if key == "human" else HUMAN_TITLE)+" to unlock.")
		else:
			var description := "%d levels · %d cleared" % [paths_for_set(key).size(),progress_for_set(key).size()]
			if key in ["nyc", "streetlife"]:
				description += " · timing & route planning"
			elif key == "city_journey":
				description += " · City & park → Frozen Blocks → Skate Escape"
			add_set_selector(key, description)
	joystick.hide()

func focus_splash_action() -> void:
	# A menu can be replaced before the deferred layout pass completes.
	if not splash_menu or not overlay.visible or not is_inside_tree():
		return
	var controls := overlay_box.find_children("*", "BaseButton", true, false)
	if not controls.is_empty() and controls[0].is_visible_in_tree():
		controls[0].grab_focus()

func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	voice.set_enabled(enabled)
	if is_instance_valid(hop_audio): hop_audio.set_enabled(enabled)
	if is_instance_valid(sound_button):
		sound_button.text = "Sound: On" if enabled else "Sound: Off"
	if is_instance_valid(menu_sound_toggle):
		menu_sound_toggle.set_pressed_no_signal(enabled)
	save_profile()

func tile_mode_unlocked() -> bool:
	return completed_human_stages.size() == HUMAN_LEVELS.size()

func change_hop_rule(key: String, value: Variant) -> void:
	if ui_busy or level.is_empty(): return
	var rules: Dictionary = level.get("rules", {}).duplicate(true)
	if rules.get(key, "free" if key == "long_hop" else 10) == value: return
	rules[key] = value
	set_level_rule("rules", rules)

func show_level_rules(only_new: bool = false) -> void:
	if rule_notice_open or mode not in ["play", "test"] or not world.result.is_empty(): return
	var cards := LevelRules.cards(level)
	if only_new:
		cards = cards.filter(func(card): return card.id not in seen_rule_ids)
		if cards.is_empty(): return
	rule_previous_halt = world.halted
	reset_overlay("")
	rule_notice_open = true
	rule_button.hide()
	pending_rule_ids.clear()
	world.halted = true
	world.input_vector = Vector2.ZERO
	if world.tile_rules != null:
		world.tile_rules.queued_direction = Vector2i.ZERO
	long_hop_button.set_pressed_no_signal(false)
	paragraph(overlay_box, str(level.name), 13)
	var heading := label("NEW RULES" if only_new else "LEVEL RULES", 30 if mobile_ui else 38, LIME)
	heading.add_theme_font_override("font", RULE_INK)
	overlay_box.add_child(heading)
	for card in cards:
		pending_rule_ids.append(card.id)
		var title := label(card.title, 23 if mobile_ui else 28, Color("f0cf87"))
		title.add_theme_font_override("font", RULE_INK)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		overlay_box.add_child(title)
		paragraph(overlay_box, card.body, 15)
	if world.tile_rules != null:
		paragraph(overlay_box, "Now: " + world.tile_rules.resource_label(), 15)
	if cards.is_empty():
		paragraph(overlay_box, "Move freely. Reach the exit. Avoid the hazards.", 15)
	var close_button := button(overlay_box, "Play" if only_new else "Back", close_level_rules, true)
	close_button.grab_focus()
	close_button.focus_next = close_button.get_path_to(close_button)
	close_button.focus_previous = close_button.get_path_to(close_button)
	joystick.hide()

func close_level_rules() -> void:
	if not rule_notice_open: return
	for id in pending_rule_ids:
		if id not in seen_rule_ids: seen_rule_ids.append(id)
	pending_rule_ids.clear()
	rule_notice_open = false
	overlay.hide()
	world.halted = rule_previous_halt
	reset_touch()
	rule_button.release_focus()
	joystick.visible = mobile_ui and not paused and not world.map_view
	save_profile()

func set_level_rule(key: String, value: Variant) -> void:
	if ui_busy or level.is_empty(): return
	record_undo()
	level[key] = value
	if key == "game_mode" and value == "tile":
		# Match the legacy cell ownership rule while making the new grid explicit.
		for obj in level.objects:
			if obj.get("behavior") == "seam_patrol": continue
			obj.pos = [floori(float(obj.pos[0])),floori(float(obj.pos[1]))]
			if obj.has("waypoints"):
				for i in range(obj.waypoints.size()):
					obj.waypoints[i] = [floori(float(obj.waypoints[i][0])),floori(float(obj.waypoints[i][1]))]
			if obj.type == "emitter": obj.rotation = roundf(float(obj.get("rotation",0))/90)*90
	rebuild()
	if key == "game_mode" and value == "tile": status("Tile Hop: actors snap to tile positions. Undo restores the previous layout.")

func show_movement_demos() -> void:
	reset_overlay("Movement demos", "Load into the editor. Undo restores your previous map.")
	var titles := ["Big Hop Boulevard", "Your Move Crossing", "Your Move Garden", "Charge Trial · 10 hops", "Shardwater Sanctuary", "The Seed Vault", "Twenty-Five Terraces"]
	for i in range(titles.size()):
		var index := i
		button(overlay_box, titles[i], func(): open_movement_demo(index))
	button(overlay_box,"Keep editing",func(): overlay.hide())

func show_scenery_demos() -> void:
	reset_overlay("Scenery demos", "Landmarks on the course and in the surrounding water. Loads into the editor; Undo restores your map.")
	for i in range(SCENERY_DEMOS.size()):
		var index := i
		button(overlay_box, ["Temple Shore", "Heron Marsh", "Horizon · 1x", "Horizon · 80x", "Courtyard Gardens · Mexico", "Jungle River · Honduras"][i], func(): open_scenery_demo(index))
	button(overlay_box, "Keep editing", func(): overlay.hide())

func open_scenery_demo(index: int) -> void:
	if request_editor_navigation(func(): open_scenery_demo(index)): return
	var demo := Data.load_json(SCENERY_DEMOS[index])
	if demo.is_empty(): return
	record_undo()
	level = demo
	editor_saved_snapshot = {}
	slot_id = ""
	selection = ""
	enter_editor()

func open_movement_demo(index: int) -> void:
	if request_editor_navigation(func(): open_movement_demo(index)): return
	var paths: Array = TILE_LEVELS.slice(0,2) + [MOVE_DEMO, CHARGE_DEMO] + TILE_LEVELS.slice(2)
	if index < 0 or index >= paths.size(): return
	var demo := Data.load_json(paths[index])
	if demo.is_empty():
		status("Could not load the movement demo.")
		return
	record_undo()
	level = demo
	editor_saved_snapshot = {}
	slot_id = ""
	selection = ""
	enter_editor()
	status("Movement demo loaded. Undo restores the previous map; Save keeps a copy.")

func human_set_unlocked() -> bool:
	return completed_stages.size() == BUILTINS.size()

func campaign_paths() -> Array:
	return paths_for_set(campaign_set)

func play_builtin(index: int, set_key: String = "baby") -> void:
	if load_builtin(index, set_key):
		start_play(false)

func load_builtin(index: int, set_key: String = "baby") -> bool:
	if set_key not in SET_TITLES: return false
	if set_key in ["tile", "sync"] and not tile_mode_unlocked():
		status("Complete " + HUMAN_TITLE + " to unlock Tile Hop.")
		return false
	if set_key == "human" and not human_set_unlocked():
		status("Complete Baby Mode to unlock " + HUMAN_TITLE + ".")
		return false
	if set_key == "city_journey" and index in [1,2] and 0 not in city_progress.city_journey:
		status("Finish Blocks & Park to unlock Frozen Blocks and Skate Escape.")
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
	editor_saved_snapshot = level.duplicate(true)
	slot_id = ""
	undo_stack.clear()
	redo_stack.clear()
	selection = ""
	deaths = 0
	world.load_level(level, false, hat, skin)
	sync_editor()
	return true

func start_play(from_editor: bool = true) -> void:
	hop_audio.clear()
	restart_confirmation_open = false
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
	checkpoint_hop_state = {}
	paused = false
	sidebar.hide()
	overlay.hide()
	world.load_level(level, false, hat, skin)
	world.halted = false
	map_button.text = "Map"
	map_button.show()
	configure_view()
	if exit_preview:
		world.begin_exit_preview()
	mode_label.visible = not (mobile_ui and level.get("game_mode") == "tile")
	mode_label.text = "PLAYTEST" if from_editor else ((str(SET_TITLES[campaign_set]).to_upper() + " · %d / %d") % [campaign_stage_number(), campaign_paths().size()] if campaign_level else "CUSTOM LEVEL")
	edit_button.hide()
	pause_button.text = "Pause"
	pause_button.show()
	joystick.visible = DisplayServer.is_touchscreen_available()
	long_hop_button.visible = level.get("game_mode", "hopan") == "tile" or level.get("city_journey",{}).get("movement") == "skate"
	long_hop_button.text = "Jump · Space" if level.get("city_journey",{}).get("movement") == "skate" else "Long hop"
	long_hop_button.set_pressed_no_signal(false)
	status(level.name + (" · Reach checkpoints to save your place for retries." if level.has("checkpoint") or not level.get("checkpoints", []).is_empty() else " · WASD / arrows to move. M: map. R: retry."))
	reset_touch()
	if level.has("hint"): status(level.name+" · "+str(level.hint))
	if level.get("game_mode") == "tile":
		status("Tile Hop · arrows / WASD: one tile · Space / Long hop, then a direction: two · Walls block both." + (" Move with me: stop to freeze hazards." if level.get("move_with_me",false) else ""))
	start_announcements()
	if rule_notices_enabled:
		show_level_rules(true)

func enter_editor() -> void:
	editor_session_active = true
	hop_audio.clear()
	begin_pending = false
	voice.clear()
	pending_result = ""
	campaign_level = false
	checkpoint_spawn = []
	checkpoint_history = []
	checkpoint_hop_state = {}
	mode = "edit"
	long_hop_button.hide()
	rule_button.hide()
	paused = false
	sidebar.show()
	overlay.hide()
	joystick.hide()
	pause_button.hide()
	map_button.hide()
	world.load_level(level, true, hat, skin)
	configure_view()
	mode_label.show()
	mode_label.text = "WORKSHOP"
	edit_button.text = "Playtest ▶"
	edit_button.show()
	sync_editor()
	status("Build your maze. Space: playtest · Save keeps a local copy · Export creates portable JSON.")

func return_to_editor() -> void:
	if mode != "test": return
	reset_touch()
	enter_editor()

func playtest() -> void:
	start_play(true)

func retry_action_text() -> String:
	return "Retry checkpoint · R" if not checkpoint_spawn.is_empty() else "Retry from start · R"

func retry_description() -> String:
	var text := "Returns to your checkpoint. Hazards restart." if not checkpoint_spawn.is_empty() else "Returns to the level start. Hazards restart."
	if level.get("game_mode", "hopan") != "tile":
		return text
	var rule := LevelRules.mode(level)
	if rule == "charged" or rule == "free":
		return text + "\nLong hop: ready."
	var saved: Dictionary = checkpoint_hop_state if not checkpoint_spawn.is_empty() else {}
	if saved.get("reserve", false):
		return text + "\nLong hop: saved reserve restored."
	if rule == "fragments":
		return text + "\nLong hop: %d / 3 fragments%s." % [int(saved.get("fragments", 0)), " restored" if not checkpoint_spawn.is_empty() else ""]
	return text + "\nLong hop: collect a Hop seed."

func retry() -> void:
	hop_audio.clear()
	restart_confirmation_open = false
	pause_button.text = "Pause"
	pending_result = ""
	paused = false
	overlay.hide()
	world.load_level(level, false, hat, skin)
	world.restore_checkpoints(checkpoint_history)
	if not checkpoint_spawn.is_empty() and world.tile_rules != null:
		world.tile_rules.restore_resource(checkpoint_hop_state)
	if not checkpoint_spawn.is_empty():
		world.player.position = world.cell_position(checkpoint_spawn)
		world.crossing.checkpoint_claimed = true
		world.fit_camera()
	world.halted = false
	map_button.text = "Map"
	configure_view()
	reset_touch()
	joystick.visible = DisplayServer.is_touchscreen_available()
	status("Checkpoint restored. " + level.name if not checkpoint_spawn.is_empty() else level.name + " · Restarted from the beginning.")
	start_announcements(true)

func on_finished(reason: String) -> void:
	if reason != "LEVEL COMPLETE!": hop_audio.clear()
	if not pending_result.is_empty():
		return
	begin_pending = false
	voice.clear()
	var progress: Array = progress_for_set()
	if reason == "LEVEL COMPLETE!" and mode == "play" and campaign_level:
		if builtin_index not in progress:
			progress.append(builtin_index)
		last_cleared_stages[campaign_set] = builtin_index
		refresh_outfit_unlocks()
		save_profile()
	var set_complete := reason == "LEVEL COMPLETE!" and mode == "play" and campaign_level and progress.size() == campaign_paths().size()
	var earned_hat := set_complete and ((campaign_set == "baby" and "baby" not in unlocked_hats) or (campaign_set == "sync" and "hourglass" not in unlocked_hats))
	if set_complete and campaign_set == "baby":
		voice.say("baby_win")
		if skin == "green" and earned_hat:
			skin = "purple"
			world.player.set_skin(skin)
			save_profile()
	if earned_hat:
		if campaign_set == "baby":
			unlock_baby_hat()
			voice.say("baby_frog")
		else:
			unlock_hourglass_hat()
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
	if mode == "test": button(overlay_box, "Back to editor", return_to_editor)
	if reason != "LEVEL COMPLETE!":
		paragraph(overlay_box, {"CROAKED!": "That critter had other plans.", "SPLASHED!": "Ride the logs to stay above the water.", "HIT!": "Ancient security systems still work.", "SQUISHED!": "Wait on the bank for a wider gap in traffic.", "SPIKED!": "Watch the copper track before the spike ball slams."}.get(reason, ""))
	else:
		paragraph(overlay_box, "One small frog. One magnificent escape.")
		if campaign_level and campaign_set == "city_journey" and builtin_index == 0:
			paragraph(overlay_box, "Frozen Blocks and Skate Escape unlocked! Next: a whole frozen district.")
		if mode == "play" and campaign_level:
			if set_complete:
				if campaign_set == "human":
					paragraph(overlay_box, "All four human-made stages cleared! Tile Hop is unlocked.")
					button(overlay_box, "Start · Tile Hop", func(): play_builtin(0,"tile"),true)
				elif campaign_set == "baby":
					paragraph(overlay_box, "All four Baby Mode stages cleared! " + HUMAN_TITLE + " is unlocked.")
					paragraph(overlay_box, "Unlocked: Purple frog skin! Choose Skin on the main menu.")
					button(overlay_box, "Start · " + HUMAN_TITLE, func(): play_builtin(0, "human"), true)
				else:
					paragraph(overlay_box, "All five Moves When You Move stages cleared!" if campaign_set == "sync" else ("Tile Hop demos cleared!" if campaign_set == "tile" else str(SET_TITLES[campaign_set])+" cleared!"))
				if earned_hat:
					paragraph(overlay_box, "Unlocked: " + ("Hourglass pyramid hat" if campaign_set == "sync" else "Baby frog hat") + "! Equipped now. Press Hat to cycle your unlocked hats.")
		if mode == "play" and campaign_level and next_campaign_index() >= 0:
			button(overlay_box, "Next level →", func(): play_builtin(next_campaign_index(), campaign_set), true)
	var has_continuation := mode == "play" and campaign_level and (next_campaign_index() >= 0 or campaign_set in ["baby", "human"])
	if not set_complete or has_continuation:
		if reason != "LEVEL COMPLETE!":
			paragraph(overlay_box, retry_description())
		button(overlay_box, retry_action_text(), retry, true)
	button(overlay_box, "Menu", show_menu)
	joystick.hide()

func toggle_pause() -> void:
	if mode not in ["play", "test"] or not world.result.is_empty():
		return
	if mode == "test": editor_session_active = true
	paused = not paused
	world.halted = paused
	reset_touch()
	if paused:
		show_pause_overlay()
	else:
		overlay.hide()
		joystick.visible = DisplayServer.is_touchscreen_available()
	pause_button.text = "Resume" if paused else "Pause"

func show_pause_overlay() -> void:
	hop_audio.clear()
	joystick.hide()
	reset_overlay("Taking a breather.", "The maze will wait. So will the critters.")
	button(overlay_box, "Resume", toggle_pause, true)
	if mode == "test": button(overlay_box, "Back to editor", return_to_editor)
	paragraph(overlay_box, retry_description())
	button(overlay_box, retry_action_text(), retry)
	if not checkpoint_spawn.is_empty():
		button(overlay_box, "Restart level…", confirm_level_restart)
	button(overlay_box, "Hop feel comparison", show_hop_comparison)
	button(overlay_box, "Menu", show_menu)

func show_hop_comparison() -> void:
	reset_overlay("Hop feel", "Compare on the same level. Only leg poses and hop sounds change. Choices last for this session.")
	hop_animation_button = button(overlay_box, "Animation: " + ("Stepped · 12 poses/s" if world.hop_pose_style == "stepped" else "Smooth"), cycle_hop_animation)
	hop_palette_button = button(overlay_box, "Hop sound: " + ("Soft" if hop_audio.palette == "soft" else "Retro") + " · original", cycle_hop_palette)
	var volume_label := paragraph(overlay_box, "Hop volume · %d%%" % roundi(hop_audio.gain * 100))
	hop_volume_slider = HSlider.new()
	hop_volume_slider.min_value=0;hop_volume_slider.max_value=100;hop_volume_slider.step=5
	hop_volume_slider.value=hop_audio.gain*100
	hop_volume_slider.custom_minimum_size=Vector2(0,44)
	hop_volume_slider.value_changed.connect(func(value: float):
		hop_audio.set_gain(value/100.0)
		volume_label.text = "Hop volume · %d%%" % roundi(value))
	overlay_box.add_child(hop_volume_slider)
	button(overlay_box, "Hear takeoff + landing", func(): preview_hop_sound())
	button(overlay_box, "Hear long-hop boing", func(): preview_hop_sound(true))
	paragraph(overlay_box, "Original synthesized effects, CC0. Sound Off mutes effects and voices. Landing is softer; effects duck during speech.")
	button(overlay_box, "Back to Pause" if paused else "Back to Menu", show_pause_overlay if paused else show_menu)

func cycle_hop_animation() -> void:
	world.hop_pose_style = "smooth" if world.hop_pose_style == "stepped" else "stepped"
	if is_instance_valid(hop_animation_button):
		hop_animation_button.text = "Animation: " + ("Stepped · 12 poses/s" if world.hop_pose_style == "stepped" else "Smooth")

func cycle_hop_palette() -> void:
	hop_audio.clear()
	hop_audio.palette = "retro" if hop_audio.palette == "soft" else "soft"
	if is_instance_valid(hop_palette_button):
		hop_palette_button.text = "Hop sound: " + ("Soft" if hop_audio.palette == "soft" else "Retro") + " · original"

func preview_hop_sound(big: bool = false) -> void:
	hop_audio.clear()
	hop_audio.play_event("takeoff", voice.busy(), big)
	var generation: int = hop_audio.generation
	# Audition only; gameplay uses its authoritative safe-landing event.
	await get_tree().create_timer(0.34).timeout
	if generation == hop_audio.generation and overlay.visible and is_instance_valid(hop_volume_slider) and hop_volume_slider.is_visible_in_tree():
		hop_audio.play_event("landing", voice.busy())

func confirm_level_restart() -> void:
	reset_overlay("Restart this level?", "Resets this level's checkpoint and pickups. Hazards restart. Campaign progress is kept.")
	restart_confirmation_open = true
	button(overlay_box, "Keep checkpoint", show_pause_overlay, true)
	button(overlay_box, "Restart from beginning", restart_current_level)

func restart_current_level() -> void:
	if not restart_confirmation_open:
		return
	start_play(mode == "test")

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
	var city_aa: bool = mode in ["play", "test"] and not world.editing and not level.get("city_journey", {}).is_empty()
	var retro: bool = not world.editing and not world.map_view and not city_aa
	# The wide City Journey camera makes the 240px retro buffer lose small
	# figures and rail edges. Render near display resolution, cap very large
	# viewports, and smooth 3D edges. Earlier levels retain retro.
	var city_shrink := maxi(1, ceili(maxf(view_container.size.x / 1920.0, view_container.size.y / 1440.0)))
	view_container.stretch_shrink = city_shrink if city_aa else (maxi(1, roundi(view_container.size.y / 240.0)) if retro else 1)
	view_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if city_aa else CanvasItem.TEXTURE_FILTER_NEAREST
	view.msaa_3d = Viewport.MSAA_2X if city_aa else Viewport.MSAA_DISABLED
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

func cleared_cosmetic_levels() -> int:
	return completed_stages.size()+completed_human_stages.size()+completed_bonus_stages.size()+completed_tile_stages.size()+completed_sync_stages.size()+city_progress.nyc.size()+city_progress.streetlife.size()

func available_skins() -> Array[String]:
	var choices:Array[String]=["green"]
	for entry in [[2,"orange"],[4,"yellow"],[6,"spotted"],[8,"purple_white"],[10,"gummy"]]:
		if cleared_cosmetic_levels()>=entry[0]:choices.append(entry[1])
	if completed_stages.size()==BUILTINS.size():choices.append("purple")
	return choices

func refresh_outfit_unlocks() -> void:
	if cleared_cosmetic_levels()>=6 and "morning" not in unlocked_hats:unlocked_hats.append("morning")

func toggle_skin() -> void:
	var choices:=available_skins()
	skin=choices[(choices.find(skin)+1)%choices.size()]
	world.player.set_skin(skin)
	save_profile()
	# Keep the emitting control, scroll position and keyboard/touch focus alive.
	# Rebuilding this menu from its own button callback can invalidate active UI.
	if is_instance_valid(skin_button):
		skin_button.text = "Skin: " + skin.replace("_", " ").capitalize()

func toggle_hat() -> void:
	refresh_outfit_unlocks()
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

func unlock_hourglass_hat() -> void:
	if completed_sync_stages.size() != SYNC_LEVELS.size() or "hourglass" in unlocked_hats:
		return
	unlocked_hats.append("hourglass")
	hat = "hourglass"
	world.player.set_hat(hat)
	if is_instance_valid(hat_button):
		hat_button.tooltip_text = "Hourglass pyramid hat · Cycle unlocked hats"
	save_profile()

func save_profile() -> void:
	var profile := ConfigFile.new()
	profile.set_value("city", "progress", city_progress)
	profile.set_value("rules", "seen", seen_rule_ids)
	profile.set_value("settings", "exit_preview", exit_preview)
	profile.set_value("settings", "recorded_voices", sound_enabled)
	profile.set_value("hats", "baby_unlocked", "baby" in unlocked_hats)
	profile.set_value("hats", "equipped", hat)
	profile.set_value("skins", "equipped", skin)
	profile.set_value("baby_mode", "completed", completed_stages)
	profile.set_value("not_as_hard", "completed", completed_human_stages)
	profile.set_value("bonus", "completed", completed_bonus_stages)
	profile.set_value("tile_hop", "completed", completed_tile_stages)
	profile.set_value("your_move", "completed", completed_sync_stages)
	profile.set_value("sets", "last_cleared", last_cleared_stages)
	var file_saved := profile.save("user://profile.cfg") == OK
	var browser_saved := false
	if OS.has_feature("web"):
		# IndexedDB filesystem sync is asynchronous. Keep the small profile durable
		# immediately as well, so a quick reload cannot restore an older hat/clear.
		var payload := JSON.stringify({"version": 1, "city": city_progress, "baby": completed_stages, "human": completed_human_stages, "bonus": completed_bonus_stages, "tile": completed_tile_stages, "sync": completed_sync_stages, "last_cleared": last_cleared_stages, "hat": hat, "skin": skin, "preview": exit_preview, "sound": sound_enabled, "seen_rules": seen_rule_ids})
		browser_saved = bool(JavaScriptBridge.eval("(function(){try{localStorage.setItem('hopan.profile.v1', " + JSON.stringify(payload) + ");return true;}catch(e){return false;}})()", true))
	if not file_saved and not browser_saved:
		status("Could not save progress on this device.")

func load_profile() -> void:
	unlocked_hats = ["none", "pharaoh"]
	completed_stages = []
	completed_human_stages = []
	completed_bonus_stages = []
	completed_tile_stages = []
	completed_sync_stages = []
	last_cleared_stages = {}
	seen_rule_ids = []
	hat = "pharaoh"
	skin = "green"
	var profile := ConfigFile.new()
	var file_loaded := profile.load("user://profile.cfg") == OK
	var browser_loaded := false
	if OS.has_feature("web"):
		var stored: Variant = JavaScriptBridge.eval("(function(){try{return localStorage.getItem('hopan.profile.v1');}catch(e){return null;}})()", true)
		if stored is String and stored.length() < 16384:
			var parsed := JSON.new()
			var backup: Variant = Data.normalize(parsed.data) if parsed.parse(stored) == OK else null
			if backup is Dictionary and backup.get("version") == 1 and backup.get("baby") is Array and backup.get("human") is Array and backup.get("hat") in HAT_NAMES and backup.get("preview") is bool:
				profile.set_value("city", "progress", backup.get("city",{}))
				profile.set_value("baby_mode", "completed", backup.baby)
				profile.set_value("not_as_hard", "completed", backup.human)
				if backup.get("bonus") is Array:
					profile.set_value("bonus", "completed", backup.bonus)
				if backup.get("tile") is Array:
					profile.set_value("tile_hop", "completed", backup.tile)
				if backup.get("sync") is Array:
					profile.set_value("your_move", "completed", backup.sync)
				if backup.get("last_cleared") is Dictionary:
					profile.set_value("sets", "last_cleared", backup.last_cleared)
				profile.set_value("hats", "equipped", backup.hat)
				profile.set_value("skins", "equipped", backup.get("skin", "green"))
				profile.set_value("rules", "seen", backup.get("seen_rules", []))
				profile.set_value("settings", "exit_preview", backup.preview)
				if backup.get("sound") is bool:
					profile.set_value("settings", "recorded_voices", backup.sound)
				browser_loaded = true
	if not file_loaded and not browser_loaded:
		return
	var saved_city: Variant = profile.get_value("city","progress",{})
	if saved_city is Dictionary:
		for key in city_progress:
			if saved_city.get(key) is Array:
				city_progress[key] = saved_city[key].filter(func(i): return i is int and i >= 0 and i < paths_for_set(key).size())
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
	var saved_tiles: Variant = profile.get_value("tile_hop", "completed", [])
	if saved_tiles is Array:
		for value in saved_tiles:
			if value is int and value >= 0 and value < TILE_LEVELS.size() and value not in completed_tile_stages:
				completed_tile_stages.append(value)
	var saved_sync: Variant = profile.get_value("your_move", "completed", [])
	if saved_sync is Array:
		for value in saved_sync:
			if value is int and value >= 0 and value < SYNC_LEVELS.size() and value not in completed_sync_stages:
				completed_sync_stages.append(value)
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
	if completed_sync_stages.size() == SYNC_LEVELS.size():
		unlocked_hats.append("hourglass")
	refresh_outfit_unlocks()
	var saved_hat: Variant = profile.get_value("hats", "equipped", "pharaoh")
	hat = str(saved_hat) if saved_hat in unlocked_hats else "pharaoh"
	var saved_skin: Variant = profile.get_value("skins", "equipped", "green")
	skin = str(saved_skin) if saved_skin in available_skins() else "green"
	var saved_rules: Variant = profile.get_value("rules", "seen", [])
	if saved_rules is Array:
		for value in saved_rules.slice(0, 64):
			if value is String and value.length() <= 64 and value not in seen_rule_ids:
				seen_rule_ids.append(value)
	if browser_loaded:
		save_profile()

func status(text: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = text

func sync_editor(refresh_selection: bool = true) -> void:
	if level.is_empty():
		return
	ui_busy = true
	tile_mode_toggle.set_pressed_no_signal(level.get("game_mode", "hopan") == "tile")
	movement_toggle.set_pressed_no_signal(level.get("move_with_me", false))
	hop_rule_picker.select(["free","charged","fragments","powerup"].find(level.get("rules", {}).get("long_hop", "free")))
	hop_rule_picker.disabled = level.get("game_mode", "hopan") != "tile"
	hop_charge_picker.set_value_no_signal(LevelRules.charge_hops(level))
	hop_charge_picker.editable = LevelRules.charged(level)
	draw_distance_picker.set_value_no_signal(level.get("draw_distance",18))
	name_field.text = level.name
	theme_picker.select(Data.THEMES.find(level.theme))
	for key in themed_tool_buttons:
		var names: Dictionary = {"tree":"Tree", "pillar":"Pillar", "decoration":"Pot"}
		if level.theme == "mexico": names = {"tree":"Cactus", "pillar":"Painted column", "decoration":"Flower pot"}
		elif level.theme == "honduras": names = {"tree":"Jungle tree", "pillar":"Stepped column", "decoration":"Fern pot"}
		themed_tool_buttons[key].text = names[key]
	undo_button.disabled = undo_stack.is_empty()
	redo_button.disabled = redo_stack.is_empty()
	ui_busy = false
	if refresh_selection:
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
	level.theme = Data.THEMES[index]
	rebuild()

func record_undo() -> void:
	if mode == "edit" and level.has("editor_autosave_id"):
		editor_change_finished.call_deferred(level.duplicate(true))
	undo_stack.append(level.duplicate(true))
	if undo_stack.size() > 80:
		undo_stack.pop_front()
	redo_stack.clear()
	undo_button.disabled = false
	redo_button.disabled = true

func undo() -> void:
	if mode != "edit" or undo_stack.is_empty():
		return
	var previous := level.duplicate(true)
	redo_stack.append(previous)
	level = undo_stack.pop_back()
	editor_change_finished.call_deferred(previous)
	selection = ""
	rebuild()
	status("Undid the last edit.")

func redo() -> void:
	if mode != "edit" or redo_stack.is_empty():
		return
	var previous := level.duplicate(true)
	undo_stack.append(previous)
	level = redo_stack.pop_back()
	editor_change_finished.call_deferred(previous)
	selection = ""
	rebuild()
	status("Redid the last edit.")

func set_tool(key: String) -> void:
	tool = key
	tool_label.text = "TOOL  /  " + key.replace("_", " ").to_upper()
	if key == "route":
		status("Select a critter, patrol car or spike ball, then draw its route.")

func rebuild(refresh_selection: bool = true) -> void:
	world.load_level(level, true, hat, skin)
	sync_editor(refresh_selection)
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
	if not world.inside(cell) and not ((tool.begins_with("landmark_") or tool in ["backdrop", "select", "erase"] or erase) and Data.landmark_point_valid([cell.x,cell.y],level.width,level.height)):
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
		if obj.is_empty() or obj.type not in ["critter", "patrol_car", "spike_ball"]:
			status("Select a critter, patrol car or spike ball, then choose Patrol route.")
			return
		if level.tiles[cell.y][cell.x] in ["wall", "cheese_wall", "water"]:
			status("Waypoints need dry, open terrain.")
			return
		if obj.type == "patrol_car":
			var previous: Array = obj.get("waypoints", [])[-1] if not obj.get("waypoints", []).is_empty() else obj.pos
			if not Data.road_segment_open(level, previous, point):
				status("Car patrols need connected road cells. Add a waypoint at each turn.")
				return
		if obj.type == "spike_ball":
			var previous: Array = obj.get("waypoints",[])[-1] if not obj.get("waypoints",[]).is_empty() else obj.pos
			if not Data.spike_segment_open(level,previous,point):
				status("Spike routes need clear, dry cardinal segments. Add a corner before turning.")
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
		if obj.type == "spike_ball": obj.behavior = "slam_patrol"
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
	if index >= 0 and level.objects[index].type == "hop_seed" and tool == "road":
		status("Erase the hop pickup before turning its safe bank into a road.")
		return
	var checkpoint_cell: bool = point in level.get("checkpoints", []) or point == level.get("checkpoint", [])
	if checkpoint_cell and (tool in ["wall", "cheese_wall", "water", "road", "spawn", "exit", "pillar", "tree", "emitter"]):
		status("Erase or move the checkpoint before blocking its safe tile.")
		return
	if (tool.begins_with("landmark_") or tool == "backdrop") and not erase:
		if index >= 0 or level.objects.size() >= 180: return
		if tool != "backdrop" and level.objects.filter(func(obj): return obj.type == "landmark").size() >= 32:
			status("A level supports up to 32 landmarks.")
			return
		if point == level.spawn or point == level.exit or point in level.get("checkpoints", []) or point == level.get("checkpoint", []):
			status("Keep the frog start, exit and checkpoint markers clear.")
			return
		var landmark := {"id":"landmark_%d" % Time.get_ticks_usec(),"type":"landmark","pos":point,"rotation":180,"solid":false,"landmark_kind":tool.trim_prefix("landmark_"),"landmark_scale":1.0}
		if tool == "backdrop":
			if level.objects.filter(func(obj):return obj.type=="backdrop").size()>=4:
				status("Use up to four distant backdrops to limit screen overdraw.")
				return
			landmark={"id":"backdrop_%d" % Time.get_ticks_usec(),"type":"backdrop","pos":point,"solid":false,"backdrop_kind":"pyramid","backdrop_scale":80,"backdrop_distance":480}
		level.objects.append(landmark)
		selection = landmark.id
		rebuild()
		return
	if not world.inside(cell) and index < 0: return
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
		if tool == "hop_seed" and terrain == "road":
			status("Hop pickups need a safe bank, away from road traffic.")
			return
		if index >= 0 or level.objects.size() >= 180:
			return
		if tool == "seam_worm":
			point = [cell.x + 0.5, cell.y + 0.5]
			if not Data.seam_point_open(level, point):
				status("Place a seam worm at a corner surrounded by four open, dry tiles.")
				return
		var obj := {"id": "object_%d_%d" % [Time.get_ticks_usec(), level.objects.size()], "type": "critter" if tool == "seam_worm" else tool, "pos": point, "rotation": 0, "solid": tool in ["pillar", "tree", "emitter"]}
		if tool in ["critter", "roach", "seam_worm"]:
			obj.merge({"behavior": "seam_patrol" if tool == "seam_worm" else "wander", "speed": 1.6, "waypoints": []})
		if tool == "seam_worm":
			obj.seam_anchor = [cell.x, cell.y]
		if tool == "city_prop":
			obj.variant = "bench"
			obj.solid = true
		if tool == "skater":
			obj.variant = 0
			obj.speed = 3.2
			obj.route = default_skate_route(point)
			if obj.route.is_empty():
				status("A skater needs a dry two-by-two-cell loop. Choose a more open spot.")
				return
		if tool == "spike_ball":
			obj.merge({"behavior":"free_shift","pause":2,"range":3,"directions":[0,90,180,270],"waypoints":[],"patrol_loop":true})
		if tool == "emitter":
			obj.interval = 2.5
		if tool in ["car", "patrol_car", "log"]:
			obj.merge({"length": 4.6 if tool == "log" else 1.5, "speed": 1.0, "direction": 1})
		if tool == "patrol_car":
			obj.merge({"axis": "east_west", "waypoints": [], "length": 1.0}, true)
		level.objects.append(obj)
		selection = obj.id
	rebuild()

func default_skate_route(point: Array) -> Array:
	for dx in [-2, 2]:
		for dy in [-2, 2]:
			var route: Array = []
			for p in [point, [point[0] + dx, point[1]], [point[0] + dx, point[1] + dy], [point[0], point[1] + dy]]:
				route.append({"pos": p, "height": 0.0, "trick": "push"})
			var candidate: Dictionary = level.duplicate(true)
			candidate.objects.append({"id": "skate_route_preview", "type": "skater", "variant": 0, "speed": 3.2, "pos": point, "route": route})
			if Data.validate(candidate).is_empty():
				return route
	return []

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
	rot.value_changed.connect(func(v: float): change_property("rotation", v, false))
	if obj.type not in ["spike_ball", "backdrop", "hop_fragment", "hop_seed"]: inspector.add_child(rot)
	else: rot.queue_free()
	if obj.type == "backdrop":
		var model := OptionButton.new()
		for title in LandmarkModels.TITLES: model.add_item(title)
		model.select(LandmarkModels.KINDS.find(obj.get("backdrop_kind","pyramid")))
		model.item_selected.connect(func(index: int): change_property("backdrop_kind",LandmarkModels.KINDS[index]))
		inspector.add_child(model)
		for field in [["backdrop_scale",1,100,1,80,"x art scale"],["backdrop_distance",128,2048,32,480,"backdrop distance"]]:
			var key: String=field[0]
			var input:=SpinBox.new()
			input.min_value=field[1]
			input.max_value=field[2]
			input.step=field[3]
			input.value=obj.get(key,field[4])
			input.suffix=field[5]
			input.value_changed.connect(func(value:float):change_property(key,value,false))
			inspector.add_child(input)
		paragraph(inspector,"Distant art · The ground pin sets its direction. Art scale changes size without changing the course. Distance sets its fixed position beyond the shore.",12)
	if obj.type in ["hop_fragment", "hop_seed"]:
		paragraph(inspector,"Triangle fragment: collect three for one long hop in Fragment rules. Diamond Hop seed: one pickup, one hop in Power-up rules. Land to collect. Inactive in other rules.",12)
	if obj.type == "landmark":
		var model := OptionButton.new()
		for title in LandmarkModels.TITLES: model.add_item(title)
		model.select(LandmarkModels.KINDS.find(obj.get("landmark_kind","sphinx")))
		model.item_selected.connect(func(index: int): change_property("landmark_kind",LandmarkModels.KINDS[index]))
		inspector.add_child(model)
		var size := SpinBox.new()
		size.min_value = 0.25
		size.max_value = 2
		size.step = 0.25
		size.value = obj.get("landmark_scale",1)
		size.suffix = "landmark scale"
		size.value_changed.connect(func(value: float): change_property("landmark_scale",value,false))
		inspector.add_child(size)
		paragraph(inspector,"Visual scenery · Does not block movement or darts. Select its gold ground pin. Background view lets you place it outside the course.",12)
	if obj.type in ["critter","roach"]:
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
		speed.value_changed.connect(func(v: float): change_property("speed", v, false))
		if level.get("game_mode") == "tile":
			speed.queue_free()
			paragraph(inspector,"Tile mode · one tile per beat",12)
		else:
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
	if obj.type == "spike_ball":
		var behavior := OptionButton.new()
		behavior.add_item("Free cardinal shifts")
		behavior.add_item("Slam patrol route")
		behavior.select(1 if obj.get("behavior")=="slam_patrol" else 0)
		behavior.item_selected.connect(func(i: int): change_property("behavior","free_shift" if i==0 else "slam_patrol"))
		inspector.add_child(behavior)
		var hold := SpinBox.new()
		hold.min_value=1
		hold.max_value=6
		hold.step=1
		hold.value=obj.get("pause",2)
		hold.suffix="hold beats" if level.get("game_mode")=="tile" else "hold seconds"
		hold.value_changed.connect(func(value: float): change_property("pause",value,false))
		inspector.add_child(hold)
		if obj.get("behavior","free_shift")=="free_shift":
			var distance := SpinBox.new()
			distance.min_value=1
			distance.max_value=5
			distance.value=obj.get("range",3)
			distance.suffix="tiles / shift"
			distance.value_changed.connect(func(value: float): change_property("range",value,false))
			inspector.add_child(distance)
			var directions := row(inspector)
			for entry in [[0,"N"],[270,"E"],[180,"S"],[90,"W"]]:
				var angle: int=entry[0]
				var check := CheckBox.new()
				check.text=entry[1]
				check.button_pressed=angle in obj.get("directions",[0,90,180,270])
				check.toggled.connect(func(enabled: bool):
					var selected: Array=obj.get("directions",[0,90,180,270]).duplicate()
					if enabled and angle not in selected: selected.append(angle)
					elif not enabled: selected.erase(angle)
					if selected.is_empty():
						refresh_inspector.call_deferred()
						status("Keep at least one spike direction enabled.")
					else: change_property("directions",selected))
				directions.add_child(check)
		else:
			var route_controls := row(inspector)
			button(route_controls,"Draw route",func(): set_tool("route"))
			var loop := CheckBox.new()
			loop.text="Loop"
			loop.button_pressed=obj.get("patrol_loop",true)
			loop.toggled.connect(func(value: bool): change_property("patrol_loop",value))
			route_controls.add_child(loop)
			button(inspector,"Clear route",func(): change_property("waypoints",[]))
		paragraph(inspector,"Copper track marks the next slam. Hold, then move fast. Walls, cheese and scenery stop it.",12)
	if obj.type == "city_prop":
		var prop_picker := OptionButton.new()
		for kind in Data.CITY_PROPS:
			prop_picker.add_item(str(kind).replace("_", " ").capitalize())
		prop_picker.select(Data.CITY_PROPS.find(obj.variant))
		prop_picker.item_selected.connect(func(i: int): change_property("variant", Data.CITY_PROPS[i], false))
		inspector.add_child(prop_picker)
	if obj.type == "skater":
		var rider := OptionButton.new()
		for title in ["Cap / rust shirt", "Hoodie / teal", "Punk / violet"]:
			rider.add_item(title)
		rider.select(int(obj.get("variant", 0)))
		rider.item_selected.connect(func(i: int): change_property("variant", i, false))
		inspector.add_child(rider)
		var skate_speed := SpinBox.new()
		skate_speed.min_value = 2
		skate_speed.max_value = 5.5
		skate_speed.step = 0.1
		skate_speed.value = obj.get("speed", 3.2)
		skate_speed.suffix = "speed"
		skate_speed.value_changed.connect(func(v: float): change_property("speed", v, false))
		inspector.add_child(skate_speed)
		paragraph(inspector, "Loop points and trick heights are preserved in JSON. The lines show this rider's route.", 11)
	if obj.type == "emitter":
		var interval := SpinBox.new()
		interval.min_value = 1.0 if level.get("game_mode") == "tile" else 0.5
		interval.max_value = 10
		interval.step = 1.0 if level.get("game_mode") == "tile" else 0.25
		interval.value = ceilf(float(obj.get("interval", 2.5))) if level.get("game_mode") == "tile" else obj.get("interval", 2.5)
		interval.suffix = "beats / shot" if level.get("game_mode") == "tile" else "sec / shot"
		interval.value_changed.connect(func(v: float): change_property("interval", v, false))
		inspector.add_child(interval)
		paragraph(inspector, "0° fires north · 90° west\n180° south · 270° east", 11)
	if obj.type in ["car", "patrol_car", "log"]:
		for field in [["length", 1.0, 1.0 if obj.type == "patrol_car" else 6.0, "cells long"], ["speed", 0.3, 4.0, "lane speed"]]:
			var key: String = field[0]
			if key == "speed" and level.get("game_mode") == "tile": continue
			var value := SpinBox.new()
			value.min_value = field[1]
			value.max_value = field[2]
			value.step = 0.1
			value.value = obj.get(key, 1.5 if key == "length" else 1.0)
			value.suffix = field[3]
			value.value_changed.connect(func(v: float): change_property(key, v, false))
			inspector.add_child(value)
		if level.get("game_mode") == "tile": paragraph(inspector,"Tile mode · one tile per beat",12)
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

	if obj.type in ["mushroom", "decoration", "city_prop"]:
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

func change_property(key: String, value: Variant, refresh_controls: bool = true) -> void:
	var obj := selected_object()
	if obj.is_empty():
		return
	if key == "solid" and value == true and (obj.pos in level.get("checkpoints", []) or obj.pos == level.get("checkpoint", [])):
		status("Move the checkpoint before making this object solid.")
		return
	if key == "rotation" and obj.get("behavior") == "seam_patrol":
		rotate_seam_worm(obj, float(value), refresh_controls)
		return
	if key == "interval":
		value = clampf(ceilf(float(value)) if level.get("game_mode") == "tile" else float(value), 1.0 if level.get("game_mode") == "tile" else 0.5, 10.0)
	record_undo()
	obj[key] = value
	# Keep a SpinBox attached throughout its own input callback and repeat timer.
	rebuild(refresh_controls)

func rotate_seam_worm(obj: Dictionary, degrees: float, refresh_controls: bool = true) -> void:
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
			refresh_inspector.call_deferred()
			status("Rotation blocked: the worm and route need clear, dry tile seams inside the level.")
			return
	record_undo()
	obj.seam_anchor = anchor.duplicate()
	obj.pos = rotated[0]
	if obj.has("waypoints"):
		obj.waypoints = rotated.slice(1)
	obj.rotation = fposmod(degrees, 360)
	rebuild(refresh_controls)

func load_library() -> void:
	var disk_exists:=FileAccess.file_exists("user://library.json")
	var disk_text:=FileAccess.get_file_as_string("user://library.json") if disk_exists else ""
	var stored:Variant=LibraryMirror.parse_json(disk_text) if disk_exists else []
	if OS.has_feature("web"):
		var lookup:=LibraryMirror.read_web(LibraryMirror.KEY)
		if not lookup.get("ok",false):
			library_safety_error=LibraryMirror.ERROR_TEXT
		else:
			library_mirror_seen=lookup.get("value")
			var resolved:=LibraryMirror.resolve(disk_exists,disk_text,library_mirror_seen!=null,str(library_mirror_seen))
			if not resolved.get("ok",false):library_safety_error=LibraryMirror.ERROR_TEXT
			else:
				stored=resolved.entries;library_mirror_state=resolved.mirror;library_mirror_used=resolved.used
	if stored is Array:
		for item in stored:
			if item is Dictionary and item.get("id") is String and Data.validate(item.get("level"), item.get("autosave",false) == true) == "":
				library.append(Data.normalize(item))
			else:library_opaque.append(item)
	if OS.has_feature("web"):
		var backup: Variant = JavaScriptBridge.eval("(function(){try{return localStorage.getItem('hopan.editor.autosaves.v1');}catch(e){return null;}})()",true)
		if backup is String and backup.length() < 8000000:
			var entries: Variant = JSON.parse_string(backup)
			if entries is Array:
				for entry in entries:
					if entry is Dictionary and entry.get("id") is String and entry.get("autosave") == true and Data.validate(entry.get("level"), true) == "":
						if library_mirror_used and library.any(func(item): return item.id == entry.id): continue
						library = library.filter(func(item: Dictionary): return item.id != entry.id)
						library.append(Data.normalize(entry))


func import_city_library() -> void:
	if not library_safety_error.is_empty(): return
	var state := LibraryCompat.load_library(Data.validate,Data.normalize)
	if not state.writable:
		library_safety_error = state.error
		return
	var merged := LibraryMerge.merge(library,state.items)
	if merged != library:
		if commit_library_candidate(merged): library = merged

func refresh_library_picker() -> void:
	saved_picker.clear()
	saved_picker.add_item("Load a local level…")
	for item in library:
		saved_picker.add_item(str(item.level.name))

func editor_has_unsaved_changes() -> bool:
	return not level.is_empty() and level != editor_saved_snapshot

func request_editor_navigation(action: Callable) -> bool:
	if editor_navigation_bypass or not editor_session_active or mode not in ["edit", "test"]: return false
	if mode == "edit": commit_name()
	if not editor_has_unsaved_changes(): return false
	pending_editor_navigation = action
	reset_overlay("Save before leaving?", "This level has unsaved changes. Save keeps a local copy on this device; export JSON for a portable backup.")
	editor_leave_open = true
	world.halted = true
	joystick.hide()
	button(overlay_box, "Yes · Save and leave", func():
		if save_level(): finish_editor_navigation()
		else: paragraph(overlay_box, status_label.text), true)
	button(overlay_box, "No · Leave without saving", finish_editor_navigation)
	button(overlay_box, "Continue editing", cancel_editor_navigation)
	return true

func finish_editor_navigation() -> void:
	var action := pending_editor_navigation
	pending_editor_navigation = Callable()
	editor_leave_open = false
	editor_navigation_bypass = true
	if action.is_valid(): action.call()
	editor_navigation_bypass = false

func cancel_editor_navigation() -> void:
	pending_editor_navigation = Callable()
	editor_leave_open = false
	if mode == "test":
		world.halted = paused
		if paused: show_pause_overlay()
		else: overlay.hide()
		joystick.visible = mobile_ui and not paused
	else:
		overlay.hide()
		world.halted = false

func commit_library_candidate(candidate:Array) -> bool:
	var all_entries:Array=library_opaque.duplicate(true)+candidate.duplicate(true)
	if not LibraryMirror.unique_ids(all_entries):
		library_safety_error=LibraryMirror.ERROR_TEXT
		status(library_safety_error);return false
	var path:="user://library.json"
	if OS.has_feature("web"):
		var exists:=FileAccess.file_exists(path)
		var old_text:=FileAccess.get_file_as_string(path) if exists else ""
		var payload:=LibraryMirror.next_payload(all_entries,exists,old_text,library_mirror_state)
		if payload.is_empty() or not LibraryMirror.put_web(LibraryMirror.KEY,payload,library_mirror_seen):
			library_safety_error=LibraryMirror.ERROR_TEXT
			status(library_safety_error)
			return false
		library_mirror_seen=payload;library_mirror_state=LibraryMirror.parse_json(payload);library_mirror_used=true
	var f:=FileAccess.open("user://library.pending.json",FileAccess.WRITE)
	if f==null:
		library_safety_error="Saved levels need recovery. Reload or export a backup before saving."
		status(library_safety_error);return false
	f.store_string(JSON.stringify(all_entries,"\t"));var write_error:=f.get_error();f.close()
	if write_error!=OK or DirAccess.rename_absolute("user://library.pending.json",path)!=OK:
		library_safety_error="Saved levels need recovery. Reload or export a backup before saving."
		status(library_safety_error);return false
	return true

func save_level() -> bool:
	if not library_safety_error.is_empty():
		status(library_safety_error)
		return false
	commit_name()
	var error := Data.validate(level)
	if not error.is_empty():
		status(error)
		return false
	var saved_id := slot_id if not slot_id.is_empty() else "level_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	var candidate: Array = library.duplicate(true)
	var found := false
	for item in candidate:
		if item.id == saved_id:
			item.level = level.duplicate(true)
			found = true
	if not found: candidate.append({"id": saved_id, "level": level.duplicate(true)})
	if not commit_library_candidate(candidate):return false
	library = candidate
	slot_id = saved_id
	editor_saved_snapshot = level.duplicate(true)
	refresh_library_picker()
	status("Saved locally: " + level.name + ". Export JSON for a backup outside this browser.")
	return true

func duplicate_level() -> void:
	record_undo()
	level = level.duplicate(true)
	if level.has("editor_autosave_id"):
		level.editor_autosave_id = "new_%d_%d" % [Time.get_unix_time_from_system(),Time.get_ticks_usec()]
	level.name = str(level.name).left(72) + " (copy)"
	slot_id = ""
	sync_editor()
	save_level()

func load_saved(index: int) -> void:
	if index > 0 and request_editor_navigation(func(): load_saved(index)): return
	if index > 0:
		load_library_entry(index - 1)
		enter_editor()

func load_library_entry(index: int) -> void:
	campaign_level = false
	level = library[index].level.duplicate(true)
	editor_saved_snapshot = {} if library[index].get("autosave",false) else level.duplicate(true)
	slot_id = "" if library[index].get("autosave",false) else library[index].id
	if library[index].get("autosave",false):
		level.name = library[index].original_name if library[index].get("original_name") is String else level.name
	editor_autosave_due = false
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
	if request_editor_navigation(func(): import_text(text)): return false
	record_undo()
	level = Data.normalize(data)
	editor_saved_snapshot = {}
	if level.has("editor_autosave_id"):
		level.editor_autosave_id = "new_%d_%d" % [Time.get_unix_time_from_system(),Time.get_ticks_usec()]
	slot_id = ""
	selection = ""
	enter_editor()
	status("Imported " + str(level.name) + ". Save to keep a local copy.")
	return true

func new_level(theme_name: String = "egypt") -> void:
	if request_editor_navigation(func(): new_level(theme_name)): return
	editor_saved_snapshot = {}
	record_undo()
	level = Data.blank(Data.NEW_NAMES[Data.THEMES.find(theme_name)], theme_name, [17,21,33][size_picker.selected], [13,16,49][size_picker.selected])
	level.editor_autosave_id = "new_%d_%d" % [Time.get_unix_time_from_system(),Time.get_ticks_usec()]
	editor_autosave_due = false
	slot_id = ""
	selection = ""
	enter_editor()

func editor_change_finished(previous: Dictionary) -> void:
	var identity: String = str(level.get("editor_autosave_id", ""))
	if identity.is_empty() or previous.get("editor_autosave_id", "") != identity or previous == level:
		return
	editor_change_counts[identity] = int(editor_change_counts.get(identity,0)) + 1
	if int(editor_change_counts[identity]) % 40 == 0:
		editor_autosave_due = true

func save_editor_checkpoint() -> bool:
	if not library_safety_error.is_empty():
		status(library_safety_error)
		return false
	if not level.has("editor_autosave_id"):
		return false
	var error := Data.validate(level,true)
	if not error.is_empty():
		status("Autosave waiting: " + error)
		return false
	var identity: String = "autosave_" + str(level.editor_autosave_id)
	var checkpoint := {"id": identity, "level": level.duplicate(true), "autosave": true, "original_name": level.name}
	checkpoint.level.name = str(level.name).left(65) + " · Autosave"
	var next_library := library.duplicate(true)
	var existing := -1
	for i in range(next_library.size()):
		if next_library[i].id == identity: existing = i
	if existing >= 0: next_library[existing] = checkpoint
	else: next_library.append(checkpoint)
	if not commit_library_candidate(next_library):return false
	library = next_library
	refresh_library_picker()
	if OS.has_feature("web"):
		var backups: Array = library.filter(func(item: Dictionary): return item.get("autosave",false))
		var payload := JSON.stringify(backups)
		var backed_up := bool(JavaScriptBridge.eval("(function(){try{localStorage.setItem('hopan.editor.autosaves.v1', " + JSON.stringify(payload) + ");return true;}catch(e){return false;}})()",true))
		if not backed_up:
			status("Autosave saved locally; immediate browser backup unavailable. Export for a portable copy.")
			return true
	status("Autosave checkpoint: " + str(level.name) + " · Recover from Load a local level.")
	return true

func reset_touch() -> void:
	thumb = Vector2.ZERO
	skate_jump_touch = false
	skate_brake_touch = false
	skate_grind_touch = false
	touch_index = -1
	tile_touch_queued = false
	if is_instance_valid(touch_knob):
		touch_knob.position = Vector2(42, 42)

func activate_long_hop() -> void:
	if level.get("city_journey",{}).get("movement") == "skate":
		long_hop_button.set_pressed_no_signal(false)
		return
	if world.tile_rules == null or mode not in ["play","test"] or overlay.visible or world.halted or world.map_view or world.intro_active or not world.result.is_empty():
		long_hop_button.set_pressed_no_signal(false)
		return
	if not world.tile_rules.long_hop_ready():
		long_hop_button.set_pressed_no_signal(false)
		show_level_rules(false)
	else:
		status("Choose a direction for two tiles. " + LevelRules.short_rule(level) + ".")

func update_long_hop_indicator() -> void:
	var journey: bool = not level.get("city_journey",{}).is_empty() and mode in ["play","test"]
	var playing: bool = journey and not overlay.visible and not world.map_view and world.result.is_empty()
	brake_button.visible = playing
	grind_button.visible = playing and level.city_journey.get("movement") == "skate"
	grind_button.position = view_container.global_position + Vector2(maxf(8,view_container.size.x-180),maxf(80,view_container.size.y-216))
	grind_button.size = Vector2(166,56)
	grind_button.text = "GRINDING · Jump off" if journey and is_instance_valid(world.journey) and world.journey.grind_index>=0 else "Grind · G"
	grind_button.tooltip_text = "Hold near an aligned rail to latch. Jump or Brake leaves it."
	brake_button.position = view_container.global_position + Vector2(maxf(8,view_container.size.x-180),maxf(96,view_container.size.y-146))
	brake_button.size = Vector2(166,56)
	if journey:
		long_hop_button.visible = playing and level.city_journey.get("movement") == "skate"
		long_hop_help.visible = long_hop_button.visible and not mobile_ui
		long_hop_button.position = view_container.global_position + Vector2(maxf(8,view_container.size.x-180),maxf(96,view_container.size.y-76))
		long_hop_button.size = Vector2(166,64)
		if mobile_ui:
			var origin := view_container.global_position
			var right := maxf(8,view_container.size.x-164)
			grind_button.position = origin+Vector2(right,maxf(108,view_container.size.y-174))
			brake_button.position = origin+Vector2(right,maxf(164,view_container.size.y-118))
			long_hop_button.position = origin+Vector2(right,maxf(220,view_container.size.y-62))
			for control in [grind_button,brake_button,long_hop_button]: control.size=Vector2(156,50)
		long_hop_help.position = long_hop_button.position - Vector2(10,258)
		long_hop_help.size = Vector2(186,42)
		long_hop_help.text = "Hold G near a rail to latch\nSpace jumps off · Shift brakes"
		long_hop_indicator.text = "OLLIE"
		return
	long_hop_help.visible = long_hop_button.visible and not overlay.visible and not world.map_view and world.result.is_empty()
	if not long_hop_button.visible or world.tile_rules == null: return
	long_hop_button.position = view_container.global_position + Vector2(maxf(8,view_container.size.x-180),maxf(96,view_container.size.y-76))
	long_hop_button.size = Vector2(166,64)
	long_hop_help.position = long_hop_button.position - Vector2(10,44)
	long_hop_help.size = Vector2(186,42)
	long_hop_button.disabled = paused or world.halted or world.map_view or world.intro_active or not world.result.is_empty()
	var state := "READY"
	if paused or world.halted or world.map_view: state = "PAUSED"
	elif world.intro_active or not world.active or overlay.visible: state = "WAIT"
	elif world.tile_rules.jumping: state = "HOPPING"
	elif not world.tile_rules.long_hop_ready(): state = world.tile_rules.resource_label()
	elif not world.tile_rules.ready_for_input(): state = "WAIT"
	elif long_hop_button.button_pressed or Input.is_physical_key_pressed(KEY_SHIFT): state = "ARMED"
	long_hop_indicator.text = state
	long_hop_help.text = ("Choose a direction" if state == "ARMED" else ("Tap, then move" if mobile_ui else "Space, then a direction")) + "\n" + LevelRules.short_rule(level)
	long_hop_indicator.add_theme_color_override("font_color", LIME if state in ["READY", "ARMED"] else MUTED)

func _process(delta: float) -> void:
	if editor_autosave_due and mode == "edit" and not stroke:
		editor_autosave_due = false
		save_editor_checkpoint()
	if not is_instance_valid(world) or level.is_empty():
		return
	if OS.has_feature("web"):
		var unsaved := editor_session_active and editor_has_unsaved_changes()
		if unsaved != last_browser_unsaved:
			last_browser_unsaved = unsaved
			JavaScriptBridge.eval("window.hopanEditorUnsaved=" + ("true" if unsaved else "false"),true)
	if browser_test:
		probe_timer += delta
		if probe_timer > (0.05 if level.width<=25 else 0.2):
			probe_timer = 0
			publish_browser_probe()
	if view_container.size != last_view_size or view.size != last_render_size:
		last_view_size = view_container.size
		last_render_size = view.size
		configure_view()
		world.fit_camera()
		configure_splash_layout()
	return_editor_button.visible = mode == "test" and not overlay.visible
	return_editor_button.position = view_container.global_position + Vector2(12, 52)
	rule_button.visible = mode in ["play", "test"] and not overlay.visible and world.result.is_empty()
	rule_button.position = view_container.global_position + Vector2(maxf(0, view_container.size.x - 86), 52)
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
	var controls_active: bool = mode in ["play", "test"] and not overlay.visible and not typing and not world.map_view and not world.halted and not world.intro_active
	world.grind_input = controls_active and (Input.is_physical_key_pressed(KEY_G) or skate_grind_touch)
	world.brake_input = controls_active and (Input.is_physical_key_pressed(KEY_SHIFT) or skate_brake_touch)
	world.long_hop_input = controls_active and ((Input.is_physical_key_pressed(KEY_SPACE) or skate_jump_touch) if level.get("city_journey",{}).get("movement") == "skate" else (Input.is_physical_key_pressed(KEY_SHIFT) or long_hop_button.button_pressed))
	update_long_hop_indicator()
	time_label.text = "%.1fs  /  %d croaks" % [world.elapsed, deaths] if mode in ["play", "test"] else "%d × %d · v1 JSON" % [level.width, level.height]
	if mode == "edit" and not overlay.visible:
		var local := viewport_position(get_global_mouse_position())
		var cell: Vector2i = world.pick(local)
		world.show_cursor(cell if view_container.get_global_rect().has_point(get_global_mouse_position()) else Vector2i(-999, -999), tool.begins_with("landmark_") or tool in ["backdrop", "select", "erase"])
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
			configure_splash_layout()

func publish_browser_probe() -> void:
	# Read-only diagnostics in explicitly requested debug exports. Browser tests
	# still interact through actual mouse, keyboard and touch events.
	var buttons: Array = []
	for node in find_children("*", "Button", true, false):
		if node.is_visible_in_tree() and (not overlay.visible or overlay.is_ancestor_of(node)):
			var rect: Rect2 = node.get_global_rect()
			buttons.append({"text": node.text, "x": rect.get_center().x, "y": rect.get_center().y})
	var fields: Array = []
	for control in inspector.get_children():
		if control is SpinBox and control.is_visible_in_tree():
			var rect: Rect2 = control.get_global_rect()
			fields.append({"suffix":control.suffix,"value":control.value,"x":rect.position.x,"y":rect.position.y,"w":rect.size.x,"h":rect.size.y})
	var cells: Array = []
	for z in range(int(level.height)):
		var cell_row: Array = []
		for x in range(int(level.width)):
			var p: Vector2 = world.camera.unproject_position(world.cell_position([x, z])) * view_container.size / Vector2(view.size) + view_container.global_position
			cell_row.append([p.x, p.y])
		cells.append(cell_row)
	var backdrop_points: Array = []
	for point in [[-2,8],[level.width+1,8]]:
		var screen: Vector2 = world.camera.unproject_position(world.cell_position(point)) * view_container.size / Vector2(view.size) + view_container.global_position
		backdrop_points.append({"cell":point,"x":screen.x,"y":screen.y})
	var state := {"mode": mode, "overlay": overlay.visible, "paused": paused, "result": world.result, "elapsed": world.elapsed, "deaths": deaths,
		"menu_panel": {"children":overlay_box.get_child_count(),"height":overlay_panel.size.y,"width":overlay_panel.size.x,"scroll":overlay_layout.get_parent().scroll_vertical},
		"city_progress": city_progress, "city_traffic": world.traffic.vehicles.size(), "city_skaters": world.skaters.size(), "campaign_set": campaign_set, "completed_bonus_stages": completed_bonus_stages, "completed_sync_stages": completed_sync_stages, "human_set_unlocked": human_set_unlocked(), "completed_human_stages": completed_human_stages,
		"hat": hat, "skin": skin, "unlocked_hats": unlocked_hats, "completed_stages": completed_stages, "checkpoint": checkpoint_spawn, "stage": builtin_index,
		"player": [world.player.position.x, world.player.position.z], "map": level, "buttons": buttons, "cells": cells, "lane_tunnels": world.lane_tunnel_plans,
		"hop_audio": {"unlocked":hop_audio.unlocked,"history":hop_audio.history,"gain":hop_audio.gain,"palette":hop_audio.palette,"playing":hop_audio.takeoff.playing or hop_audio.landing.playing,"db":hop_audio.takeoff.volume_db}, "hop_pose":world.hop_pose_style,"pose_phase":world.player.pose_phase,
		"hop_volume_rect": [hop_volume_slider.global_position.x,hop_volume_slider.global_position.y,hop_volume_slider.size.x,hop_volume_slider.size.y] if is_instance_valid(hop_volume_slider) and hop_volume_slider.is_visible_in_tree() else [],
		"editor_unsaved":editor_has_unsaved_changes(),"editor_leave_open":editor_leave_open,
		"ui_size": [size.x, size.y], "saved": library.size(), "status": status_label.text, "fields": fields, "editor_changes": editor_change_counts.get(str(level.get("editor_autosave_id","")),0), "tool": tool, "selection": selection, "fps": Engine.get_frames_per_second(),
		"voice_history": voice.history, "voice_playing": voice.player.playing, "voice_queue": voice.queue, "voice_gesture": voice.gesture_received, "sound_enabled": sound_enabled, "begin_pending": begin_pending, "return_warning_armed": return_warning_armed,
		"exit_preview": exit_preview, "intro_active": world.intro_active, "intro_time": world.intro_time, "result_time": world.result_time,
		"camera_target": [world.camera_target.x, world.camera_target.y, world.camera_target.z], "pose_y": world.player.visual.position.y,
		"park_poses":world.park_hazards.encounters.map(func(e): return {"kind":e.kind,"state":e.state,"time":e.time}) if is_instance_valid(world.park_hazards) else [], "stunt_poses":world.skaters.filter(func(r):return not r.stunt_spec.is_empty()).map(func(r):return {"state":r.state,"height":r.height,"lap":r.stunt_lap,"position":[r.position.x,r.position.y,r.position.z]}), "journey": world.journey.stats() if is_instance_valid(world.journey) else {}, "backdrops": world.backdrops.stats() if is_instance_valid(world.backdrops) else {}, "landmarks": world.landmarks.stats() if is_instance_valid(world.landmarks) else {}, "background_view": world.background_view, "backdrop_points": backdrop_points, "rule_notice": rule_notice_open, "seen_rules": seen_rule_ids, "charge_remaining": world.tile_rules.charge_remaining if world.tile_rules != null else 0, "hop_resource": world.tile_rules.checkpoint_state() if world.tile_rules != null else {}, "hop_help":long_hop_help.text, "long_hops_used":world.tile_rules.long_hops_used if world.tile_rules != null else 0, "splash_menu": splash_menu, "splash_variant": splash_variant, "splash_portrait": splash_art.texture in [SPLASH_PORTRAIT, SPLASH_LAYERED_PORTRAIT], "long_hop_state": long_hop_indicator.text if long_hop_button.visible else "", "tile_mode": world.tile_rules != null, "tile_hops": world.tile_rules.hop_count if world.tile_rules != null else 0, "tile_beats": world.tile_rules.beat_count if world.tile_rules != null else 0, "hop_active": world.tile_rules.jumping if world.tile_rules != null else false, "hop_airborne": world.tile_rules.airborne() if world.tile_rules != null else false, "tile_unlocked": tile_mode_unlocked(), "compatibility_mode": compatibility_mode, "map_view": world.map_view, "projection": world.camera.projection, "render_size": [view.size.x, view.size.y], "retro": view_container.material != null, "msaa_3d": int(view.msaa_3d), "view_filter": int(view_container.texture_filter), "stretch_shrink": view_container.stretch_shrink}
	JavaScriptBridge.eval("window.hopanState = " + JSON.stringify(state), true)

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) and event.is_pressed():
		voice.unlock()
		hop_audio.unlocked = true
	if not is_instance_valid(world):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if editor_leave_open:
			if event.keycode == KEY_ESCAPE:
				cancel_editor_navigation()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_R: get_viewport().set_input_as_handled()
			return
		if restart_confirmation_open:
			if event.keycode == KEY_ESCAPE:
				show_pause_overlay()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_R:
				get_viewport().set_input_as_handled()
			return
		if rule_notice_open:
			if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
				close_level_rules()
				get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F1 and mode in ["play", "test"] and not overlay.visible:
			show_level_rules(false)
			get_viewport().set_input_as_handled()
			return
	if world.intro_active and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		world.cancel_exit_preview()
		get_viewport().set_input_as_handled()
		return
	var focused := get_viewport().gui_get_focus_owner()
	if event is InputEventKey and event.pressed and not event.echo and not (focused is LineEdit or focused is TextEdit):
		if world.tile_rules != null and mode in ["play","test"] and not overlay.visible and not world.map_view and not world.intro_active:
			if event.keycode == KEY_SPACE:
				long_hop_button.set_pressed_no_signal(not long_hop_button.button_pressed)
				activate_long_hop()
				get_viewport().set_input_as_handled()
				return
			var directions := {KEY_W:Vector2i.UP,KEY_UP:Vector2i.UP,KEY_S:Vector2i.DOWN,KEY_DOWN:Vector2i.DOWN,KEY_A:Vector2i.LEFT,KEY_LEFT:Vector2i.LEFT,KEY_D:Vector2i.RIGHT,KEY_RIGHT:Vector2i.RIGHT}
			if event.keycode in directions:
				world.tile_rules.queue_hop(directions[event.keycode],event.shift_pressed or long_hop_button.button_pressed)
		if event.keycode == KEY_ESCAPE:
			if mode in ["play", "test"]:
				toggle_pause()
			elif overlay.visible:
				if mode == "edit": editor_session_active = true
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
		if world.tile_rules != null and not tile_touch_queued and thumb.length() > 0.3 and not overlay.visible and not world.map_view:
			var direction := Vector2i(signi(int(signf(thumb.x))),0) if absf(thumb.x) >= absf(thumb.y) else Vector2i(0,signi(int(signf(thumb.y))))
			world.tile_rules.queue_hop(direction,long_hop_button.button_pressed)
			tile_touch_queued = true
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

# Stable stored indices preserve old Skate Escape clears at index1.
func journey_order() -> Array:
	return [0,2,1]

func campaign_stage_number() -> int:
	return journey_order().find(builtin_index)+1 if campaign_set == "city_journey" else builtin_index+1

func next_campaign_index() -> int:
	if campaign_set == "city_journey":
		var position := journey_order().find(builtin_index)
		return journey_order()[position+1] if position >= 0 and position+1<journey_order().size() else -1
	return builtin_index+1 if builtin_index+1<campaign_paths().size() else -1

func paths_for_set(set_key: String) -> Array:
	match set_key:
		"baby": return BUILTINS
		"human": return HUMAN_LEVELS
		"sync": return SYNC_LEVELS
		"tile": return TILE_LEVELS
		"bonus": return BONUS_LEVELS
		"nyc": return NYC_LEVELS
		"streetlife": return STREETLIFE_LEVELS
		"city_journey": return JOURNEY_LEVELS
	return []

func progress_for_set(set_key: String = "") -> Array:
	match campaign_set if set_key.is_empty() else set_key:
		"human": return completed_human_stages
		"sync": return completed_sync_stages
		"tile": return completed_tile_stages
		"bonus": return completed_bonus_stages
		"nyc": return city_progress.nyc
		"streetlife": return city_progress.streetlife
		"city_journey": return city_progress.city_journey
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
	for i in (journey_order() if set_key == "city_journey" else range(paths.size())):
		var index: int = i
		var stage := Data.load_json(paths[i])
		if not stage.is_empty():
			var locked: bool = set_key == "city_journey" and index in [1,2] and 0 not in city_progress.city_journey
			var stage_button := button(stages, ("Locked · " if locked else "Play · ") + str(stage.name), func(): play_builtin(index, set_key))
			stage_button.disabled = locked
			if locked: stage_button.tooltip_text = "Finish Blocks & Park to unlock this level."
