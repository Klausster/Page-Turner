extends Camera2D


const ZOOM_STEP = 0.1
const ZOOM_MIN = 0.5
const ZOOM_MAX = 3.0
const ZOOM_SPEED = 8.0

var target_zoom := 1.0

@onready var zoom_in_sound: AudioStreamPlayer = $ZoomInSound
@onready var zoom_out_sound: AudioStreamPlayer = $ZoomOutSound


func _ready() -> void:
	target_zoom = zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_change_zoom(ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_zoom(-ZOOM_STEP)


func _change_zoom(amount: float) -> void:
	var new_zoom := clampf(target_zoom + amount, ZOOM_MIN, ZOOM_MAX)
	if is_equal_approx(new_zoom, target_zoom):
		return # Already at the limit, so no sound.
	target_zoom = new_zoom

	# Don't start a new sound until the current one has finished.
	if zoom_in_sound.playing or zoom_out_sound.playing:
		return

	if amount > 0:
		zoom_in_sound.play()
	else:
		zoom_out_sound.play()


func _process(delta: float) -> void:
	var z := lerpf(zoom.x, target_zoom, ZOOM_SPEED * delta)
	zoom = Vector2(z, z)
	
