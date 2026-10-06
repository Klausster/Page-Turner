extends CharacterBody2D
#@onready var audio_stream_player_2d: AudioStreamPlayer2D = $Jump


const SPEED = 300.0
const JUMP_VELOCITY = -450.0

var spawn_position: Vector2


func _ready() -> void:
	spawn_position = global_position


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$Jump.play()

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
func die() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	
	
