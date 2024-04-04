extends Control

signal text_box_closed

enum Scene { WORLD, DUNGEON, CYCLOPS, WIZARD, GHOST, SPIDER, RAT }

const SCENES = {
	Scene.WORLD: "res://scenes/world.tscn",
	Scene.DUNGEON: "res://scenes/dungeon.tscn",
	Scene.CYCLOPS: "res://scenes/enemies/cyclops.tscn",
	Scene.GHOST: "res://scenes/enemies/ghost.tscn",
	Scene.RAT: "res://scenes/enemies/rat.tscn",
	Scene.SPIDER: "res://scenes/enemies/spider.tscn",
	Scene.WIZARD: "res://scenes/enemies/wizard.tscn"
}

# Constants for animation names and scene paths
const INTRO_ANIMATION = "intro"
var enemy_scene
var enemy


# Called when the node enters the scene tree for the first time.
func _ready():
	setup_enemy()
	update_health_bar($EnemyHealth/ProgressBar, enemy)
	update_health_bar($PlayerHealth/ProgressBar, PlayerState)
	show_text_box("A " + enemy.name + " draws near!")
	await self.text_box_closed
	hide_text_box()


func setup_enemy():
	enemy_scene = Scene.WIZARD if PlayerState.engaging_boss else random_enemy()
	enemy = load(SCENES[enemy_scene]).instantiate()
	add_child(enemy)
	enemy.get_node("AnimationPlayer").play(INTRO_ANIMATION)

func random_enemy():
	return [Scene.CYCLOPS, Scene.GHOST, Scene.RAT, Scene.SPIDER].pick_random()

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
		SceneTransition.change_scene_to_file(SCENES[Scene.DUNGEON])
	else:
		show_text_box("You couldn't escape!")
		await self.text_box_closed
		enemy_turn()


func _on_attack_pressed():
	show_text_box("You attack " + enemy.name + "!")
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
	show_text_box("The " + enemy.name + " attacks you!")
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
	show_text_box("You defeated " + enemy.name + "!")
	await self.text_box_closed
	show_text_box("You earned " + str(enemy.experience_earned) + " experience!")
	await self.text_box_closed
	if PlayerState.will_level_up(enemy.experience_earned):
		show_text_box("You leveled up!")
		await self.text_box_closed
	if enemy_scene == Scene.WIZARD:
		PlayerState.engaging_boss = false
		PlayerState.progress_quest_status()
	PlayerState.gain_experience(enemy.experience_earned)
	SceneTransition.change_scene_to_file(SCENES[Scene.DUNGEON])


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
