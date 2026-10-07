extends CharacterBody2D


# --- Movement settings ---
const SPEED = 300.0                 # Maximum horizontal speed (pixels/sec).
const JUMP_VELOCITY = -500.0        # Upward launch speed (negative = up in Godot).
const COYOTE_TIME = 0.12            # Grace period to still jump after leaving a ledge.
const JUMP_BUFFER_TIME = 0.12       # How long an early jump press is remembered.

# --- Acceleration settings ---
const ACCELERATION = 1500.0         # Ground speed-up rate.
const FRICTION = 1800.0             # Ground slow-down rate when no key is held.
const AIR_ACCELERATION = 1000.0     # Speed-up rate while airborne.
const AIR_FRICTION = 600.0          # Slow-down rate while airborne.
const TURN_BOOST = 2.0              # Extra acceleration when reversing direction.

# --- Ice settings ---
const ICE_ACCELERATION = 300.0      # Slow speed-up on ice (harder to get moving).
const ICE_FRICTION = 80.0           # Very slow slow-down on ice (you slide).
const ICE_TURN_BOOST = 1.0          # No extra turning grip on ice.

# --- Variable jump height ---
const JUMP_CUT = 0.4                # Fraction of upward speed kept when jump is released early.

# --- Charged crouch jump ---
const CROUCH_JUMP_VELOCITY = -760.0 # Launch speed for a fully charged jump.
const CROUCH_SPEED_MULT = 0.25      # Crouching limits horizontal speed to 25%.
const CHARGE_TIME = 3.0             # Seconds of holding crouch needed for the big jump.
const MAX_SHAKE = 2.0               # Camera shake strength (pixels) at full charge.

var spawn_position: Vector2         # Where the player respawns after dying.
var coyote_timer := 0.0             # Counts down after leaving the ground.
var jump_buffer_timer := 0.0        # Counts down after pressing jump.
var charge_timer := 0.0             # How long crouch has been held (0 to CHARGE_TIME).
var on_ice := false                 # True while standing on something in the "ice" group.

# Non-positional jump sound (must be an AudioStreamPlayer node named "Jump").
@onready var jump_sound: AudioStreamPlayer = $Jump

# The camera that shakes while charging (must be a child named "player_camera").
@onready var camera: Camera2D = get_node_or_null("player_camera")


func _ready() -> void:
	# Remember the starting position so die() can send us back here.
	spawn_position = global_position


func _physics_process(delta: float) -> void:
	# Check what we're standing on (uses last frame's collisions).
	_update_ice()

	# Refill the coyote timer on the ground; apply gravity and count down in the air.
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		velocity += get_gravity() * delta
		coyote_timer -= delta

	# We're crouching only while holding crouch on the ground.
	var crouching := Input.is_action_pressed("crouch") and is_on_floor()

	# Letting go of crouch with a full charge launches the big jump.
	# (Checked before the charge is updated below, since releasing resets it.)
	var charged_release := Input.is_action_just_released("crouch") \
		and charge_timer >= CHARGE_TIME and is_on_floor()

	# Charge while crouching; letting go (or leaving the ground) resets the charge.
	if crouching:
		charge_timer = minf(charge_timer + delta, CHARGE_TIME)
	else:
		charge_timer = 0.0

	# Shake the screen more the longer we've charged (squared so it starts subtle).
	if camera:
		var charge_ratio := charge_timer / CHARGE_TIME
		camera.set_shake(MAX_SHAKE * charge_ratio * charge_ratio)

	# Fire the charged jump on release.
	if charged_release:
		velocity.y = CROUCH_JUMP_VELOCITY
		coyote_timer = 0.0           # Prevents a second jump from the same window.
		jump_buffer_timer = 0.0      # Clear any buffered press.
		jump_sound.play()

	# Remember jump presses for a short time (jump buffering).
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# Normal jump if a press is buffered AND we're on the ground or within coyote time.
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0           # Prevents a second jump from the same window.
		jump_buffer_timer = 0.0      # Consume the buffered press.
		charge_timer = 0.0           # Jumping cancels any charge in progress.
		jump_sound.play()

	# Variable jump height: releasing jump while rising cuts the upward speed.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# Read left/right input from arrows, d-pad, or the left stick
	# (-1 = left, 0 = none, 1 = right; sticks give values in between).
	var direction := Input.get_axis("move_left", "move_right")

	# Crouching slows the player down on the ground.
	var max_speed := SPEED * CROUCH_SPEED_MULT if crouching else SPEED

	# Pick ground, ice, or air values depending on where we are.
	var accel := AIR_ACCELERATION
	var friction := AIR_FRICTION
	var turn_boost := TURN_BOOST
	velocity += get_gravity() * delta
	if is_on_floor():
		if on_ice:
			accel = ICE_ACCELERATION
			friction = ICE_FRICTION
			turn_boost = ICE_TURN_BOOST
		else:
			accel = ACCELERATION
			friction = FRICTION

	if direction != 0.0:
		# Turn around faster when pushing against the current movement.
		if signf(direction) != signf(velocity.x) and velocity.x != 0.0:
			accel *= turn_boost
		# Speed up gradually toward the target speed (a half-tilted stick = half speed).
		velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
	else:
		# No input: slow down gradually to a stop.
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# While crouched on normal ground, never exceed the crouch speed.
	# (Skipped on ice so you keep sliding with your momentum.)
	if crouching and not on_ice:
		velocity.x = clampf(velocity.x, -max_speed, max_speed)

	# Apply the velocity and handle collisions.
	move_and_slide()


# Sets on_ice by checking the floor we collided with during the last move.
func _update_ice() -> void:
	on_ice = false
	if not is_on_floor():
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		# Only count surfaces that act as floor (normal pointing up), not walls.
		if collision.get_normal().dot(up_direction) > 0.7:
			var collider := collision.get_collider()
			if collider is Node and collider.is_in_group("ice"):
				on_ice = true
				return

# Called by spikes (kill zones) when the player touches them.
func die() -> void:
	global_position = spawn_position   # Send the player back to the start.
	velocity = Vector2.ZERO            # Stop all movement.
	coyote_timer = 0.0                 # Clear timers so nothing stale carries over.
	jump_buffer_timer = 0.0
	charge_timer = 0.0                 # Cancel any charge in progress.
	if camera:
		camera.set_shake(0.0)          # Stop the shake.
