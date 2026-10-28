extends Node

# Player preferences, kept separately from the save game so they survive a new game.

signal changed

const SETTINGS_PATH = "user://settings.cfg"

const TEXT_SPEED_NAMES = ["Slow", "Normal", "Fast", "Instant"]
const CHARACTERS_PER_SECOND_FOR_TEXT_SPEED = [25.0, 50.0, 100.0, 0.0]

var music_volume_percent = 80
var sound_effects_volume_percent = 80
var fullscreen = false
var text_speed = 1
var screen_shake = true


func _ready():
	load_settings()
	apply_settings()


func characters_per_second():
	return CHARACTERS_PER_SECOND_FOR_TEXT_SPEED[text_speed]


func text_speed_name():
	return TEXT_SPEED_NAMES[text_speed]


func apply_settings():
	set_bus_volume("Music", music_volume_percent)
	set_bus_volume("SFX", sound_effects_volume_percent)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	emit_signal("changed")


func set_bus_volume(bus_name, volume_percent):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_mute(bus_index, volume_percent <= 0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_percent / 100.0))


func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume_percent", music_volume_percent)
	config.set_value("audio", "sound_effects_volume_percent", sound_effects_volume_percent)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "screen_shake", screen_shake)
	config.set_value("game", "text_speed", text_speed)
	config.save(SETTINGS_PATH)


func load_settings():
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	music_volume_percent = config.get_value("audio", "music_volume_percent", music_volume_percent)
	sound_effects_volume_percent = config.get_value(
		"audio", "sound_effects_volume_percent", sound_effects_volume_percent
	)
	fullscreen = config.get_value("video", "fullscreen", fullscreen)
	screen_shake = config.get_value("video", "screen_shake", screen_shake)
	text_speed = clampi(config.get_value("game", "text_speed", text_speed), 0, 3)
