extends Node

# One place for music and sound effects.
#   Audio.play_music("town")    crossfades to the town theme (no-op if already playing)
#   Audio.play_sound("heal")    fires a one-shot sound on the SFX bus

const MUSIC_FILES = {
	"town": "res://assets/audio/town.ogg",
	"dungeon": "res://assets/audio/dungeon.ogg",
	"battle": "res://assets/audio/battle.ogg",
}

const SOUND_FILES = {
	"bump": "res://assets/audio/bump.ogg",
	"enemy_death": "res://assets/audio/enemy_death.ogg",
	"enemy_hit": "res://assets/audio/enemy_hit.ogg",
	"heal": "res://assets/audio/heal.ogg",
	"intro": "res://assets/audio/intro.ogg",
	"level_up": "res://assets/audio/level_up.ogg",
	"menu_click": "res://assets/audio/menu_click.ogg",
	"menu_select": "res://assets/audio/menu_select.ogg",
	"obtain_upgrade": "res://assets/audio/obtain_upgrade.ogg",
	"player_death": "res://assets/audio/player_death.ogg",
	"player_hit": "res://assets/audio/player_hit.ogg",
	"runaway": "res://assets/audio/runaway.ogg",
	"start_game": "res://assets/audio/start_game.ogg",
	"walking": "res://assets/audio/walking.ogg",
	"text_blip": "res://assets/audio/menu_select.ogg",
}

# Per-track trims so nothing is louder than the old -10 dB scene players.
const MUSIC_VOLUME_DB = -10.0
const SOUND_VOLUME_DB = {"walking": -10.0, "bump": -4.0, "text_blip": -16.0}
const CROSSFADE_SECONDS = 0.8
const SOUND_PLAYER_COUNT = 8

var current_music_name = ""
var music_players = []
var active_music_player_index = 0
var sound_players = []
var next_sound_player_index = 0
var loaded_streams = {}


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in 2:
		var music_player = AudioStreamPlayer.new()
		music_player.bus = "Music"
		music_player.volume_db = -80.0
		add_child(music_player)
		music_players.append(music_player)
	for index in SOUND_PLAYER_COUNT:
		var sound_player = AudioStreamPlayer.new()
		sound_player.bus = "SFX"
		add_child(sound_player)
		sound_players.append(sound_player)


func play_music(music_name, pitch = 1.0):
	if music_name == current_music_name:
		return
	current_music_name = music_name
	var outgoing_player = music_players[active_music_player_index]
	active_music_player_index = 1 - active_music_player_index
	var incoming_player = music_players[active_music_player_index]
	fade_player(outgoing_player, -80.0, true)
	if music_name == "":
		return
	incoming_player.stream = stream_for(MUSIC_FILES[music_name])
	set_looping(incoming_player.stream)
	incoming_player.pitch_scale = pitch
	incoming_player.volume_db = -40.0
	incoming_player.play()
	fade_player(incoming_player, MUSIC_VOLUME_DB, false)


func stop_music():
	play_music("")


func fade_player(player, target_volume_db, stop_when_done):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", target_volume_db, CROSSFADE_SECONDS)
	if stop_when_done:
		tween.tween_callback(player.stop)


func play_sound(sound_name, pitch = 1.0):
	var sound_player = sound_players[next_sound_player_index]
	next_sound_player_index = (next_sound_player_index + 1) % SOUND_PLAYER_COUNT
	sound_player.stream = stream_for(SOUND_FILES[sound_name])
	sound_player.pitch_scale = pitch
	sound_player.volume_db = SOUND_VOLUME_DB.get(sound_name, 0.0)
	sound_player.play()
	return sound_player


# Plays a sound and waits for it to finish, for moments the game should hold on.
func play_sound_and_wait(sound_name, pitch = 1.0):
	var sound_player = play_sound(sound_name, pitch)
	await sound_player.finished


func stream_for(path):
	if not loaded_streams.has(path):
		loaded_streams[path] = load(path)
	return loaded_streams[path]


func set_looping(stream):
	if stream is AudioStreamOggVorbis:
		stream.loop = true
