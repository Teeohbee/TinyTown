extends Node

# Everything about the hero and the story so far. Saved to disk as JSON.

signal stats_changed

const Items = preload("res://scripts/data/items.gd")
const Quests = preload("res://scripts/data/quests.gd")

const SAVE_PATH = "user://save.json"
const SAVE_VERSION = 1
const STARTING_SCENE = "res://scenes/world.tscn"
const STARTING_SPAWN = "start"
const KILLS_FOR_BOW = 7
const LEVEL_FOR_SWORD = 3

# Hero
var level = 1
var experience = 0
var experience_required = 10
var health = 15
var max_health = 15
var magic = 6
var max_magic = 6
var min_damage = 4
var max_damage = 6
var damage_reduction = 0.15
var gold = 10
var status_effect = ""
var status_turns_left = 0

# Equipment, each one is a one-off upgrade
var sword_upgrade = false
var bow_upgrade = false
var armour_upgrade = false
var axe_upgrade = false

# Bag: item id -> count
var inventory = {}

# Story: quest id -> stage, plus one-off flags like "wizard_defeated"
var quests = {}
var flags = {}
var opened_chests = []

# Record keeping
var kill_count = 0
var kills_since_last_defeat = 0
var battles_won = 0
var play_time_seconds = 0.0

# Where the hero is. Not all of this is saved: battles are never saved mid-fight.
var current_scene_path = STARTING_SCENE
var next_spawn_name = STARTING_SPAWN
var saved_position = null
var battle_return_position = null
var battle_enemy_id = ""
var battle_backdrop = "dungeon"
var steps_since_last_battle = 0


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	new_game()


func _process(delta):
	if not get_tree().paused:
		play_time_seconds += delta


func new_game():
	level = 1
	experience = 0
	experience_required = 10
	health = 15
	max_health = 15
	magic = 6
	max_magic = 6
	min_damage = 4
	max_damage = 6
	damage_reduction = 0.15
	gold = 10
	status_effect = ""
	status_turns_left = 0
	sword_upgrade = false
	bow_upgrade = false
	armour_upgrade = false
	axe_upgrade = false
	inventory = {"potion": 2}
	quests = {}
	flags = {}
	opened_chests = []
	kill_count = 0
	kills_since_last_defeat = 0
	battles_won = 0
	play_time_seconds = 0.0
	current_scene_path = STARTING_SCENE
	next_spawn_name = STARTING_SPAWN
	saved_position = null
	battle_return_position = null
	steps_since_last_battle = 0


# --- Combat stats ---


func damage():
	return randi_range(min_damage, max_damage)


func is_hurt():
	return health < max_health


func heal(amount):
	var before = health
	health = mini(max_health, health + amount)
	emit_signal("stats_changed")
	return health - before


func restore_magic(amount):
	var before = magic
	magic = mini(max_magic, magic + amount)
	emit_signal("stats_changed")
	return magic - before


func full_restore():
	health = max_health
	magic = max_magic
	clear_status()
	emit_signal("stats_changed")


func take_damage(amount):
	health = maxi(0, health - amount)
	emit_signal("stats_changed")


func clear_status():
	status_effect = ""
	status_turns_left = 0


# --- Levelling ---


func will_level_up(experience_earned):
	return experience + experience_earned >= experience_required


# Returns a list of level-up summaries, one per level gained.
func gain_experience(experience_earned):
	var level_ups = []
	experience += experience_earned
	while experience >= experience_required:
		experience -= experience_required
		experience_required = roundi(experience_required * 1.5)
		level += 1
		var health_gain = 5
		var magic_gain = 2
		max_health += health_gain
		health += health_gain
		max_magic += magic_gain
		magic += magic_gain
		min_damage += 1
		max_damage += 1
		level_ups.append({"level": level, "health": health_gain, "magic": magic_gain, "damage": 1})
	emit_signal("stats_changed")
	return level_ups


func record_victory():
	kill_count += 1
	kills_since_last_defeat += 1
	battles_won += 1


# Losing a battle: wake up in town, lighter of purse, with the archer's streak reset.
func record_defeat():
	kills_since_last_defeat = 0
	experience = 0
	gold = gold / 2
	health = 1
	magic = max_magic
	clear_status()
	current_scene_path = STARTING_SCENE
	next_spawn_name = "maiden"
	saved_position = null
	battle_return_position = null


# --- Equipment ---


func apply_sword_upgrade():
	sword_upgrade = true
	min_damage += 3
	max_damage += 4
	emit_signal("stats_changed")


func apply_bow_upgrade():
	bow_upgrade = true
	min_damage += 3
	max_damage += 4
	emit_signal("stats_changed")


# The original armour set damage_reduction to the value it already had, so it did nothing.
func apply_armour_upgrade():
	armour_upgrade = true
	damage_reduction = 0.35
	emit_signal("stats_changed")


func apply_axe_upgrade():
	axe_upgrade = true
	min_damage += 4
	max_damage += 5
	emit_signal("stats_changed")


# --- Bag ---


func add_item(item_id, count = 1):
	inventory[item_id] = inventory.get(item_id, 0) + count
	emit_signal("stats_changed")


func remove_item(item_id, count = 1):
	var remaining = inventory.get(item_id, 0) - count
	if remaining > 0:
		inventory[item_id] = remaining
	else:
		inventory.erase(item_id)
	emit_signal("stats_changed")


func has_item(item_id):
	return inventory.get(item_id, 0) > 0


func item_count(item_id):
	return inventory.get(item_id, 0)


func spend_gold(amount):
	if gold < amount:
		return false
	gold -= amount
	emit_signal("stats_changed")
	return true


func earn_gold(amount):
	gold += amount
	emit_signal("stats_changed")


# Applies a consumable's effect. Returns a sentence describing what happened.
func use_item(item_id):
	var definition = Items.item(item_id)
	var messages = []
	if definition.has("heal_health"):
		var healed = heal(definition["heal_health"])
		messages.append("Recovered %d HP." % healed)
	if definition.has("heal_magic"):
		var restored = restore_magic(definition["heal_magic"])
		messages.append("Recovered %d MP." % restored)
	if definition.get("cures_status", false):
		if status_effect == "":
			messages.append("You feel fine already.")
		else:
			messages.append("You are no longer %s." % status_effect_description())
		clear_status()
	remove_item(item_id)
	return " ".join(messages)


func status_effect_description():
	match status_effect:
		"poison":
			return "poisoned"
		"burn":
			return "burning"
	return ""


# --- Quests and story ---


func quest_stage(quest_id):
	return quests.get(quest_id, 0)


func set_quest_stage(quest_id, stage):
	quests[quest_id] = stage


func is_quest_complete(quest_id):
	return quest_stage(quest_id) == Quests.final_stage(quest_id)


func has_flag(flag_name):
	return flags.get(flag_name, false)


func set_flag(flag_name):
	flags[flag_name] = true


func is_chest_opened(chest_id):
	return opened_chests.has(chest_id)


func mark_chest_opened(chest_id):
	if not opened_chests.has(chest_id):
		opened_chests.append(chest_id)


# --- Saving ---


func has_save():
	return FileAccess.file_exists(SAVE_PATH)


func save_game(position_in_scene):
	saved_position = position_in_scene
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(to_dictionary(), "\t"))
	return true


func load_game():
	if not has_save():
		return false
	var text = FileAccess.get_file_as_string(SAVE_PATH)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save file is unreadable, ignoring it")
		return false
	new_game()
	from_dictionary(data)
	return true


func save_summary():
	if not has_save():
		return ""
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	return "Lv %d  -  %s" % [data.get("level", 1), format_play_time(data.get("play_time_seconds", 0))]


static func format_play_time(seconds):
	var total_minutes = int(seconds) / 60
	return "%d:%02d" % [total_minutes / 60, total_minutes % 60]


const SAVED_FIELDS = [
	"level", "experience", "experience_required", "health", "max_health", "magic",
	"max_magic", "min_damage", "max_damage", "damage_reduction", "gold", "status_effect",
	"status_turns_left", "sword_upgrade", "bow_upgrade", "armour_upgrade", "axe_upgrade",
	"inventory", "quests", "flags", "opened_chests", "kill_count", "kills_since_last_defeat",
	"battles_won", "play_time_seconds", "current_scene_path",
]

const WHOLE_NUMBER_FIELDS = [
	"level", "experience", "experience_required", "health", "max_health", "magic",
	"max_magic", "min_damage", "max_damage", "gold", "status_turns_left", "kill_count",
	"kills_since_last_defeat", "battles_won",
]


func to_dictionary():
	var data = {"version": SAVE_VERSION}
	for field in SAVED_FIELDS:
		data[field] = get(field)
	data["position_x"] = saved_position.x
	data["position_y"] = saved_position.y
	return data


# JSON turns every number into a float, so whole-number fields are converted back.
func from_dictionary(data):
	for field in SAVED_FIELDS:
		if not data.has(field):
			continue
		var value = data[field]
		if WHOLE_NUMBER_FIELDS.has(field):
			value = int(value)
		set(field, value)
	for item_id in inventory.keys():
		inventory[item_id] = int(inventory[item_id])
	for quest_id in quests.keys():
		quests[quest_id] = int(quests[quest_id])
	saved_position = Vector2(data.get("position_x", 0), data.get("position_y", 0))
	next_spawn_name = ""
