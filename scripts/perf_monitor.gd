extends CanvasLayer
# Phone performance measurement (Settings → Performance test).
# Records every frame's time for a fixed duration while the player keeps
# playing, then shows FPS, frame time (ms) and memory (MB) for a screenshot.
# Every result is also appended to user://perf_log.csv.

const LOG_PATH := "user://perf_log.csv"
var overlay: Label
var result_box: Control
var running := false
var duration := 60.0
var elapsed := 0.0
var frame_times: Array[float] = []
var peak_memory := 0.0
var scene_name := ""

func _ready() -> void:
	layer = 100
	overlay = Aura.label(self, "", Rect2(12, 8, 520, 34), 22, Color("3b2f63"))
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.75)
	bg.set_corner_radius_all(10)
	bg.content_margin_left = 10
	bg.content_margin_right = 10
	overlay.add_theme_stylebox_override("normal", bg)
	refresh_visibility()

func refresh_visibility() -> void:
	overlay.visible = Aura.show_fps or running

func start_test(seconds: float) -> void:
	if result_box: result_box.queue_free()
	duration = seconds
	elapsed = 0.0
	frame_times.clear()
	peak_memory = 0.0
	var scene := get_tree().current_scene
	scene_name = scene.name if scene else "?"
	if scene and "level_number" in scene:
		scene_name = "Chapter %d" % scene.level_number if scene.level_number > 0 else "Creative Studio"
	running = true
	refresh_visibility()

func _process(delta: float) -> void:
	var memory := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	if running:
		elapsed += delta
		frame_times.append(delta * 1000.0)
		peak_memory = maxf(peak_memory, memory)
		if elapsed >= duration:
			running = false
			_show_result()
	if overlay.visible:
		var text := "%d FPS · %.1f ms · %.0f MB" % [Engine.get_frames_per_second(), delta * 1000.0, memory]
		if running: text += " · test %d s" % ceili(duration - elapsed)
		overlay.text = text
	refresh_visibility()

func summary() -> Dictionary:
	var total := 0.0
	var worst := 0.0
	var slow := 0
	for ms in frame_times:
		total += ms
		worst = maxf(worst, ms)
		if ms > 1000.0 / 55.0: slow += 1
	var count := maxi(frame_times.size(), 1)
	return {
		"device": OS.get_model_name(), "os": "%s %s" % [OS.get_name(), OS.get_version()],
		"scene": scene_name, "seconds": snappedf(total / 1000.0, 0.1), "frames": frame_times.size(),
		"avg_fps": snappedf(1000.0 * count / maxf(total, 0.001), 0.1),
		"avg_ms": snappedf(total / count, 0.01), "max_ms": snappedf(worst, 0.01),
		"slow_pct": snappedf(100.0 * slow / count, 0.1), "memory_mb": snappedf(peak_memory, 0.1),
	}

func _show_result() -> void:
	var r := summary()
	var file := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
	if file:
		if file.get_length() == 0:
			file.store_line("date,device,os,scene,seconds,frames,avg_fps,avg_frame_ms,max_frame_ms,slow_frames_pct,peak_memory_mb")
		file.seek_end()
		file.store_line("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s" % [Time.get_datetime_string_from_system(), r.device, r.os, r.scene, r.seconds, r.frames, r.avg_fps, r.avg_ms, r.max_ms, r.slow_pct, r.memory_mb])
	result_box = Aura.panel(self, Rect2(Aura.margin_x + 290, 120, 700, 520))
	Aura.label(result_box, "Performance test result", Rect2(24, 16, 650, 46), 32)
	var lines := "Device: %s (%s)\\nScene: %s\\nDuration: %s s, %d frames\\nAverage: %s FPS (%s ms per frame)\\nWorst frame: %s ms\\nFrames slower than 55 FPS: %s %%\\nPeak memory: %s MB\\nTool: Godot Performance monitors, %s" % [r.device, r.os, r.scene, r.seconds, r.frames, r.avg_fps, r.avg_ms, r.max_ms, r.slow_pct, r.memory_mb, Time.get_datetime_string_from_system(false, true)]
	Aura.paragraph(result_box, lines.replace("\\n", "\n"), Rect2(24, 76, 650, 330), 24)
	Aura.button(result_box, "Close", Rect2(24, 420, 652, 80), func():
		result_box.queue_free()
		result_box = null)
