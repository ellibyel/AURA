extends Node

const SAVE_PATH := "user://aura_progress.cfg"
const CREAM := Color("faf5ec")
const INK := Color("393346")
const GOLD := Color("ae8749")
const PURPLE := Color("837495")
# Secondary text colour: dark enough to read on the lavender scenery (about 7:1).
const MUTED := Color("4d4160")
const SOUNDS := {
	"place": "res://assets/audio/kenney/glass_001.ogg",
	"rotate": "res://assets/audio/kenney/pluck_001.ogg",
	"win": "res://assets/audio/kenney/jingles_STEEL00.ogg",
}
# Drop the team's own loop here; the game runs without music until it exists.
const MUSIC_PATH := "res://assets/audio/music/ambience.ogg"
signal motion_changed
signal layout_changed
# Wide phones (iPhone ~19.5:9) get extra width instead of black bars: the
# 1280x800 layout is centred and only the background fills the sides.
const DESIGN := Vector2(1280, 800)
const LEVEL_COUNT := 8
const GAME_SCENE := "res://scenes/game.tscn"
var margin_x := 0.0
# Best reward (0-3 stars) per chapter; chapters unlock one after another.
var best: Array = []
var unlocked := 1
var current_level := 1
# Page the main menu opens on ("chapters" when returning from a level).
var menu_page := ""
var vibration := true
var tilt_rotate := false
var show_fps := false
var perf: CanvasLayer
var sfx_volume := 0.7
var music_volume := 0.3
var reduced_motion := false
var tutorial := true
var save_error := ""
var music: AudioStreamPlayer
var voices: Dictionary = {}

func _ready() -> void:
	best.resize(LEVEL_COUNT)
	best.fill(0)
	load_progress()
	perf = load("res://scripts/perf_monitor.gd").new()
	add_child(perf)
	get_tree().root.size_changed.connect(apply_layout)
	apply_layout()
	music = AudioStreamPlayer.new()
	add_child(music)
	if ResourceLoader.exists(MUSIC_PATH):
		var stream := load(MUSIC_PATH) as AudioStreamOggVorbis
		stream.loop = true
		music.stream = stream
		music.play()
	for key in SOUNDS:
		var voice := AudioStreamPlayer.new()
		voice.stream = load(SOUNDS[key])
		add_child(voice)
		voices[key] = voice
	apply_audio()

func apply_layout() -> void:
	var width := get_tree().root.get_visible_rect().size.x
	margin_x = maxf(0.0, (width - DESIGN.x) / 2.0)
	get_tree().root.canvas_transform = Transform2D(0.0, Vector2(margin_x, 0.0))
	layout_changed.emit()

func has_music() -> bool:
	return music.stream != null

# Freezes editor-authored animation (AnimationPlayer / AnimatedSprite2D) in a scene.
func apply_motion(root: Node) -> void:
	for player in root.find_children("*", "AnimationPlayer", true, false):
		if reduced_motion and player.is_playing() and player.get_animation(player.current_animation).loop_mode == Animation.LOOP_NONE:
			player.seek(player.current_animation_length, true)
		player.speed_scale = 0.0 if reduced_motion else 1.0
	for sprite in root.find_children("*", "AnimatedSprite2D", true, false):
		sprite.speed_scale = 0.0 if reduced_motion else 1.0
	for particles in root.find_children("*", "CPUParticles2D", true, false):
		particles.speed_scale = 0.0 if reduced_motion else 1.0

func apply_audio() -> void:
	music.volume_db = linear_to_db(maxf(music_volume, 0.0001)) - 7.0
	for voice in voices.values():
		voice.volume_db = linear_to_db(maxf(sfx_volume, 0.0001)) - 5.0

func sound(key: String) -> void:
	if sfx_volume > 0.0 and voices.has(key):
		voices[key].play()

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for i in range(LEVEL_COUNT):
		best[i] = clampi(int(cfg.get_value("progress", "level_%d" % (i + 1), 0)), 0, 3)
	# Assignment 3 saves: chapter 1 is unchanged, the old chapter 2 was replaced.
	if cfg.has_section_key("progress", "stars_0") and best[0] == 0:
		best[0] = clampi(int(cfg.get_value("progress", "stars_0", 0)), 0, 3)
	_update_unlocked()
	vibration = bool(cfg.get_value("settings", "vibration", true))
	tilt_rotate = bool(cfg.get_value("settings", "tilt_rotate", false))
	show_fps = bool(cfg.get_value("settings", "show_fps", false))
	sfx_volume = clampf(float(cfg.get_value("settings", "sfx", 0.7)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("settings", "music", 0.3)), 0.0, 1.0)
	reduced_motion = bool(cfg.get_value("settings", "reduced_motion", false))
	tutorial = bool(cfg.get_value("settings", "tutorial", true))

func save_progress() -> void:
	var cfg := ConfigFile.new()
	for i in range(LEVEL_COUNT):
		cfg.set_value("progress", "level_%d" % (i + 1), best[i])
	cfg.set_value("settings", "vibration", vibration)
	cfg.set_value("settings", "tilt_rotate", tilt_rotate)
	cfg.set_value("settings", "show_fps", show_fps)
	cfg.set_value("settings", "sfx", sfx_volume)
	cfg.set_value("settings", "music", music_volume)
	cfg.set_value("settings", "reduced_motion", reduced_motion)
	cfg.set_value("settings", "tutorial", tutorial)
	save_error = "" if cfg.save(SAVE_PATH) == OK else "Progress could not be saved on this device."

func complete(level: int, rating: int) -> void:
	best[level - 1] = maxi(int(best[level - 1]), rating)
	_update_unlocked()
	save_progress()

func reset_progress() -> void:
	best.fill(0)
	_update_unlocked()
	save_progress()

func _update_unlocked() -> void:
	unlocked = 1
	while unlocked < LEVEL_COUNT and int(best[unlocked - 1]) > 0:
		unlocked += 1

func total_stars() -> int:
	var total := 0
	for value in best: total += int(value)
	return total

# 0 opens Creative Studio; 1..LEVEL_COUNT open a chapter.
func start_level(number: int) -> void:
	if number > unlocked: return
	current_level = number
	get_tree().change_scene_to_file(GAME_SCENE)

func haptic(ms: int) -> void:
	if vibration: Input.vibrate_handheld(ms)

func label(parent: Node, text: String, rect: Rect2, size: int = 24, color: Color = INK) -> Label:
	var item := Label.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func paragraph(parent: Node, text: String, rect: Rect2, size: int = 24) -> Label:
	var item := Label.new()
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", INK)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.text = text
	item.position = rect.position
	item.size = rect.size
	parent.add_child(item)
	return item

func style(fill: Color = CREAM) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = Color("cbb995")
	box.set_border_width_all(1)
	box.set_corner_radius_all(14)
	box.content_margin_left = 12
	box.content_margin_right = 12
	return box

func button(parent: Node, text: String, rect: Rect2, action: Callable, size: int = 26) -> Button:
	var item := Button.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.focus_mode = Control.FOCUS_NONE
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", INK)
	item.add_theme_color_override("font_hover_color", INK)
	item.add_theme_color_override("font_pressed_color", INK)
	item.add_theme_color_override("font_disabled_color", Color("7a7180"))
	item.add_theme_stylebox_override("normal", style())
	item.add_theme_stylebox_override("hover", style(Color("fffaf2")))
	item.add_theme_stylebox_override("pressed", style(Color("e9ddc7")))
	item.add_theme_stylebox_override("hover_pressed", style(Color("e9ddc7")))
	item.add_theme_color_override("font_hover_pressed_color", INK)
	item.add_theme_stylebox_override("disabled", style(Color("e1dce3")))
	parent.add_child(item)
	item.pressed.connect(action)
	return item

func panel(parent: Node, rect: Rect2) -> Panel:
	var item := Panel.new()
	item.position = rect.position
	item.size = rect.size
	item.add_theme_stylebox_override("panel", style())
	parent.add_child(item)
	return item

func toggle(parent: Node, rect: Rect2, title: String, value: bool, on_change: Callable) -> Button:
	var item := button(parent, "", rect, func(): pass, 24)
	item.toggle_mode = true
	item.button_pressed = value
	item.text = title + (": On" if value else ": Off")
	item.toggled.connect(func(state: bool):
		item.text = title + (": On" if state else ": Off")
		on_change.call(state))
	return item

func open_settings(parent: Node, on_close: Callable = Callable()) -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.15, 0.12, 0.22, 0.55)
	overlay.position = Vector2(-640, 0)
	overlay.size = Vector2(2560, 800)
	parent.add_child(overlay)
	var box := panel(overlay, Rect2(780, 50, 1000, 650))
	label(box, "Settings", Rect2(32, 16, 900, 50), 34)
	for i in range(2):
		var y := 86 + i * 92
		label(box, "Sound effects" if i == 0 else "Music", Rect2(32, y + 18, 200, 40), 26)
		if i == 1 and not has_music():
			label(box, "not added yet", Rect2(236, y + 20, 240, 40), 24, MUTED)
			continue
		var value := label(box, "", Rect2(316, y + 18, 84, 40), 26)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var show := func(): value.text = "%d%%" % roundi((sfx_volume if i == 0 else music_volume) * 100)
		show.call()
		for step in [-0.1, 0.1]:
			button(box, "–" if step < 0 else "+", Rect2(236 if step < 0 else 400, y, 80, 76), func():
				if i == 0: sfx_volume = clampf(snappedf(sfx_volume + step, 0.1), 0.0, 1.0)
				else: music_volume = clampf(snappedf(music_volume + step, 0.1), 0.0, 1.0)
				apply_audio()
				show.call()
				if i == 0: sound("rotate"), 34)
	toggle(box, Rect2(32, 270, 448, 76), "Reduce animation", reduced_motion, func(v: bool):
		reduced_motion = v
		motion_changed.emit())
	toggle(box, Rect2(32, 362, 448, 76), "Tutorial tips", tutorial, func(v: bool): tutorial = v)
	toggle(box, Rect2(520, 86, 448, 76), "Vibration", vibration, func(v: bool):
		vibration = v
		haptic(40))
	toggle(box, Rect2(520, 178, 448, 76), "Tilt to rotate", tilt_rotate, func(v: bool): tilt_rotate = v)
	toggle(box, Rect2(520, 270, 448, 76), "Show FPS", show_fps, func(v: bool):
		show_fps = v
		perf.refresh_visibility())
	button(box, "Performance test (60 s)", Rect2(520, 362, 448, 76), func():
		save_progress()
		overlay.queue_free()
		if on_close.is_valid(): on_close.call()
		perf.start_test(60.0), 24)
	label(box, "Tilt to rotate: tilt the phone left or right to turn the selected mirror.", Rect2(32, 456, 936, 40), 22, MUTED)
	button(box, "Save & return", Rect2(32, 530, 936, 80), func():
		save_progress()
		overlay.queue_free()
		if on_close.is_valid(): on_close.call())
	return overlay

func _exit_tree() -> void:
	if music: music.stop()
	for voice in voices.values(): voice.stop()
