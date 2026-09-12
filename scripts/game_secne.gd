extends Node2D


const GRIDSIZE = 35
@export var time : float


var size : Vector2
var cel_size : Vector2
@export var slot_scene: PackedScene
@export var character_scene: PackedScene
@export var character_data: CharacterData


var slots : Dictionary[int, Node2D] = {}
var avalable_characters := []
var picked_characters := []
var positions : Dictionary = {}
var showing := true
var new_character: Character



@export var color_rect: ColorRect
@onready var timer : Timer = $'Timer'
@onready var anim : AnimationPlayer = $'AnimationPlayer'
@export var time_bar : ProgressBar

func _ready() -> void:
	size = get_viewport_rect().size
	cel_size = Vector2(abs(size.x/7), abs(size.y/5)) 
	avalable_characters = character_data.characters.keys()

	fill_grid(GRIDSIZE)
	
	for i in 3:
		add_new_character()
	positions = shuffle(picked_characters, GRIDSIZE)

	for i in positions:
		slots[i].add_child(positions[i])

	timer.timeout.connect(_on_timeout)
	timer.start(time)

	

	

func _process(_delta: float) -> void:
	time_bar.value = time_bar.max_value * timer.time_left / time 


func procede():
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	anim.play('blink_out')
	await anim.animation_finished
	

	timer.start(time)
	for i in positions:
		positions[i].get_parent().remove_child(positions[i])

	positions = shuffle(picked_characters, GRIDSIZE)

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

