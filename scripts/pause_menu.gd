extends CanvasLayer


# Path to the start screen (used by the Main Menu button).
const START_SCREEN = "res://scenes/start_screen.tscn"


func _ready() -> void:
	# Keep working while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	# Connect the buttons.
	%ResumeButton.pressed.connect(resume)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%MainMenuButton.pressed.connect(_on_main_menu_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)

	# When settings close, bring the pause buttons back.
	%SettingsMenu.closed.connect(_on_settings_closed)


func _unhandled_input(event: InputEvent) -> void:
	# Escape / Start toggles the pause menu. B (ui_cancel) also resumes while it's open.
	if event.is_action_pressed("pause") or (visible and event.is_action_pressed("ui_cancel")):
		# Let the settings menu handle its own back button.
		if %SettingsMenu.visible:
			return
		if visible:
			resume()
		else:
			pause()
		get_viewport().set_input_as_handled()


func pause() -> void:
	show()
	%Buttons.show()
	%SettingsMenu.hide()
	get_tree().paused = true      # Freezes everything that isn't set to "Always".
	%ResumeButton.grab_focus()    # Controller focus starts on Resume.


func resume() -> void:
	%SettingsMenu.hide()
	hide()
	get_tree().paused = false


func _on_settings_pressed() -> void:
	# Hide the pause buttons so focus can't drift to them behind the settings menu.
	%Buttons.hide()
	%SettingsMenu.open()


func _on_settings_closed() -> void:
	%Buttons.show()
	%SettingsButton.grab_focus()  # Return focus to where the player was.


func _on_main_menu_pressed() -> void:
	get_tree().paused = false     # Always unpause before leaving, or the next scene stays frozen.
	get_tree().change_scene_to_file("res://scenes/gui/start_screen.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
