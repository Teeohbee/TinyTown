extends Node2D

# Root script for every explorable map: music, random battles, darkness, autosave.

const Enemies = preload("res://scripts/data/enemies.gd")

@export var display_name = ""
@export var music_name = "town"
@export var music_pitch = 1.0
# Enemy ids from scripts/data/enemies.gd. Empty means a safe area.
@export var encounter_table: Array[String] = []
@export_range(0.0, 1.0) var encounter_chance = 0.12
# A few free steps after every battle so fights don't come back to back.
@export var steps_before_encounters = 6
@export var battle_backdrop = "dungeon"
@export var dark = false


func _ready():
	Audio.play_music(music_name, music_pitch)
	PlayerState.current_scene_path = scene_file_path
	if dark:
		var darkness = CanvasModulate.new()
		darkness.color = Color(0.16, 0.13, 0.2)
		add_child(darkness)


func on_player_arrived(player):
	player.lantern.enabled = dark
	player.hud.show_area_name(display_name)
	player.save_here()
	get_tree().call_group("npc", "refresh_marker")


func on_player_stepped(player):
	if encounter_table.is_empty():
		return
	PlayerState.steps_since_last_battle += 1
	if PlayerState.steps_since_last_battle < steps_before_encounters:
		return
	if randf() < encounter_chance:
		player.start_battle(encounter_table.pick_random())
