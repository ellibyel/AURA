extends CanvasLayer
# Phone layout (1280x800, letterboxed): header on top, board on the left,
# guide panel on the right, all edit controls in one bottom row of 100 px
# buttons that stays above the iPhone home indicator.
var game: Node2D
var status: Label
var guide: Label
var selected: Label
var character: Node2D
var mutations: Array[Button] = []
var rotate_left: Button
var rotate_right: Button
var remove_button: Button
var undo_button: Button
var hint_button: Button
var success: Control
var modal: Control

func _ready() -> void:
	game=get_parent()
	var header:=Aura.panel(self,Rect2(24,12,1062,88))
	Aura.label(header,"Creative Studio  ·  A place to experiment" if game.level_number==0 else "Chapter %d  ·  %s" % [game.level_number,game.level_data.title],Rect2(8,4,1040,44),32)
	if game.level_number>0:
		Aura.label(header,"Light every star  ·  ★★★ with %d mirror%s and no hints  ·  no timer" % [int(game.level_data.par),"" if int(game.level_data.par)==1 else "s"],Rect2(8,46,1040,34),22,Aura.MUTED)
	else:
		Aura.label(header,"Target tool: tap a target again to remove it  ·  up to 12 targets",Rect2(8,46,1040,34),22,Aura.MUTED)
	Aura.button(self,"Pause",Rect2(1102,12,154,88),open_pause,28)
	var panel:=Aura.panel(self,Rect2(872,112,384,524))
	status=Aura.label(panel,"",Rect2(12,10,360,40),28,Color("7d5f2a"))
	character=load("res://scenes/lightkeeper.tscn").instantiate()
	character.position=Vector2(192,134)
	character.scale=Vector2.ONE*0.66
	panel.add_child(character)
	guide=Aura.paragraph(panel,"",Rect2(12,262,360,180),23)
	var info:=Aura.panel(self,Rect2(24,592,832,46))
	selected=Aura.label(info,"",Rect2(4,4,816,38),23,Aura.MUTED)
	undo_button=Aura.button(self,"Undo",Rect2(24,648,176,100),game.undo_mirror)
	remove_button=Aura.button(self,"Delete",Rect2(210,648,176,100),game.delete_selected)
	var reset:=Aura.button(self,"Reset",Rect2(396,648,176,100),game.reset_level)
	rotate_left=Aura.button(self,"Rotate left",Rect2(612,648,312,100),func():game.rotate_selected(-45),30)
	rotate_right=Aura.button(self,"Rotate right",Rect2(944,648,312,100),func():game.rotate_selected(45),30)
	mutations.assign([rotate_left,rotate_right,undo_button,remove_button,reset])
	if game.level_number>0:
		hint_button=Aura.button(panel,"Need a hint?",Rect2(12,448,360,64),game.show_hint)
		mutations.append(hint_button)
	else:
		guide.size.y=110
		# Studio tools: the selection applies to subsequent taps on the board.
		for i in range(3):
			var names: Array=["Mirror","Target","Source"]
			var keys: Array=["mirror","star","source"]
			mutations.append(Aura.button(panel,names[i],Rect2(12+i*122,376,114,64),func():
				game.tool=keys[i]
				game.message="Tool: "+names[i]+". Tap a grid cell."
				refresh(),24))
		Aura.button(panel,"Save layout",Rect2(12,448,174,64),game.save_layout,24)
		Aura.button(panel,"Load layout",Rect2(198,448,174,64),game.load_layout,24)
	refresh()

func refresh() -> void:
	status.text="TARGETS  %d / %d" % [game.stars_hit,game.target_stars.size()]
	character.happy=game.level_won
	var frozen:bool=game.blocked or (game.level_won and game.level_number>0)
	for button in mutations:button.disabled=frozen
	rotate_left.disabled=frozen or game.selected_mirror<0
	rotate_right.disabled=rotate_left.disabled
	remove_button.disabled=rotate_left.disabled
	undo_button.disabled=frozen or game.history.is_empty()
	selected.text="Tap an empty cell to place a crystal mirror."
	if game.selected_mirror>=0:
		var m:Dictionary=game.mirrors[game.selected_mirror]
		selected.text="Selected mirror: angle %d°   ·   mirrors placed: %d" % [m.rotation,game.mirrors.size()]
	if not game.message.is_empty():guide.text=game.message
	elif game.level_number==0:
		guide.text="All targets are lit! Keep creating, or save this layout." if game.level_won else "Build your own light puzzle. Choose a tool, then tap the grid."
	elif game.level_won:guide.text="You found the way. Every little light matters."
	elif not Aura.tutorial:guide.text="Light every target. Take your time — there are no penalties for experimenting."
	elif game.level_number==1:
		guide.text="1 / PLACE\nTap the cell below the sun to add a mirror." if game.mirrors.is_empty() else "2 / ROTATE\nTap Rotate left or right. Each tap turns the selected mirror 45°."
	else:guide.text="3 / CONNECT\nRoute one beam through both stars. Light passes through stars."

func show_success() -> void:
	if success:return
	success=ColorRect.new()
	success.color=Color(0.17,0.13,0.23,0.40)
	success.size=Vector2(1280,800)
	add_child(success)
	var box:=Aura.panel(success,Rect2(290,170,700,440))
	Aura.label(box,"Chapter complete" if game.level_number==1 else "A journey remembered",Rect2(20,20,660,56),38).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.label(box,"★".repeat(game.rating())+"☆".repeat(3-game.rating()),Rect2(20,82,660,70),52,Color("7d5f2a")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var text: String="Mirrors used: %d  ·  Best reward: %d of 3" % [game.mirrors.size(),int(Aura.best[game.level_number-1])]
	text+="\nChapter 2 is now open." if game.level_number==1 else "\nBoth chapters complete. Your progress is saved."
	if not Aura.save_error.is_empty():text+="\n"+Aura.save_error
	Aura.paragraph(box,text,Rect2(24,166,652,120),24).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.button(box,"Try again",Rect2(24,320,204,90),func():get_tree().reload_current_scene())
	Aura.button(box,"Main menu",Rect2(248,320,204,90),go_menu)
	Aura.button(box,"Next chapter" if game.level_number==1 else "Creative studio",Rect2(472,320,204,90),func():get_tree().change_scene_to_file("res://levels/level_2.tscn" if game.level_number==1 else "res://levels/creative.tscn"),24)
	refresh()

func open_pause() -> void:
	if modal or success:return
	game.blocked=true
	refresh()
	modal=ColorRect.new()
	modal.color=Color(0.15,0.12,0.22,0.55)
	modal.size=Vector2(1280,800)
	add_child(modal)
	var box:=Aura.panel(modal,Rect2(390,120,500,540))
	Aura.label(box,"Paused",Rect2(20,18,460,56),38).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.button(box,"Resume",Rect2(40,96,420,84),resume)
	Aura.button(box,"Restart" if game.level_number==0 else "Restart chapter",Rect2(40,196,420,84),func():get_tree().reload_current_scene())
	Aura.button(box,"Settings",Rect2(40,296,420,84),func():Aura.open_settings(modal))
	Aura.button(box,"Main menu",Rect2(40,396,420,84),go_menu)

func resume() -> void:
	if modal:modal.queue_free()
	modal=null
	game.blocked=false
	refresh()

func _notification(what: int) -> void:
	# Leaving the app (home gesture, call) pauses the puzzle.
	if what==NOTIFICATION_APPLICATION_PAUSED and is_node_ready():open_pause()

func go_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
