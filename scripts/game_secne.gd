extends Node2D


const GRIDSIZE = 35
@export var time : float


var size : Vector2
var cel_size : Vector2
@export var slot_scene: PackedScene
@export var shape_scene: PackedScene


var slots : Dictionary = {}
var shapes = []
var positions : Dictionary = {}
var showing := true
var new_shape: Shape



@export var color_rect: ColorRect
@onready var timer : Timer = $'Timer'
@onready var anim : AnimationPlayer = $'AnimationPlayer'
@export var time_bar : ProgressBar

func _ready() -> void:
	size = get_viewport_rect().size
	cel_size = Vector2(abs(size.x/7), abs(size.y/5)) 
	print(size, cel_size)

	for i in 3:
		add_new_shape()
	positions = shuffle(shapes, GRIDSIZE)

	fill_grid(GRIDSIZE)
	
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

	positions = shuffle(shapes, GRIDSIZE)

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
		add_new_shape()
		procede()
	
	

func add_new_shape():
	var new_shape: Shape = shape_scene.instantiate()
	new_shape.set_color(Color(randf(), randf(), randf()))
	shapes.append(new_shape)
	new_shape.clicked.connect(_on_clicked)
	self.new_shape = new_shape
	



func is_correct_shape(shape: Shape):
	return shape == new_shape
	

func _on_clicked(shape: Shape):
	if is_correct_shape(shape):
		shape.set_border_color(Color.GREEN)
		timer.stop()
		await get_tree().create_timer(0.5).timeout
		add_new_shape()
		procede()
	else:
		shape.set_border_color(Color.RED)
		timer.stop()
		lose()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_R and not event.echo and event.pressed:
			get_tree().reload_current_scene()

func shuffle(elements: Array, gsize: int): ## shufles, Duh!
	var res := {}
	var avlable_slots = range(0, gsize) 
	for i in elements:
		var slot : int = avlable_slots[randi_range(0, avlable_slots.size()-1)]
		res[slot] = i
		avlable_slots.erase(slot)
	return res


func fill_grid(gsize: int): # makes the slots
	for i in gsize:
		var new_slot : Node2D = slot_scene.instantiate()
		new_slot.position = Vector2(
			(i % 7) * cel_size.x + cel_size.x/2,
			(i / 7) * cel_size.x + cel_size.y/2
			)
		slots[i] = new_slot
		new_slot.set_label(str(i))
		add_child(new_slot)

