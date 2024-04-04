extends Control

signal text_box_closed

# Constants for animation names and scene paths
const INTRO_ANIMATION = "intro"
const WORLD_SCENE_PATH = "res://scenes/world.tscn"
const DUNGEON_SCENE_PATH = "res://scenes/dungeon.tscn"

var cyclops_scene = "res://scenes/enemies/cyclops.tscn"
var wizard_scene = "res://scenes/enemies/wizard.tscn"

@onready var enemy = load(cyclops_scene).instantiate()
@onready var enemy_name = enemy.enemy_name


# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(enemy)
	enemy.get_node("AnimationPlayer").play(INTRO_ANIMATION)
	update_health_bar($EnemyHealth/ProgressBar, enemy)
	update_health_bar($PlayerHealth/ProgressBar, PlayerState)
	show_text_box("A " + enemy_name + " draws near!")
	await self.text_box_closed
	hide_text_box()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and $Panel/TextBox.visible:
		emit_signal("text_box_closed")


# Changes the current scene to the world scene when the run button is pressed
func _on_run_pressed():
	show_text_box("You attempt to run away!")
	await self.text_box_closed
	var chance = randi_range(0, 1)
	if chance == 1:
		show_text_box("You managed to escape!")
		await self.text_box_closed
		SceneTransition.change_scene_to_file(DUNGEON_SCENE_PATH)
	else:
		show_text_box("You couldn't escape!")
		await self.text_box_closed
		enemy_turn()


func _on_attack_pressed():
	show_text_box("You attack " + enemy_name + "!")
	await self.text_box_closed
	enemy.health = max(0, enemy.health - PlayerState.damage)
	update_health_bar($EnemyHealth/ProgressBar, enemy)
	enemy.get_node("AnimationPlayer").play("takes_damage")
	show_text_box("You dealt " + str(PlayerState.damage) + " damage!")
	await self.text_box_closed
	if enemy.health == 0:
		enemy_death()
	else:
		enemy_turn()


func _on_defend_pressed():
	show_text_box("You take a defensive position!")
	await self.text_box_closed
	enemy_turn(true)


func enemy_turn(defending: bool = false):
	show_text_box("The " + enemy_name + " attacks you!")
	await self.text_box_closed
	var damage = enemy.damage / 2 if defending else enemy.damage
	PlayerState.health = max(0, PlayerState.health - damage)
	update_health_bar($PlayerHealth/ProgressBar, PlayerState)
	show_text_box("You took " + str(damage) + " damage!")
	await self.text_box_closed
	if PlayerState.health == 0:
		player_death()
	else:
		hide_text_box()


func player_death():
	show_text_box("You were defeated!")
	await self.text_box_closed
	show_text_box("GAME OVER!")


func enemy_death():
	enemy.get_node("AnimationPlayer").play("death")
	await enemy.get_node("AnimationPlayer").animation_finished
	show_text_box("You defeated " + enemy_name + "!")
	await self.text_box_closed
	show_text_box("You earned " + str(enemy.experience_earned) + " experience!")
	await self.text_box_closed
	if PlayerState.will_level_up(enemy.experience_earned):
		show_text_box("You leveled up!")
		await self.text_box_closed
	PlayerState.gain_experience(enemy.experience_earned)
	SceneTransition.change_scene_to_file(DUNGEON_SCENE_PATH)


func show_text_box(message):
	$Panel/TextBox.text = message
	$Panel/ActionButtons.hide()
	$Panel/TextBox.show()


func hide_text_box():
	$Panel/TextBox.hide()
	$Panel/ActionButtons.show()
	$Panel/ActionButtons/Attack.grab_focus()


func update_health_bar(health_bar, character):
	health_bar.value = character.health
	health_bar.max_value = character.max_health
	health_bar.get_node("Label").text = (
		"HP: " + str(character.health) + "/" + str(character.max_health)
	)
