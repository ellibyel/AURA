extends CanvasLayer
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
	Aura.label(self,"AURA  /  CREATIVE STUDIO" if game.level_number==0 else "AURA  /  CHAPTER %02d" % game.level_number,Rect2(40,26,800,30),18,Aura.PURPLE)
	Aura.label(self,"A place to experiment" if game.level_number==0 else game.level_data.title,Rect2(40,62,950,60),42)
	if game.level_number>0: Aura.label(self,game.level_data.subtitle,Rect2(40,128,900,30),20)
	Aura.button(self,"Menu",Rect2(1060,34,170,54),go_menu)
	Aura.button(self,"Settings",Rect2(1060,102,170,54),open_pause)
	var panel:=Aura.panel(self,Rect2(848,192,382,548))
	status=Aura.label(panel,"",Rect2(24,16,340,40),25,Aura.GOLD)
	character=load("res://scripts/portrait.gd").new()
	character.position=Vector2(180,180)
	panel.add_child(character)
	guide=Aura.paragraph(panel,"",Rect2(24,335,334,157),20)
	selected=Aura.label(self,"",Rect2(40,633,790,28),18,Aura.PURPLE)
	rotate_left=Aura.button(self,"Rotate left",Rect2(40,676,177,60),func():game.rotate_selected(-45))
	rotate_right=Aura.button(self,"Rotate right",Rect2(229,676,177,60),func():game.rotate_selected(45))
	undo_button=Aura.button(self,"Undo",Rect2(418,676,112,60),game.undo_mirror)
	remove_button=Aura.button(self,"Delete",Rect2(542,676,120,60),game.delete_selected)
	var reset:=Aura.button(self,"Reset",Rect2(674,676,134,60),game.reset_level)
	mutations.assign([rotate_left,rotate_right,undo_button,remove_button,reset])
	if game.level_number>0:
		hint_button=Aura.button(panel,"Need a hint?",Rect2(24,485,334,48),game.show_hint)
		mutations.append(hint_button)
		Aura.label(self,"3 reward stars: finish with %d mirror%s and no hints. Experiment freely; no timer." % [int(game.level_data.par),"" if int(game.level_data.par)==1 else "s"],Rect2(40,752,1170,28),16)
	else:
		# Studio tools sit above the board; selection applies to subsequent taps.
		for i in range(3):
			var names: Array=["Mirror","Target","Source"]
			var keys: Array=["mirror","star","source"]
			mutations.append(Aura.button(self,names[i],Rect2(40+i*155,121,143,48),func():
				game.tool=keys[i]
				game.message="Tool: "+names[i]+". Tap a grid cell."
				refresh()))
		Aura.button(panel,"Save layout",Rect2(24,485,160,48),game.save_layout)
		Aura.button(panel,"Load layout",Rect2(194,485,164,48),game.load_layout)
		Aura.label(self,"Target tool: tap again to remove. Source tool: choose an empty cell. Up to 12 targets.",Rect2(40,752,1170,28),16)
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
		selected.text="Selected: column %d, row %d  /  angle %d°  /  mirrors %d" % [m.grid_x+1,m.grid_y+1,m.rotation,game.mirrors.size()]
	if not game.message.is_empty():guide.text=game.message
	elif game.level_number==0:
		guide.text="All targets are lit! Keep creating, or save this layout." if game.level_won else "Build your own light puzzle. Choose Mirror, Target or Source, then tap the grid."
	elif game.level_won:guide.text="You found the way. Every little light matters."
	elif not Aura.tutorial:guide.text="Light every target. Take your time — there are no penalties for experimenting."
	elif game.level_number==1:
		guide.text="1 / PLACE\nTap a cell below the sun to add a mirror." if game.mirrors.is_empty() else "2 / ROTATE\nUse Rotate left or right. Each tap turns the selected mirror 45°. Aim at the star."
	else:guide.text="3 / CONNECT\nRoute one beam through both stars. Stars let the light pass through. Undo reverses your last edit."

func show_success() -> void:
	if success:return
	success=ColorRect.new()
	success.color=Color(0.17,0.13,0.23,0.40)
	success.size=Vector2(1280,800)
	add_child(success)
	var box:=Aura.panel(success,Rect2(325,205,630,386))
	Aura.label(box,"Chapter complete" if game.level_number==1 else "A journey remembered",Rect2(30,24,570,56),34).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.label(box,"★".repeat(game.rating())+"☆".repeat(3-game.rating()),Rect2(30,87,570,68),46,Aura.GOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var text: String="Mirrors used: %d  /  Best reward: %d of 3" % [game.mirrors.size(),int(Aura.best[game.level_number-1])]
	text+="\nChapter 2 is now open." if game.level_number==1 else "\nBoth chapters complete. Your progress is saved."
	if not Aura.save_error.is_empty():text+="\n"+Aura.save_error
	Aura.paragraph(box,text,Rect2(36,169,558,86),20).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Aura.button(box,"Try again",Rect2(30,290,170,60),func():get_tree().reload_current_scene())
	Aura.button(box,"Main menu",Rect2(212,290,180,60),go_menu)
	Aura.button(box,"Next chapter" if game.level_number==1 else "Creative studio",Rect2(404,290,196,60),func():get_tree().change_scene_to_file("res://levels/level_2.tscn" if game.level_number==1 else "res://levels/creative.tscn"))
	refresh()

func open_pause() -> void:
	if modal or success:return
	game.blocked=true
	refresh()
	modal=Aura.open_settings(self,func():
		modal=null
		game.blocked=false
		refresh())

func go_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
