extends Control

func _on_start_pressed() -> void:
	RunState.reset()
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_instructions_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Instructions.tscn")
