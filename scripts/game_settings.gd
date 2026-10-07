extends Node


const SAVE_PATH = "user://settings.cfg"            # Where settings are stored on disk.
const BUS_NAMES = ["Master", "Music", "SFX"]       # Must match your bus names exactly.

# Volume per bus as a 0.0 to 1.0 slider value.
var volumes := {"Master": 1.0, "Music": 1.0, "SFX": 1.0}


func _ready() -> void:
	# Load saved settings and apply them as soon as the game starts.
	load_settings()
	for bus in BUS_NAMES:
		_apply(bus)


# Called by the sliders whenever a value changes.
func set_volume(bus_name: String, value: float) -> void:
	volumes[bus_name] = value
	_apply(bus_name)


func get_volume(bus_name: String) -> float:
	return volumes[bus_name]


# Pushes a slider value to the real audio bus.
func _apply(bus_name: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return # Bus doesn't exist, so skip it.
	# Sliders are linear, but audio uses decibels, so convert.
	AudioServer.set_bus_volume_db(index, linear_to_db(volumes[bus_name]))
	# Fully mute at the bottom of the slider (linear_to_db(0) is -infinity).
	AudioServer.set_bus_mute(index, volumes[bus_name] <= 0.001)


func save_settings() -> void:
	var config := ConfigFile.new()
	for bus in BUS_NAMES:
		config.set_value("audio", bus, volumes[bus])
	config.save(SAVE_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return # No save file yet, so keep the defaults.
	for bus in BUS_NAMES:
		volumes[bus] = config.get_value("audio", bus, 1.0)
