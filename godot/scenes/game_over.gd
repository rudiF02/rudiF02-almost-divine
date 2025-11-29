extends Control


func _on_quit_button_pressed():
	# Quits the game
	get_tree().quit()

func _on_restart_button_pressed():
	# Reloads the main game scene
	get_tree().change_scene_to_file("res://scenes/main_menu_scene.tscn")
