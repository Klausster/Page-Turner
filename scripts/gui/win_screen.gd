extends Control


# Set this in the Inspector to the level the Retry button should load.
@export_file("*.tscn") var level_to_retry: String


func _ready() -> void:
	# Connect the Retry button (change the name if yours is different).
	%RetryButton.pressed.connect(_on_retry_pressed)

	# Highlight Retry so a controller (or Enter) can press it right away.
	%RetryButton.grab_focus()


func _on_retry_pressed() -> void:
	# Load the level again.
	get_tree().change_scene_to_file(level_to_retry)
