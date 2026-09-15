extends Node2D


signal win
signal lose

@export_group('Gameplay')
@export var time : float
@export var starting_characters := 3 
@export var last_level: int

@export_group('File Referances')
@export var slot_scene		: PackedScene
@export var character_scene	: PackedScene
@export var character_data	: CharacterData
@export var landsacpe_theme	: Theme
@export var portrait_theme	: Theme


@export_group('Node Referances')
@export var color_rect	: ColorRect
@export var play_ground	: ColorRect
@export var timer 		: Timer
@export var anim 		: AnimationPlayer
@export var time_bar 	: ProgressBar
@export var win_panel	: Panel
@export var lose_panel	: Panel
@export var win_label	: Label
@export var lose_label	: Label
@export var lose_name_label		: Label
@export var replay_button		: Button
@export var lose_replay_button	: Button
@export var lose_char_sprite	: Sprite2D


@export_group('Grid')
@export var max_gid_cels: int
@export var min_ratio	: Vector2i
@export var max_ratio	: Vector2i
@export var valid_grids	: Array[Vector2i]


var level := 1
var start_time : int ## it should hold the game tick of when we start playing
var size 			: Vector2
var current_grid	: Vector2i
var cel_size 		: Vector2
var icon_size		: Vector2
var slots 			: Dictionary[int, Node2D] = {}
var avalable_characters := []
var picked_characters : Array[Character] = []
var positions : Dictionary = {}
var showing := true
var new_character: Character



func _ready() -> void:
	# safe gards:
	if last_level > (max_gid_cels - starting_characters):
		printerr("your last level is out of bounds")
		get_tree().quit()
	if last_level < 1:
		printerr("your last level is less then 1 you stupid fuck")
		get_tree().quit()
	var grid_sizes : Array[int] = []
	for i in valid_grids:
		grid_sizes.append(i.x * i.y)
	var min_cels = grid_sizes.min()
	if min_cels < max_gid_cels:
		printerr("you have more cels then you can show")
		get_tree().quit()


	# the actual function:
	win.connect(_on_win)
	lose.connect(_on_lose)


	# grid initialazation
	play_ground.resized.connect(size_the_grid)
	fill_grid(max_gid_cels)
	size_the_grid()

	avalable_characters = character_data.characters.keys()

	
	for i in starting_characters:
		add_new_character()
	positions = shuffle(picked_characters, max_gid_cels)

	for i in positions:
		slots[i].add_child(positions[i])

	timer.timeout.connect(_on_timeout)
	timer.start(time)
	start_time = Time.get_ticks_msec()



	

func _process(_delta: float) -> void:
	time_bar.value = time_bar.max_value * timer.time_left / time 


func procede():
	## the process of going to next level happens here
	if level >= last_level: 
		win.emit()
		return

	level += 1

	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	anim.play('blink_out')
	await anim.animation_finished
	

	timer.start(time)
	for i in positions:
		positions[i].get_parent().remove_child(positions[i])

	positions = shuffle(picked_characters, max_gid_cels)

	for i in positions:
		slots[i].add_child(positions[i])
		positions[i].reset_border_color()
	
	anim.play('blink_in')
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE



func _on_timeout(): 
	if !showing: 
		lose.emit()
	else:
		showing = false
		new_character = add_new_character()
		procede()
	
	

func add_new_character() -> Character: 
	## choses a random character, instantiates it
	## adds to the picked characters, deletes it form the avalable ones
	## and returns the new cahracter node instance
	var new_character_index = randi_range(0, avalable_characters.size()-1)
	var new_character_num = avalable_characters.pop_at(new_character_index)
	var new_character: Character = character_scene.instantiate()

	new_character.set_character(
		character_data.texture,
		character_data.slices.x,
		character_data.slices.y,
		new_character_num,
		character_data.characters[new_character_num],
		icon_size,
		)

	picked_characters.append(new_character)
	new_character.clicked.connect(_on_clicked)
	return new_character
	


func closest_aspect(window: Vector2, ratios: Array) -> Vector2:
	## what an ugly ass function
	var target := window.x / window.y
	var closest : Vector2i = ratios[0]
	var closest_diff : float = abs(target - float(closest.x)/float(closest.y))

	for r in ratios:
		var ratio : float= float(r.x) / float(r.y)
		var diff : float = abs(target - ratio)

		if diff < closest_diff:
			closest_diff = diff
			closest = r
	return closest

func is_correct_shape(character: Character): # self explanatory
	return character == new_character
	

func _on_clicked(character: Character): # handdls any button press
	if is_correct_shape(character):
		character.set_border_color(Color.GREEN)
		timer.stop()
	#	await get_tree().create_timer(0.5).timeout
		new_character = add_new_character()
		procede()
	else:
		character.set_border_color(Color.RED)
		timer.stop()
		lose.emit()



func format_time(s: int) -> String: ## s is in msec 
	var minutes := s / 60
	var seconds := s % 60

	return "%02d:%02d" % [minutes, seconds]

func _on_win():
	var play_time := (Time.get_ticks_msec() - start_time) / 1000.0
	win_label.text = "you finished the game! im proud of you.\n\n" +\
			'your score: ' + str(level) + '\n' +\
			'your time: ' + format_time(int(play_time)) + '\n'

	replay_button.pressed.connect(func (): get_tree().reload_current_scene())
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	anim.play("show_win_panel")


func _on_lose():
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	new_character.set_border_color(Color.GREEN)

	lose_replay_button.pressed.connect(func (): 
		get_tree().reload_current_scene())
	var play_time := (Time.get_ticks_msec() - start_time) / 1000.0
	lose_label.text = '\nyour score: ' + str(level) + '\n' +\
			'your time: '  + format_time(int(play_time))
	lose_name_label.text = new_character.char_name
	lose_char_sprite.hframes = character_data.slices.x
	lose_char_sprite.vframes = character_data.slices.y
	lose_char_sprite.frame = new_character.frame
	anim.play("show_lose_panel")


	
func size_the_grid():
	size = play_ground.size
	current_grid = closest_aspect(size, valid_grids)
	if size.x > size.y:
		win_panel.theme = landsacpe_theme
		lose_panel.theme = landsacpe_theme
	else:
		win_panel.theme = portrait_theme
		lose_panel.theme = portrait_theme


	cel_size = Vector2(abs(size.x/current_grid.x), abs(size.y/current_grid.y)) 

	icon_size = Vector2.ONE * max(cel_size.y, cel_size.x) / 64

	for i in max_gid_cels:
		slots[i].position = Vector2(
			(i % current_grid.x) * cel_size.x,
			(i / current_grid.x) * cel_size.y
		)
	for i in picked_characters:
		i.set_size(icon_size)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_R and not event.echo and event.pressed:
			get_tree().reload_current_scene()



func shuffle(elements: Array, lsize: int) -> Dictionary: 
	## as shuffle Dictionary of slot to thair elemets
	## with any number of empty slots
	var res := {}
	var avlable_slots = range(0, lsize) 
	for i in elements:
		var slot : int = avlable_slots[randi_range(0, avlable_slots.size()-1)]
		res[slot] = i
		avlable_slots.erase(slot)
	return res


func fill_grid(gsize: int): ## isntantiates the slots
	for i in gsize:
		var new_slot : Node2D = slot_scene.instantiate()
		slots[i] = new_slot
		add_child(new_slot)
