extends Control


const GAME_SCENE = "res://scenes/main.tscn"

@onready var TitleMusic: AudioStreamPlayer = $TitleMusic


func _ready() -> void:
	%Start.pressed.connect(_on_play_pressed)
	%Quit.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	%Start.disabled = true # Prevent double clicks during the fade.
	var tween := create_tween()
	tween.tween_property(TitleMusic, "volume_db", -40.0, 0.6)
	await tween.finished
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
