class_name Shape
extends Node2D

signal clicked(shape: Shape)



func _ready() -> void:
	$"Button".pressed.connect(_on_button_pressed)


func _on_button_pressed():
	clicked.emit(self)

func set_color(c: Color):
	$"Icon".modulate = c

func set_border_color(c: Color):
	$"border".modulate = c

func reset_border_color():
	set_border_color(Color.TRANSPARENT)
