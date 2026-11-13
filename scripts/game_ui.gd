extends CanvasLayer
# Immersive phone HUD (Assignment 4): the board fills the screen and the
# controls are round icon buttons on this layer, pinned to the screen edges
# inside the safe area. Text is limited to small chips and short toasts.
const ICONS := "res://assets/ui/icons/%s.svg"
const AD_SECONDS := 5
var game: Node2D
var chips: Array[Label] = []
var toast: Label
var toast_tween: Tween
var last_message := ""
var mutations: Array[Button] = []
var rotate_left: Button
var rotate_right: Button
var remove_button: Button
var undo_button: Button
var hint_button: Button
var hint_badge: Label
var success: Control
var modal: Control

func _ready() -> void:
	game=get_parent()
	offset.x=Aura.margin_x
	Aura.layout_changed.connect(func():offset.x=Aura.margin_x)
	var edge:=_safe_edges()
	var left:=edge.x
	var right:=edge.y
	var top:=_safe_top()
	# Top strip: pause in the top-left corner (players looked for it there),
	# then compact chips; hint on the right. All inside the safe area.
	_icon_button("pause",Rect2(left,top,80,80),open_pause)
	var cx:=left+96
	if game.level_number>0:
		chips.append(_chip(Vector2(cx,top),"Ch %d · %s" % [game.level_number,game.level_data.title]))
		chips.append(_chip(Vector2(cx+430,top),""))
		chips.append(_chip(Vector2(cx+600,top),""))
	else:
		chips.append(_chip(Vector2(cx,top),"Creative Studio"))
		var names:Array=["Mirror","Target","Source"]
		var keys:Array=["mirror","star","source"]
		for i in range(3):
			mutations.append(Aura.button(self,names[i],Rect2(cx+260+i*132,top-2,120,58),func():
				game.tool=keys[i]
				game.message="Tool: "+names[i]+". Tap a grid cell."
				refresh(),24))
		Aura.button(self,"Save",Rect2(cx+660,top-2,110,58),game.save_layout,24)
		Aura.button(self,"Load",Rect2(cx+782,top-2,110,58),game.load_layout,24)
	if game.level_number>0:
		hint_button=_icon_button("hint",Rect2(right-80,top,80,80),game.show_hint)
		hint_badge=Aura.label(hint_button,"",Rect2(48,-6,40,34),22,Color.WHITE)
		hint_badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var badge:=StyleBoxFlat.new()
		badge.bg_color=Aura.GOLD
		badge.set_corner_radius_all(16)
		hint_badge.add_theme_stylebox_override("normal",badge)
		mutations.append(hint_button)
	# Edit tools on the left, rotation under the right thumb.
	undo_button=_icon_button("undo",Rect2(left,662,88,88),game.undo_mirror)
	remove_button=_icon_button("delete",Rect2(left,564,88,88),game.delete_selected)
	var reset:=_icon_button("reset",Rect2(left,466,88,88),game.reset_level)
	rotate_right=_icon_button("rotate_cw",Rect2(right-104,646,104,104),func():game.rotate_selected(45))
	rotate_left=_icon_button("rotate_ccw",Rect2(right-104,530,104,104),func():game.rotate_selected(-45))
	mutations.append_array([rotate_left,rotate_right,undo_button,remove_button,reset])
	toast=Aura.label(self,"",Rect2(240,690,800,52),24,Color.WHITE)
	toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var toast_bg:=StyleBoxFlat.new()
	toast_bg.bg_color=Color(0.23,0.18,0.39,0.86)
	toast_bg.set_corner_radius_all(24)
	toast_bg.content_margin_left=20
	toast_bg.content_margin_right=20
	toast.add_theme_stylebox_override("normal",toast_bg)
	toast.modulate.a=0.0
	refresh()
	if game.level_number==1 and Aura.tutorial: show_toast("Tap the cell under the sun to place a mirror.")

# Left and right x positions of the visible screen (design coordinates),
# moved in by the iPhone safe area so nothing sits under the Dynamic Island.
# Top inset (status bar, notch or camera cut-out) in design pixels, 6..14.
func _safe_top() -> float:
	var view:=get_viewport().get_visible_rect().size
	var window:=Vector2(DisplayServer.window_get_size())
	var safe:=Rect2(DisplayServer.get_display_safe_area())
	if window.y<=0 or safe.size.y<=0: return 6.0
	var inset:=maxf(0.0,safe.position.y-DisplayServer.window_get_position().y)*view.y/window.y
	# Phones in landscape have no top cut-out (the Dynamic Island is on a side),
	# so the inset stays small; the clamp keeps the chips above the board.
	return clampf(inset+6.0,6.0,14.0)

func _safe_edges() -> Vector2:
	var view:=get_viewport().get_visible_rect().size
	var window:=Vector2(DisplayServer.window_get_size())
	var safe:=Rect2(DisplayServer.get_display_safe_area())
	var inset_l:=0.0
	var inset_r:=0.0
	if window.x>0 and safe.size.x>0:
		var k:=view.x/window.x
		inset_l=maxf(0.0,safe.position.x)*k
		inset_r=maxf(0.0,window.x-safe.end.x)*k
	return Vector2(-Aura.margin_x+inset_l+12,Aura.DESIGN.x+Aura.margin_x-inset_r-12)

func _chip(pos: Vector2, text: String) -> Label:
	var chip:=Aura.label(self,text,Rect2(pos,Vector2(0,56)),24,Aura.INK)
	chip.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var box:=StyleBoxFlat.new()
	box.bg_color=Color(1,1,1,0.72)
	box.border_color=Color(1,1,1,0.95)
	box.set_border_width_all(2)
	box.set_corner_radius_all(28)
	box.content_margin_left=18
	box.content_margin_right=18
	chip.add_theme_stylebox_override("normal",box)
	return chip

func _icon_button(icon: String, rect: Rect2, action: Callable) -> Button:
	var item:=Aura.button(self,"",rect,action)
	item.icon=load(ICONS % icon)
	item.expand_icon=true
	item.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
	item.add_theme_constant_override("icon_max_width",int(rect.size.x*0.5))
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		var box:=StyleBoxFlat.new()
		box.bg_color=Color(1,1,1,0.62 if state!="pressed" else 0.9)
		if state=="disabled": box.bg_color=Color(1,1,1,0.3)
		box.border_color=Color(1,1,1,0.95)
		box.set_border_width_all(2)
		box.set_corner_radius_all(int(rect.size.x/2))
		box.shadow_color=Color(0.24,0.16,0.35,0.18)
		box.shadow_size=8
		item.add_theme_stylebox_override(state,box)
	item.add_theme_color_override("icon_disabled_color",Color(1,1,1,0.4))
	return item

func refresh() -> void:
	if game.level_number>0:
		chips[1].text="★ %d / %d" % [game.stars_hit,game.target_stars.size()]
		chips[2].text="Mirrors %d / %d" % [game.mirrors.size(),game.max_mirrors]
		hint_badge.text=str(game.hints_left) if game.hints_left>0 else "AD"
	var frozen:bool=game.blocked or (game.level_won and game.level_number>0)
	for button in mutations:button.disabled=frozen
	rotate_left.disabled=frozen or game.selected_mirror<0
	rotate_right.disabled=rotate_left.disabled
	remove_button.disabled=rotate_left.disabled
	undo_button.disabled=frozen or game.history.is_empty()
	if not game.message.is_empty() and game.message!=last_message:
		show_toast(game.message)
	elif game.level_number==1 and Aura.tutorial and game.mirrors.size()==1 and not game.level_won and last_message.begins_with("Tap the cell"):
		show_toast("Turn the mirror with the round arrows until the beam hits the star.")
	last_message=game.message if not game.message.is_empty() else last_message

func show_toast(text: String) -> void:
	last_message=text
	toast.text=text
	toast.size=Vector2(800,52)
	if toast_tween: toast_tween.kill()
	toast_tween=create_tween()
	toast.modulate.a=1.0
	toast_tween.tween_interval(3.5)
	toast_tween.tween_property(toast,"modulate:a",0.0,0.6)

func _overlay() -> ColorRect:
	var shade:=ColorRect.new()
	shade.color=Color(0.15,0.12,0.22,0.55)
	shade.position=Vector2(-640,0)
	shade.size=Vector2(2560,800)
	add_child(shade)
	return shade

func show_success() -> void:
	if success:return
	success=_overlay()
	var box:=Aura.panel(success,Rect2(930,150,700,480))
	var last:bool=game.level_number>=Aura.LEVEL_COUNT
	Aura.label(box,"All chapters complete" if last else "Chapter %d complete" % game.level_number,Rect2(20,20,660,56),38).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.label(box,"★".repeat(game.rating())+"☆".repeat(3-game.rating()),Rect2(20,82,660,70),56,Color("7d5f2a")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	# The chapter keeps its best result, so a weaker run never lowers it; say so.
	var best:int=int(Aura.best[game.level_number-1])
	var text: String="Mirrors used: %d (best possible: %d)" % [game.mirrors.size(),int(game.level_data.par)]
	text+="\nThis run: %d ★ · Chapter best: %d ★" % [game.rating(),best] if best>game.rating() else "\nNew chapter best: %d ★" % best
	if game.hints_used>0: text+="\nHints used: %d" % game.hints_used
	text+="\nTotal stars: %d / %d" % [Aura.total_stars(),Aura.LEVEL_COUNT*3]
	if not Aura.save_error.is_empty():text+="\n"+Aura.save_error
	Aura.paragraph(box,text,Rect2(24,166,652,130),24).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.button(box,"Try again",Rect2(24,360,204,90),func():get_tree().reload_current_scene())
	Aura.button(box,"Chapters",Rect2(248,360,204,90),go_chapters)
	if last: Aura.button(box,"Creative",Rect2(472,360,204,90),func():Aura.start_level(0))
	else: Aura.button(box,"Next",Rect2(472,360,204,90),func():Aura.start_level(game.level_number+1))
	refresh()

func open_pause() -> void:
	if modal or success:return
	game.blocked=true
	refresh()
	modal=_overlay()
	var box:=Aura.panel(modal,Rect2(1030,90,500,610))
	Aura.label(box,"Paused",Rect2(20,18,460,56),38).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.button(box,"Resume",Rect2(40,90,420,84),resume)
	Aura.button(box,"Restart" if game.level_number==0 else "Restart chapter",Rect2(40,188,420,84),func():get_tree().reload_current_scene())
	Aura.button(box,"Chapters",Rect2(40,286,420,84),go_chapters)
	Aura.button(box,"Settings",Rect2(40,384,420,84),func():Aura.open_settings(self))
	Aura.button(box,"Main menu",Rect2(40,482,420,84),go_menu)

func resume() -> void:
	if modal:modal.queue_free()
	modal=null
	game.blocked=false
	refresh()

# Monetisation prototype: a rewarded "ad" for an extra hint. It is a local demo
# screen (no ad network, no tracking), clearly labelled as a demo.
func offer_ad() -> void:
	if modal or success:return
	game.blocked=true
	refresh()
	modal=_overlay()
	var box:=Aura.panel(modal,Rect2(980,170,600,420))
	Aura.label(box,"Out of hints",Rect2(20,20,560,52),36).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.paragraph(box,"Watch a short ad to get one more hint.\nHints still cost one reward star.",Rect2(30,90,540,110),24).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.button(box,"Watch ad (5 s)",Rect2(30,230,540,80),_play_ad)
	Aura.button(box,"No, thanks",Rect2(30,322,540,72),resume)

func _play_ad() -> void:
	modal.queue_free()
	modal=_overlay()
	modal.color=Color(0.08,0.06,0.13,0.94)
	var box:=Aura.panel(modal,Rect2(930,110,700,560))
	Aura.label(box,"ADVERTISEMENT · DEMO",Rect2(20,16,660,34),22,Aura.MUTED).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.label(box,"AURA",Rect2(20,80,660,110),96).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.paragraph(box,"Enjoying the quiet light?\nShare AURA with a friend who loves puzzles.",Rect2(40,210,620,110),26).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var count:=Aura.label(box,"",Rect2(20,340,660,44),26,Aura.MUTED)
	count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var close:=Aura.button(box,"Close and get hint",Rect2(40,400,620,90),func():
		resume()
		game.grant_hint())
	close.disabled=true
	for left in range(AD_SECONDS,0,-1):
		count.text="Reward in %d s" % left
		await get_tree().create_timer(1.0).timeout
		if not is_instance_valid(count): return
	count.text="Reward ready"
	close.disabled=false

func _notification(what: int) -> void:
	# Leaving the app (home gesture, call) pauses the puzzle.
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT] and is_node_ready():open_pause()

func go_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func go_chapters() -> void:
	Aura.menu_page="chapters"
	go_menu()
