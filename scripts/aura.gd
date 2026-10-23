extends Node

const SAVE_PATH := "user://aura_progress.cfg"
const CREAM := Color("faf5ec")
const INK := Color("393346")
const GOLD := Color("ae8749")
const PURPLE := Color("837495")
var best: Array = [0, 0]
var unlocked := 1
var sfx_volume := 0.7
var music_volume := 0.3
var reduced_motion := false
var tutorial := true
var save_error := ""
var music: AudioStreamPlayer
var voices: Dictionary = {}

func _ready() -> void:
	load_progress()
	music = AudioStreamPlayer.new()
	var stream := load("res://assets/ambience.wav") as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	music.stream = stream
	add_child(music)
	music.play()
	for key in ["place", "rotate", "win"]:
		var voice := AudioStreamPlayer.new()
		voice.stream = load("res://assets/%s.wav" % key)
		add_child(voice)
		voices[key] = voice
	apply_audio()

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
	for i in range(2):
		best[i] = clampi(int(cfg.get_value("progress", "stars_%d" % i, 0)), 0, 3)
	unlocked = 2 if int(best[0]) > 0 else 1
	sfx_volume = clampf(float(cfg.get_value("settings", "sfx", 0.7)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("settings", "music", 0.3)), 0.0, 1.0)
	reduced_motion = bool(cfg.get_value("settings", "reduced_motion", false))
	tutorial = bool(cfg.get_value("settings", "tutorial", true))

func save_progress() -> void:
	var cfg := ConfigFile.new()
	for i in range(2):
		cfg.set_value("progress", "stars_%d" % i, best[i])
	cfg.set_value("settings", "sfx", sfx_volume)
	cfg.set_value("settings", "music", music_volume)
	cfg.set_value("settings", "reduced_motion", reduced_motion)
	cfg.set_value("settings", "tutorial", tutorial)
	save_error = "" if cfg.save(SAVE_PATH) == OK else "Progress could not be saved on this device."

func complete(level: int, rating: int) -> void:
	best[level - 1] = maxi(int(best[level - 1]), rating)
	unlocked = 2
	save_progress()

func reset_progress() -> void:
	best = [0, 0]
	unlocked = 1
	save_progress()

func label(parent: Node, text: String, rect: Rect2, size: int = 20, color: Color = INK) -> Label:
	var item := Label.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func paragraph(parent: Node, text: String, rect: Rect2, size: int = 19) -> Label:
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
	box.content_margin_left = 16
	box.content_margin_right = 16
	return box

func button(parent: Node, text: String, rect: Rect2, action: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.focus_mode = Control.FOCUS_NONE
	item.add_theme_font_size_override("font_size", 19)
	item.add_theme_color_override("font_color", INK)
	item.add_theme_color_override("font_hover_color", INK)
	item.add_theme_color_override("font_pressed_color", INK)
	item.add_theme_color_override("font_disabled_color", Color("948c97"))
	item.add_theme_stylebox_override("normal", style())
	item.add_theme_stylebox_override("hover", style(Color("fffaf2")))
	item.add_theme_stylebox_override("pressed", style(Color("e9ddc7")))
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

func open_settings(parent: Node, on_close: Callable = Callable()) -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.15, 0.12, 0.22, 0.55)
	overlay.size = Vector2(1280, 800)
	parent.add_child(overlay)
	var box := panel(overlay, Rect2(370, 135, 540, 530))
	label(box, "Make yourself at home", Rect2(32, 20, 480, 50), 28)
	for i in range(2):
		label(box, "Sound effects" if i == 0 else "Background music", Rect2(32, 94 + i * 85, 450, 30))
		var slider := HSlider.new()
		slider.position = Vector2(32, 133 + i * 85)
		slider.size = Vector2(475, 30)
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = sfx_volume if i == 0 else music_volume
		box.add_child(slider)
		slider.value_changed.connect(func(value: float):
			if i == 0: sfx_volume = value
			else: music_volume = value
			apply_audio())
	var motion := CheckButton.new()
	motion.text = "Reduce animation"
	motion.position = Vector2(32, 290)
	motion.size = Vector2(470, 50)
	motion.button_pressed = reduced_motion
	motion.add_theme_color_override("font_color", INK)
	motion.add_theme_color_override("font_hover_color", INK)
	motion.add_theme_color_override("font_pressed_color", INK)
	motion.add_theme_color_override("font_hover_pressed_color", INK)
	motion.add_theme_color_override("font_focus_color", INK)
	box.add_child(motion)
	motion.toggled.connect(func(value: bool): reduced_motion = value)
	var tips := CheckButton.new()
	tips.text = "Show tutorial guidance"
	tips.position = Vector2(32, 355)
	tips.size = Vector2(470, 50)
	tips.button_pressed = tutorial
	tips.add_theme_color_override("font_color", INK)
	tips.add_theme_color_override("font_hover_color", INK)
	tips.add_theme_color_override("font_pressed_color", INK)
	tips.add_theme_color_override("font_hover_pressed_color", INK)
	tips.add_theme_color_override("font_focus_color", INK)
	box.add_child(tips)
	tips.toggled.connect(func(value: bool): tutorial = value)
	button(box, "Save & return", Rect2(32, 442, 476, 56), func():
		save_progress()
		overlay.queue_free()
		if on_close.is_valid(): on_close.call())
	return overlay

func _exit_tree() -> void:
	if music: music.stop()
	for voice in voices.values(): voice.stop()
