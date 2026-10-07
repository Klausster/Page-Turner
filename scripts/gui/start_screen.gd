extends Control


# Path to the level that loads when Start is pressed.
const GAME_SCENE = "res://scenes/main.tscn"

# Title music player (an AudioStreamPlayer child named "TitleMusic").
@onready var title_music: AudioStreamPlayer = $TitleMusic


func _ready() -> void:
	# Connect the buttons (they need the % unique-name flag in the Scene dock).
	%Start.pressed.connect(_on_play_pressed)
	%Settings.pressed.connect(_on_settings_pressed)
	%Quit.pressed.connect(_on_quit_pressed)

	# When settings close, bring the main buttons back.
	%SettingsMenu.closed.connect(_on_settings_closed)

	# Highlight Start so a controller (or Enter) can use the menu right away.
	%Start.grab_focus()


func _on_play_pressed() -> void:
	%Start.disabled = true  # Prevent double clicks during the fade.
	# Fade the music out over 0.6 seconds, then load the level.
	var tween := create_tween()
	tween.tween_property(title_music, "volume_db", -40.0, 0.6)
	await tween.finished
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_pressed() -> void:
	# Hide the main buttons so focus can't drift to them behind the settings menu.
	$VBoxContainer.hide()
	%SettingsMenu.open()


func _on_settings_closed() -> void:
	$VBoxContainer.show()
	%Settings.grab_focus()  # Return focus to the Settings button.


func _on_quit_pressed() -> void:
	# Close the game.
	get_tree().quit()
