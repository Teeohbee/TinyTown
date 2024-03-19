extends Area2D

# Constants
const TILE_SIZE = 16
const ANIMATION_SPEED = 4
const TWEEN_DURATION = 1.0
const BATTLE_SCENE_PATH = "res://battle.tscn"

# Variables
var inputs = {
	"ui_right": Vector2.RIGHT, "ui_left": Vector2.LEFT, "ui_up": Vector2.UP, "ui_down": Vector2.DOWN
}
var moving = false

@onready var ray = $RayCast2D


# Called when the node enters the scene tree for the first time.
func _ready():
	position = PlayerState.last_position
	$Camera2D.reset_smoothing()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	handle_movement()
	if Input.is_action_just_pressed("ui_accept"):
		SceneTransition.change_scene_to_file(BATTLE_SCENE_PATH)
		PlayerState.last_position = position


# Handles player movement
func handle_movement():
	if moving:
		return
	for dir in inputs.keys():
		if Input.is_action_pressed(dir):
			if is_colliding(dir):
				$AnimationPlayer.play("bump_" + dir)
			else:
				move(dir)


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
	SceneTransition.change_scene_to_file(BATTLE_SCENE_PATH)
	PlayerState.last_position = position
