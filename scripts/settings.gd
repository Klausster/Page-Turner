extends Control


# Tells whoever opened the menu (start screen or pause menu) that it was closed.
signal closed

# Each bus name paired with its slider.
@onready var sliders: Dictionary = {
	"Master": %MasterSlider,
	"Music": %MusicSlider,
	"SFX": %SFXSlider,
}


func _ready() -> void:
	# Keep working while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	# Update the matching bus whenever a slider moves.
	for bus in sliders:
		sliders[bus].value_changed.connect(_on_slider_changed.bind(bus))

	%BackButton.pressed.connect(close)


# Shows the menu with sliders matching the current volumes.
func open() -> void:
	for bus in sliders:
		sliders[bus].set_value_no_signal(GameSettings.get_volume(bus))
	show()
	# Focus the first slider so a controller can use the menu right away.
	%MasterSlider.grab_focus()


# Saves the settings and hides the menu.
func close() -> void:
	GameSettings.save_settings()
	hide()
	closed.emit()


func _on_slider_changed(value: float, bus: String) -> void:
	GameSettings.set_volume(bus, value)


func _unhandled_input(event: InputEvent) -> void:
	# B on a controller (or Escape) goes back.
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
