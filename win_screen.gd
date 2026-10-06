extends Control


@export_file("*.tscn") var level_to_retry: String


func _ready() -> void:
	$RetryButton.pressed.connect(_on_retry_pressed)


func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
