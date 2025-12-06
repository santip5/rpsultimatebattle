extends Control

@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	RunState.reset()

	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
