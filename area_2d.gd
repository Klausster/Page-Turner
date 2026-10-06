
extends Area2D


@export_file("*.tscn") var next_level: String


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		if next_level != "":
			get_tree().change_scene_to_file.call_deferred(next_level)
		else:
			print("You win!")
