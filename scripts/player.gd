extends Area2D

# The hero on the overworld: grid movement, talking to NPCs, random battles, warps.

const TILE_SIZE = 16
const STEP_SECONDS = 0.25
const BATTLE_SCENE_PATH = "res://scenes/battle.tscn"

const DIRECTIONS = {
	"ui_right": Vector2.RIGHT,
	"ui_left": Vector2.LEFT,
	"ui_up": Vector2.UP,
	"ui_down": Vector2.DOWN,
}

var moving = false
var busy = false
var facing = Vector2.DOWN

@onready var ray = $RayCast2D
@onready var sprite = $Sprite2D
@onready var camera = $Camera
@onready var hud = $HUD
@onready var pause_menu = $PauseMenu
@onready var lantern = $Lantern


func _ready():
	add_to_group("player")
	position = starting_position()
	camera.reset_smoothing()
	limit_camera_to_area()
	await get_tree().process_frame
	var area = current_area()
	if area != null:
		area.on_player_arrived(self)


func current_area():
	var scene = get_tree().current_scene
	if scene != null and scene.has_method("on_player_arrived"):
		return scene
	return null


# Coming back from a battle beats a warp spawn, which beats a loaded save position.
func starting_position():
	if PlayerState.battle_return_position != null:
		var returning_to = PlayerState.battle_return_position
		PlayerState.battle_return_position = null
		return returning_to
	if PlayerState.next_spawn_name != "":
		var spawn = find_spawn(PlayerState.next_spawn_name)
		PlayerState.next_spawn_name = ""
		if spawn != null:
			return spawn.global_position
	if PlayerState.saved_position != null:
		return PlayerState.saved_position
	var fallback_spawn = find_spawn("start")
	if fallback_spawn != null:
		return fallback_spawn.global_position
	return position


func find_spawn(spawn_name):
	for spawn in get_tree().get_nodes_in_group("spawn"):
		if spawn.name == spawn_name:
			return spawn
	return null


func limit_camera_to_area():
	var ground = get_parent().get_node_or_null("Ground")
	if ground == null:
		return
	var used = ground.get_used_rect()
	var top_left = ground.to_global(Vector2(used.position * TILE_SIZE))
	var bottom_right = ground.to_global(Vector2(used.end * TILE_SIZE))
	camera.limit_left = int(top_left.x)
	camera.limit_top = int(top_left.y)
	camera.limit_right = int(bottom_right.x)
	camera.limit_bottom = int(bottom_right.y)


func can_act():
	return not moving and not busy and not Dialogue.is_open() and not pause_menu.is_open() and not SceneTransition.is_transitioning()


func _process(_delta):
	if not can_act():
		return
	if Input.is_action_just_pressed("open_menu"):
		pause_menu.open_menu()
		return
	if Input.is_action_just_pressed("ui_accept"):
		var facing_thing = thing_in_direction(facing)
		if facing_thing != null and facing_thing.is_in_group("npc"):
			talk_to(facing_thing)
			return
	handle_movement()


func handle_movement():
	for direction_name in DIRECTIONS.keys():
		if Input.is_action_pressed(direction_name):
			var direction = DIRECTIONS[direction_name]
			face(direction)
			var blocker = thing_in_direction(direction)
			if blocker == null:
				move(direction)
			else:
				bump(direction)
				if blocker.is_in_group("npc"):
					talk_to(blocker)
			return


func face(direction):
	facing = direction
	if direction == Vector2.LEFT:
		sprite.flip_h = true
	elif direction == Vector2.RIGHT:
		sprite.flip_h = false


func thing_in_direction(direction):
	ray.target_position = direction * TILE_SIZE
	ray.force_raycast_update()
	if ray.is_colliding():
		return ray.get_collider()
	return null


func move(direction):
	moving = true
	Audio.play_sound("walking", randf_range(0.9, 1.1))
	var tween = create_tween()
	tween.tween_property(self, "position", position + direction * TILE_SIZE, STEP_SECONDS).set_trans(Tween.TRANS_SINE)
	var hop = create_tween()
	hop.tween_property(sprite, "position:y", -2.0, STEP_SECONDS / 2)
	hop.tween_property(sprite, "position:y", 0.0, STEP_SECONDS / 2)
	await tween.finished
	moving = false
	var area = current_area()
	if area != null:
		area.on_player_stepped(self)


func bump(direction):
	busy = true
	Audio.play_sound("bump")
	var tween = create_tween()
	tween.tween_property(sprite, "position", direction * 3, 0.06)
	tween.tween_property(sprite, "position", Vector2.ZERO, 0.08)
	await tween.finished
	await get_tree().create_timer(0.08).timeout
	busy = false


func talk_to(npc):
	busy = true
	await npc.interact(self)
	await get_tree().process_frame
	busy = false
	hud.refresh()
	get_tree().call_group("npc", "refresh_marker")


# --- Leaving the area ---


func start_battle(enemy_id, backdrop = ""):
	busy = true
	PlayerState.battle_enemy_id = enemy_id
	var area = current_area()
	if backdrop == "" and area != null:
		backdrop = area.battle_backdrop
	PlayerState.battle_backdrop = backdrop
	PlayerState.battle_return_position = position
	PlayerState.steps_since_last_battle = 0
	await flash_for_battle()
	SceneTransition.change_scene_to_file(BATTLE_SCENE_PATH)


func flash_for_battle():
	Audio.play_sound("intro", 2.0)
	var tween = create_tween()
	for flash in 3:
		tween.tween_property(sprite, "modulate", Color(3, 3, 3), 0.06)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.06)
	await tween.finished


func warp_to(scene_path, spawn_name):
	if busy:
		return
	busy = true
	PlayerState.next_spawn_name = spawn_name
	PlayerState.saved_position = null
	SceneTransition.change_scene_to_file(scene_path)


func save_here():
	return PlayerState.save_game(position)
