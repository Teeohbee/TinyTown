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
	$AudioManager/Intro.play()
	enemy.get_node("AnimationPlayer").play(INTRO_ANIMATION)


func random_enemy():
	return [Scene.CYCLOPS, Scene.GHOST, Scene.RAT, Scene.SPIDER].pick_random()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	handle_input()


func handle_input():
	if pressed("ui_accept") and $Panel/TextBox.visible:
		emit_signal("text_box_closed")
	if pressed("ui_accept"):
		$AudioManager/MenuClick.play()
	if !$Panel/TextBox.visible and (pressed("ui_left") or pressed("ui_right")):
		$AudioManager/MenuSelect.play()


# Changes the current scene to the world scene when the run button is pressed
func _on_run_pressed():
	show_text_box("You attempt to run away!")
	await self.text_box_closed
	var chance = randi_range(0, 1)
	if chance == 1 and enemy_scene != Scene.WIZARD:
		show_text_box("You managed to escape!")
		await self.text_box_closed
		$AudioManager/Runaway.play()
		await $AudioManager/Runaway.finished
		PlayerState.engaging_boss = false
		SceneTransition.change_scene_to_file(SCENES[Scene.DUNGEON])
	else:
		show_text_box("You couldn't escape!")
		await self.text_box_closed
		enemy_turn()


func _on_attack_pressed():
	show_text_box("You attack " + enemy.name + "!")
	await self.text_box_closed
	var player_damage = PlayerState.damage()
	enemy.health = max(0, enemy.health - player_damage)
	update_health_bar($EnemyHealth/ProgressBar, enemy)
	enemy.get_node("AnimationPlayer").play("takes_damage")
	$AudioManager/EnemyHit.play()
	show_text_box("You dealt " + str(player_damage) + " damage!")
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
	var enemy_damage = enemy.damage()
	var adjusted_for_damage_reduction = enemy_damage * (1 - PlayerState.damage_reduction)
	var adjusted_for_defending = (
		adjusted_for_damage_reduction / 2 if defending else adjusted_for_damage_reduction
	)
	var rounded_damage = floori(adjusted_for_defending)
	PlayerState.health = max(0, PlayerState.health - rounded_damage)
	update_health_bar($PlayerHealth/ProgressBar, PlayerState)
	$AudioManager/PlayerHit.play()
	show_text_box("You took " + str(rounded_damage) + " damage!")
	await self.text_box_closed
	if PlayerState.health == 0:
		player_death()
	else:
		hide_text_box()


func player_death():
	show_text_box("You were defeated!")
	await self.text_box_closed
	show_text_box("GAME OVER!")
	$AudioManager/PlayerDeath.play()
	await $AudioManager/PlayerDeath.finished
	await self.text_box_closed
	PlayerState.engaging_boss = false
	PlayerState.health = 1
	PlayerState.experience = 0
	PlayerState.kill_count = 0
	PlayerState.last_position = {}
	SceneTransition.change_scene_to_file(SCENES[Scene.WORLD])


func enemy_death():
	enemy.get_node("AnimationPlayer").play("death")
	$AudioManager/EnemyDeath.play()
	await enemy.get_node("AnimationPlayer").animation_finished
	show_text_box("You defeated " + enemy.name + "!")
	await self.text_box_closed
	show_text_box("You earned " + str(enemy.experience_earned) + " experience!")
	await self.text_box_closed
	if PlayerState.will_level_up(enemy.experience_earned):
		show_text_box("You leveled up!")
		$AudioManager/LevelUp.play()
		await self.text_box_closed
	if enemy_scene == Scene.WIZARD:
		PlayerState.engaging_boss = false
		PlayerState.progress_quest_status()
	PlayerState.gain_experience(enemy.experience_earned)
	PlayerState.kill_count += 1
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


func pressed(input):
	return Input.is_action_just_pressed(input)
