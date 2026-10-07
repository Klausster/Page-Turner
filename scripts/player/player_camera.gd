extends Camera2D


# --- Zoom settings ---
const ZOOM_STEP = 0.1     # How much each zoom input changes the zoom.
const ZOOM_MIN = 0.5      # Furthest you can zoom out.
const ZOOM_MAX = 3.0      # Closest you can zoom in.
const ZOOM_SPEED = 8.0    # How quickly the camera glides to the target zoom.

var target_zoom := 1.0    # The zoom level we're gliding toward.
var shake_strength := 0.0 # Current shake size in pixels (set by the player).

# Non-positional zoom sounds (named to match your Scene dock).
@onready var zoom_in_sound: AudioStreamPlayer = $ZoomIn
@onready var zoom_out_sound: AudioStreamPlayer = $ZoomOut


func _ready() -> void:
	# Start the target at the camera's current zoom.
	target_zoom = zoom.x


func _unhandled_input(event: InputEvent) -> void:
	# "zoom_in" / "zoom_out" cover the mouse wheel and the controller bumpers.
	if event.is_action_pressed("zoom_in"):
		_change_zoom(ZOOM_STEP)
	elif event.is_action_pressed("zoom_out"):
		_change_zoom(-ZOOM_STEP)


# Called by the player to set how hard the screen shakes (0 = no shake).
func set_shake(strength: float) -> void:
	shake_strength = strength


func _change_zoom(amount: float) -> void:
	# Keep the new zoom within the allowed range.
	var new_zoom := clampf(target_zoom + amount, ZOOM_MIN, ZOOM_MAX)
	if is_equal_approx(new_zoom, target_zoom):
		return # Already at a limit, so no change and no sound.
	target_zoom = new_zoom

	# Don't start a new sound until the current one has finished.
	if zoom_in_sound.playing or zoom_out_sound.playing:
		return

	if amount > 0:
		zoom_in_sound.play()
	else:
		zoom_out_sound.play()


func _process(delta: float) -> void:
	# Smoothly move the actual zoom toward the target zoom.
	var z := lerpf(zoom.x, target_zoom, ZOOM_SPEED * delta)
	zoom = Vector2(z, z)

	# Shake by nudging the camera's offset a random amount each frame.
	if shake_strength > 0.01:
		offset = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_strength
	else:
		offset = Vector2.ZERO  # No shake, so recenter the camera.
