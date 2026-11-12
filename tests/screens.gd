extends Node
# Saves screenshots of the main screens (for the GDD and layout checks).
@export var out_dir := "/private/tmp/claude-501/-Users-elli-by-el-Desktop-AURA-Assignment3/5c5d3883-6efb-4ad0-80f9-99a7a261b932/scratchpad/shots4"
func shot(name: String) -> void:
	for i in range(10): await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
func level(n: int) -> Node:
	Aura.current_level = n
	var l = load(Aura.GAME_SCENE).instantiate()
	add_child(l)
	return l
func _ready() -> void:
	Aura.reset_progress()
	for i in range(Aura.LEVEL_COUNT - 2): Aura.complete(i + 1, 3 - i % 3)
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await shot("menu")
	menu.show_chapters()
	await shot("chapters")
	menu.queue_free()
	var l = level(5)
	var sol: Array = l.level_data.solution
	for i in range(sol.size() - 1):
		l.board_tap(l.grid_center(sol[i][0], sol[i][1]))
		l.rotate_selected(sol[i][2])
	await shot("gameplay")
	l.show_hint()
	await shot("hint")
	l.show_hint()
	await shot("ad_offer")
	l.ui._play_ad()
	await shot("ad")
	l.queue_free()
	var w = level(6)
	for s in w.level_data.solution:
		w.board_tap(w.grid_center(s[0], s[1]))
		w.rotate_selected(s[2])
	await get_tree().create_timer(2.0).timeout
	await shot("win")
	w.ui.success.queue_free(); w.ui.success = null
	w.ui.open_pause()
	Aura.open_settings(w.ui)
	await shot("settings")
	Aura.reset_progress()
	get_tree().quit()
