extends Node
# Saves screenshots of the main screens (for slides and layout checks).
func shot(name: String) -> void:
	for i in range(8): await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/private/tmp/claude-501/-Users-elli-by-el-Library-Application-Support-Claude-scratch-workspaces-5dc6122c-d459-4d1b-b906-fbcf7bec2d22-c2f7176a-e850-4e3e-b7b4-e7670d19d526-scratch-2026-10-23-3fc12c/5c5d3883-6efb-4ad0-80f9-99a7a261b932/scratchpad/shots/%s.png" % name)
func _ready() -> void:
	Aura.reset_progress()
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await shot("menu")
	menu.queue_free()
	var one = load("res://levels/level_1.tscn").instantiate()
	add_child(one)
	one.board_tap(one.grid_center(8,7))
	await shot("level1_placed")
	one.rotate_selected(45)
	await get_tree().create_timer(1.0).timeout
	await shot("level1_won")
	one.queue_free()
	var two = load("res://levels/level_2.tscn").instantiate()
	add_child(two)
	two.board_tap(two.grid_center(8,3))
	two.rotate_selected(135)
	two.show_hint(); two.show_hint()
	await shot("level2_hint")
	two.ui.open_pause()
	await shot("pause")
	Aura.open_settings(two.ui.modal)
	await shot("settings")
	Aura.reset_progress()
	get_tree().quit()
