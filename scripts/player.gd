extends Area2D

signal text_box_closed

# Constants
const TILE_SIZE = 16
const ANIMATION_SPEED = 4
const TWEEN_DURATION = 1.0
const BATTLE_SCENE_PATH = "res://scenes/battle.tscn"

# Variables
var inputs = {
	"ui_right": Vector2.RIGHT, "ui_left": Vector2.LEFT, "ui_up": Vector2.UP, "ui_down": Vector2.DOWN
}
var moving = false
var talking = false

@onready var ray = $RayCast2D


# Called when the node enters the scene tree for the first time.
func _ready():
	if PlayerState.last_position.has(self.get_parent().name):
		position = PlayerState.last_position[self.get_parent().name]
	else:
		position = PlayerState.reset_position
	$Camera.reset_smoothing()
	$Camera.update_player_hud()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	handle_movement()
	if Input.is_action_just_pressed("ui_focus_next"):
		SceneTransition.change_scene_to_file(BATTLE_SCENE_PATH)
		PlayerState.last_position[self.get_parent().name] = position
	if Input.is_action_just_pressed("ui_accept") and $Camera/CanvasLayer/DialoguePanel.visible:
		emit_signal("text_box_closed")


# Handles player movement
func handle_movement():
	if moving or talking:
		return
	for dir in inputs.keys():
		if Input.is_action_pressed(dir):
			if is_colliding(dir):
				$AnimationPlayer.play("bump_" + dir)
				interact_with_collider()
			else:
				move(dir)


func interact_with_collider():
	var collider = ray.get_collider()
	if not collider.is_in_group("npc"):
		return
	$Camera/CanvasLayer/DialoguePanel.show()
	talking = true
	for line in collider.dialogue():
		$Camera/CanvasLayer/DialoguePanel/TextBox.text = line
		await self.text_box_closed
	talking = false
	$Camera/CanvasLayer/DialoguePanel.hide()
	if collider.name == "Wizard":
		SceneTransition.change_scene_to_file(BATTLE_SCENE_PATH)


# Checks if the player will collide in the given direction
func is_colliding(dir):
	ray.target_position = inputs[dir] * TILE_SIZE
	ray.force_raycast_update()
	return ray.is_colliding()


# Moves the player in the given direction using a tween
func move(dir):
	var tween = create_tween()
	play_tween(tween, dir)
	moving = true
	await tween.finished
	#moving = false
	var chance = randi_range(0, 7)
	if self.get_parent().name == "Dungeon" and chance == 0:
		SceneTransition.change_scene_to_file(BATTLE_SCENE_PATH)
		PlayerState.last_position[self.get_parent().name] = position
	else:
		moving = false


# Plays the tween for the player movement
func play_tween(tween, dir):
	(
		tween
		. tween_property(
			self, "position", position + inputs[dir] * TILE_SIZE, TWEEN_DURATION / ANIMATION_SPEED
		)
		. set_trans(Tween.TRANS_SINE)
	)


func _on_dungeon_entrance_area_entered(_area):
	SceneTransition.change_scene_to_file("res://scenes/dungeon.tscn")
	PlayerState.last_position[self.get_parent().name] = Vector2(position.x, position.y + 12)


func _on_dungeon_exit_area_entered(_area):
	SceneTransition.change_scene_to_file("res://scenes/world.tscn")
	PlayerState.last_position[self.get_parent().name] = Vector2(position.x, position.y + 12)


func _on_maiden_player_healed():
	await self.text_box_closed
	PlayerState.health = PlayerState.max_health
	$Camera.update_player_hud()
