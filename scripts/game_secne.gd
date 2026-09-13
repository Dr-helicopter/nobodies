extends Node2D


signal win

@export_group('Gameplay')
@export var time : float
@export var starting_characters := 3 
@export var last_level: int

@export_group('File Referances')
@export var slot_scene		: PackedScene
@export var character_scene	: PackedScene
@export var character_data	: CharacterData


@export_group('Node Referances')
@export var color_rect	: ColorRect
@export var timer 		: Timer
@export var anim 		: AnimationPlayer
@export var time_bar 	: ProgressBar
@export var win_panel	: Panel
@export var win_label	: Label
@export var replay_button:Button


@export_group('Grid')
@export var max_gid_cels: int
@export var min_ratio	: Vector2i
@export var max_ratio	: Vector2i
@export var valid_grids	: Array[Vector2i]

var level := 1
var size : Vector2
var cel_size : Vector2
var slots : Dictionary[int, Node2D] = {}
var avalable_characters := []
var picked_characters := []
var positions : Dictionary = {}
var showing := true
var new_character: Character



func _ready() -> void:
	# safe gards
	if last_level > max_gid_cels - starting_characters:
		printerr("your last level is out of bounds")
		get_tree().quit()
	if last_level < 1:
		printerr("your last level is less then 1 you stupid fuck")
		get_tree().quit()

	win.connect(_on_win)


	size = get_viewport_rect().size
	cel_size = Vector2(abs(size.x/7), abs(size.y/5)) 
	avalable_characters = character_data.characters.keys()

	fill_grid(max_gid_cels)
	
	for i in starting_characters:
		add_new_character()
	positions = shuffle(picked_characters, max_gid_cels)

	for i in positions:
		slots[i].add_child(positions[i])

	timer.timeout.connect(_on_timeout)
	timer.start(time)



	

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


func lose():
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_timeout(): 
	if !showing: 
		lose()
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
		new_character_num
		)

	picked_characters.append(new_character)
	new_character.clicked.connect(_on_clicked)
	return new_character
	



func is_correct_shape(character: Character): # self explanatory
	return character == new_character
	

func _on_clicked(shape: Character): # handdls any button press
	if is_correct_shape(shape):
		shape.set_border_color(Color.GREEN)
		timer.stop()
	#	await get_tree().create_timer(0.5).timeout
		new_character = add_new_character()
		procede()
	else:
		shape.set_border_color(Color.RED)
		timer.stop()
		lose()

func _on_win():
	win_label.text = "you finished the game! im proud of you.\n\n" +\
			'your score: 30\n' +\
			'your time: 69'
	replay_button.pressed.connect(func (): get_tree().reload_current_scene())
	win_panel.show()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	

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
		new_slot.position = Vector2(
			(i % 7) * cel_size.x,
			(i / 7) * cel_size.y
			)
		slots[i] = new_slot
		new_slot.set_label(str(i))
		add_child(new_slot)
