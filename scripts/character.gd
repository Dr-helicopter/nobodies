class_name Character
extends Node2D

signal clicked(shape: Character)



func _ready() -> void:
	$"Button".pressed.connect(_on_button_pressed)


func _on_button_pressed():
	clicked.emit(self)

func set_character(t: Texture, hframe: int, vframe: int, frame: int):
	$"Icon".texture = t
	$"Icon".hframes = hframe
	$"Icon".vframes = vframe
	$"Icon".frame = frame

func set_border_color(c: Color):
	$"border".modulate = c

func reset_border_color():
	set_border_color(Color.TRANSPARENT)
