extends Control

# Turn-based battle against one enemy from scripts/data/enemies.gd.
# The whole fight is a coroutine: player turn -> enemy turn -> status ticks, until
# somebody drops. Every message waits for the accept button, like the original.

signal message_advanced
signal command_chosen(command, argument)

const Enemies = preload("res://scripts/data/enemies.gd")
const Items = preload("res://scripts/data/items.gd")
const Skills = preload("res://scripts/data/skills.gd")
const GAME_OVER_SCENE_PATH = "res://scenes/game_over.tscn"

const BASE_PLAYER_MISS_CHANCE = 0.05
const ENEMY_MISS_CHANCE = 0.06
const CRITICAL_HIT_CHANCE = 0.1
const CRITICAL_HIT_MULTIPLIER = 1.5
const SMASH_MULTIPLIER = 2.2
const ENRAGE_MULTIPLIER = 1.3
const HARDEN_BONUS_DEFENCE = 0.4
const RUN_CHANCE = 0.5
const MAX_ENEMY_HEALS = 2
const STATUS_TURNS = 3
const ENEMY_SPRITE_SIZE = 256
const BOSS_SPRITE_SIZE = 320

const HEALTH_COLOUR = Color(0.86, 0.25, 0.3)
const MAGIC_COLOUR = Color(0.3, 0.55, 0.95)
const DAMAGE_COLOUR = Color(1, 1, 1)
const CRITICAL_COLOUR = Color(1, 0.85, 0.2)
const HEAL_COLOUR = Color(0.45, 1, 0.5)
const PLAYER_DAMAGE_COLOUR = Color(1, 0.4, 0.35)

# Enemy state for this fight
var enemy_id = ""
var enemy = {}
var enemy_health = 0
var enemy_max_health = 0
var enemy_charging = false
var enemy_hardened_turns = 0
var enemy_stunned = false
var enemy_enraged = false
var enemy_heals_used = 0
var stolen_gold = 0
var idle_tween = null

# Player state for this fight
var defending = false
var battle_over = false
var waiting_for_message = false
var waiting_for_command = false

@onready var shaker = $Shaker
@onready var backdrop = $Shaker/Backdrop
@onready var enemy_sprite = $Shaker/EnemySprite
@onready var popups = $Shaker/Popups
@onready var player_name_label = $PlayerPanel/Rows/Name
@onready var player_health_bar = $PlayerPanel/Rows/HealthBar
@onready var player_magic_bar = $PlayerPanel/Rows/MagicBar
@onready var player_status_label = $PlayerPanel/Rows/Status
@onready var enemy_name_label = $EnemyPanel/Rows/Name
@onready var enemy_health_bar = $EnemyPanel/Rows/HealthBar
@onready var enemy_status_label = $EnemyPanel/Rows/Status
@onready var message_label = $MessagePanel/Text
@onready var next_arrow = $MessagePanel/NextArrow
@onready var command_panel = $CommandPanel
@onready var commands = $CommandPanel/Commands
@onready var submenu_panel = $SubmenuPanel
@onready var submenu_list = $SubmenuPanel/Scroll/List


func _ready():
	tint_bar(player_health_bar, HEALTH_COLOUR)
	tint_bar(player_magic_bar, MAGIC_COLOUR)
	tint_bar(enemy_health_bar, HEALTH_COLOUR)
	for button in commands.get_children():
		var command = button.name.to_lower()
		button.pressed.connect(func(): on_command_pressed(command))
		button.focus_entered.connect(func(): Audio.play_sound("menu_select"))
	command_panel.hide()
	setup_enemy()
	backdrop.show_backdrop(PlayerState.battle_backdrop)
	Audio.play_music("battle", 0.85 if enemy.get("boss", false) else 1.0)
	refresh_bars()
	await play_intro()
	run_battle()


func setup_enemy():
	enemy_id = PlayerState.battle_enemy_id
	if not Enemies.ENEMIES.has(enemy_id):
		enemy_id = "rat"
	enemy = Enemies.enemy(enemy_id)
	enemy_max_health = enemy["max_health"]
	enemy_health = enemy_max_health
	enemy_name_label.text = enemy["name"]
	enemy_sprite.texture = Enemies.texture(enemy_id)
	enemy_sprite.self_modulate = enemy.get("tint", Color.WHITE)
	var sprite_size = BOSS_SPRITE_SIZE if enemy.get("boss", false) else ENEMY_SPRITE_SIZE
	enemy_sprite.size = Vector2(sprite_size, sprite_size)
	enemy_sprite.position = Vector2(640 - sprite_size / 2.0, 432 - sprite_size)
	enemy_sprite.pivot_offset = Vector2(sprite_size / 2.0, sprite_size)


func play_intro():
	Audio.play_sound("intro", 2.0)
	enemy_sprite.scale = Vector2(0.2, 0.2)
	enemy_sprite.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(enemy_sprite, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(enemy_sprite, "scale", Vector2(1.15, 1.15), 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_property(enemy_sprite, "scale", Vector2.ONE, 0.15)
	await tween.finished
	start_idle_bob()
	if enemy.get("boss", false):
		shake(12.0)
		await say("%s blocks your path!" % enemy["name"])
	else:
		await say("A %s draws near!" % enemy["name"])


func start_idle_bob():
	idle_tween = create_tween().set_loops()
	idle_tween.tween_property(enemy_sprite, "scale", Vector2(1.03, 0.97), 0.6).set_trans(Tween.TRANS_SINE)
	idle_tween.tween_property(enemy_sprite, "scale", Vector2(0.97, 1.03), 0.6).set_trans(Tween.TRANS_SINE)


# --- The battle loop ---


func run_battle():
	while not battle_over:
		await player_turn()
		if battle_over:
			return
		if enemy_health <= 0:
			await win_battle()
			return
		await enemy_turn()
		if PlayerState.health <= 0:
			await lose_battle()
			return
		await end_of_round()
		if PlayerState.health <= 0:
			await lose_battle()
			return
		if enemy_health <= 0:
			await win_battle()
			return


func player_turn():
	defending = false
	refresh_bars()
	message_label.text = "What will you do?"
	next_arrow.hide()
	var choice = await wait_for_command()
	var command = choice[0]
	var argument = choice[1]
	match command:
		"attack":
			await player_attack()
		"skill":
			await use_skill(argument)
		"item":
			await use_item(argument)
		"defend":
			defending = true
			var restored = PlayerState.restore_magic(1)
			refresh_bars()
			if restored > 0:
				await say("You brace yourself. (+1 MP)")
			else:
				await say("You brace yourself!")
		"run":
			await try_to_run()


func wait_for_command():
	command_panel.show()
	await get_tree().process_frame
	commands.get_node("Attack").grab_focus()
	waiting_for_command = true
	var choice = await command_chosen
	waiting_for_command = false
	command_panel.hide()
	submenu_panel.hide()
	return choice


func on_command_pressed(command):
	if not waiting_for_command:
		return
	Audio.play_sound("menu_click")
	match command:
		"skill":
			open_skill_menu()
		"item":
			open_item_menu()
		_:
			emit_signal("command_chosen", command, "")


# --- Submenus ---


func open_skill_menu():
	clear_submenu()
	var known = Skills.known_skills(PlayerState)
	if known.is_empty():
		message_label.text = "You haven't learned any skills yet. (Level 2)"
		return
	for skill_id in known:
		var definition = Skills.skill(skill_id)
		var button = add_submenu_button(
			"%s  %d MP" % [definition["name"], definition["magic_cost"]],
			definition["description"],
			func(): emit_signal("command_chosen", "skill", skill_id))
		button.disabled = PlayerState.magic < definition["magic_cost"]
	open_submenu()


func open_item_menu():
	clear_submenu()
	for item_id in PlayerState.inventory.keys():
		if Items.is_key_item(item_id):
			continue
		var definition = Items.item(item_id)
		add_submenu_button(
			"%s  x%d" % [definition["name"], PlayerState.item_count(item_id)],
			definition["description"],
			func(): emit_signal("command_chosen", "item", item_id),
			Items.icon(item_id))
	if submenu_list.get_child_count() == 0:
		message_label.text = "You have no items to use."
		return
	open_submenu()


func clear_submenu():
	for child in submenu_list.get_children():
		submenu_list.remove_child(child)
		child.queue_free()


func add_submenu_button(text, description, on_pressed, icon = null):
	var button = Button.new()
	button.text = text
	button.icon = icon
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 40)
	button.pressed.connect(func():
		Audio.play_sound("menu_click")
		on_pressed.call())
	button.focus_entered.connect(func():
		Audio.play_sound("menu_select")
		message_label.text = description)
	submenu_list.add_child(button)
	return button


func open_submenu():
	submenu_panel.show()
	for button in submenu_list.get_children():
		if not button.disabled:
			button.grab_focus()
			return
	submenu_list.get_child(0).grab_focus()


func close_submenu():
	submenu_panel.hide()
	message_label.text = "What will you do?"
	commands.get_node("Attack").grab_focus()


# --- Player actions ---


func player_attack():
	await say("You attack the %s!" % enemy["name"])
	await strike_enemy(1.0, false)


# One hit on the enemy. Returns true if it landed.
func strike_enemy(multiplier, never_misses):
	var miss_chance = BASE_PLAYER_MISS_CHANCE + enemy.get("evasion", 0.0)
	if not never_misses and randf() < miss_chance:
		Audio.play_sound("bump")
		dodge_enemy()
		popup_text("MISS", enemy_popup_position(), Color(0.8, 0.8, 0.8))
		await say("The %s dodges!" % enemy["name"])
		return false
	var critical = randf() < CRITICAL_HIT_CHANCE
	var damage = PlayerState.damage() * multiplier
	if critical:
		damage *= CRITICAL_HIT_MULTIPLIER
	damage *= 1.0 - current_enemy_defence()
	var final_damage = maxi(1, roundi(damage))
	await hurt_enemy(final_damage, critical)
	if critical:
		await say("A critical hit! %d damage!" % final_damage)
	else:
		await say("You dealt %d damage!" % final_damage)
	return true


func current_enemy_defence():
	var defence = enemy.get("defence", 0.0)
	if enemy_hardened_turns > 0:
		defence += HARDEN_BONUS_DEFENCE
	return minf(defence, 0.8)


func hurt_enemy(amount, critical = false):
	enemy_health = maxi(0, enemy_health - amount)
	Audio.play_sound("enemy_hit")
	flash_enemy()
	shake(10.0 if critical else 5.0)
	popup_text(str(amount), enemy_popup_position(), CRITICAL_COLOUR if critical else DAMAGE_COLOUR, critical)
	refresh_bars()
	await get_tree().create_timer(0.25).timeout


func use_skill(skill_id):
	var definition = Skills.skill(skill_id)
	PlayerState.magic -= definition["magic_cost"]
	refresh_bars()
	await say("You use %s!" % definition["name"])
	match definition["effect"]:
		"strike":
			for hit in definition["hit_count"]:
				if enemy_health <= 0:
					break
				await strike_enemy(definition["damage_multiplier"], definition["never_misses"])
		"heal":
			var healed = PlayerState.heal(ceili(PlayerState.max_health * definition["heal_fraction"]))
			Audio.play_sound("heal")
			popup_text("+%d" % healed, player_popup_position(), HEAL_COLOUR)
			refresh_bars()
			await say("You recovered %d HP." % healed)
		"stun":
			var landed = await strike_enemy(definition["damage_multiplier"], false)
			if landed and enemy_health > 0:
				if randf() < definition["stun_chance"]:
					enemy_stunned = true
					enemy_charging = false
					await say("The %s is stunned!" % enemy["name"])
				else:
					await say("The %s shrugs it off." % enemy["name"])


func use_item(item_id):
	var definition = Items.item(item_id)
	await say("You use a %s!" % definition["name"])
	if definition.has("damage"):
		PlayerState.remove_item(item_id)
		Audio.play_sound("player_death", 1.6)
		await hurt_enemy(definition["damage"], true)
		await say("BOOM! %d damage!" % definition["damage"])
		return
	var health_before = PlayerState.health
	var message = PlayerState.use_item(item_id)
	Audio.play_sound("heal")
	if PlayerState.health > health_before:
		popup_text("+%d" % (PlayerState.health - health_before), player_popup_position(), HEAL_COLOUR)
	refresh_bars()
	await say(message)


func try_to_run():
	await say("You try to run away!")
	if enemy.get("boss", false) or enemy.get("cannot_flee", false):
		await say("There's no escape!")
		return
	if randf() < RUN_CHANCE:
		Audio.play_sound("runaway")
		await say("You got away safely!")
		battle_over = true
		leave_battle()
	else:
		await say("You couldn't escape!")


# --- Enemy turn ---


func enemy_turn():
	if enemy_stunned:
		enemy_stunned = false
		await say("The %s is too dazed to move." % enemy["name"])
		return
	if enemy.get("enrages_below_half", false) and not enemy_enraged and enemy_health * 2 <= enemy_max_health:
		enemy_enraged = true
		enemy_sprite.self_modulate = enemy.get("tint", Color.WHITE) * Color(1.3, 0.75, 0.75)
		shake(14.0)
		await say("The %s is furious!" % enemy["name"])
	if enemy_charging:
		enemy_charging = false
		await say("The %s unleashes a mighty smash!" % enemy["name"])
		await hit_player(SMASH_MULTIPLIER, true)
		return
	await use_enemy_ability(pick_enemy_ability())


func pick_enemy_ability():
	var weights = enemy["abilities"].duplicate()
	if enemy_health * 2 > enemy_max_health or enemy_heals_used >= MAX_ENEMY_HEALS:
		weights.erase("heal_self")
	if enemy_hardened_turns > 0:
		weights.erase("harden")
	if PlayerState.gold <= 0:
		weights.erase("steal")
	var total = 0
	for ability in weights.keys():
		total += weights[ability]
	var roll = randi_range(1, total)
	for ability in weights.keys():
		roll -= weights[ability]
		if roll <= 0:
			return ability
	return "attack"


func use_enemy_ability(ability):
	var enemy_name = enemy["name"]
	match ability:
		"attack":
			await say("The %s attacks!" % enemy_name)
			await hit_player(1.0, true)
		"nibble":
			var bites = randi_range(2, 3)
			await say("The %s bites again and again!" % enemy_name)
			var total_damage = 0
			for bite in bites:
				total_damage += await hit_player(0.5, false, false, false)
				await get_tree().create_timer(0.2).timeout
				if PlayerState.health <= 0:
					break
			await say("Bitten %d times for %d damage!" % [bites, total_damage])
		"poison_bite":
			await say("The %s sinks in its fangs!" % enemy_name)
			var landed = await hit_player(0.8, true)
			if landed and PlayerState.status_effect == "" and randf() < 0.6:
				await inflict_status("poison", STATUS_TURNS)
		"drain":
			await say("The %s drains your life!" % enemy_name)
			var damage = await hit_player(0.8, true)
			if damage > 0:
				var healed = mini(damage, enemy_max_health - enemy_health)
				enemy_health += healed
				refresh_bars()
				if healed > 0:
					popup_text("+%d" % healed, enemy_popup_position(), HEAL_COLOUR)
					await say("The %s recovered %d HP." % [enemy_name, healed])
		"heavy_windup":
			enemy_charging = true
			wind_up_animation()
			await say("The %s is winding up a mighty blow!" % enemy_name)
		"fireball":
			await say("The %s hurls a fireball!" % enemy_name)
			var damage = await hit_player(1.3, true, true)
			if damage > 0 and PlayerState.status_effect == "" and randf() < 0.3:
				await inflict_status("burn", STATUS_TURNS)
		"heal_self":
			enemy_heals_used += 1
			var healed = mini(ceili(enemy_max_health * 0.25), enemy_max_health - enemy_health)
			enemy_health += healed
			Audio.play_sound("heal")
			popup_text("+%d" % healed, enemy_popup_position(), HEAL_COLOUR)
			refresh_bars()
			await say("The %s heals itself for %d HP!" % [enemy_name, healed])
		"harden":
			enemy_hardened_turns = 2
			refresh_bars()
			await say("The %s hunkers down. Its defence rises!" % enemy_name)
		"engulf":
			await say("The %s tries to swallow you whole!" % enemy_name)
			await hit_player(1.25, true)
		"steal":
			var amount = mini(PlayerState.gold, randi_range(5, 15))
			PlayerState.gold -= amount
			stolen_gold += amount
			popup_text("-%dG" % amount, player_popup_position(), CRITICAL_COLOUR)
			await say("The %s snatched %d gold!" % [enemy_name, amount])
		"curse":
			await say("The %s mutters a dark curse..." % enemy_name)
			await hit_player(0.6, false, true)
			if PlayerState.health > 0 and PlayerState.status_effect == "":
				await inflict_status("poison", STATUS_TURNS + 1)
		_:
			await say("The %s attacks!" % enemy_name)
			await hit_player(1.0, true)


# Hits the player for a multiple of the enemy's damage. Returns the damage dealt (0 = miss).
func hit_player(multiplier, can_miss, ignores_armour = false, announce = true):
	if can_miss and randf() < ENEMY_MISS_CHANCE:
		Audio.play_sound("bump")
		popup_text("MISS", player_popup_position(), Color(0.8, 0.8, 0.8))
		await say("It missed!")
		return 0
	var damage = randi_range(enemy["min_damage"], enemy["max_damage"]) * multiplier
	if enemy_enraged:
		damage *= ENRAGE_MULTIPLIER
	if not ignores_armour:
		damage *= 1.0 - PlayerState.damage_reduction
	if defending:
		damage /= 2.0
	var final_damage = maxi(1, floori(damage))
	PlayerState.take_damage(final_damage)
	Audio.play_sound("player_hit")
	shake(8.0 if final_damage >= PlayerState.max_health / 4 else 4.0)
	flash_screen(Color(1, 0, 0, 0.25))
	popup_text(str(final_damage), player_popup_position(), PLAYER_DAMAGE_COLOUR)
	lunge_enemy()
	refresh_bars()
	if announce:
		await say("You took %d damage!" % final_damage)
	return final_damage


func inflict_status(status, turns):
	PlayerState.status_effect = status
	PlayerState.status_turns_left = turns
	refresh_bars()
	await say("You are %s!" % PlayerState.status_effect_description())


func end_of_round():
	if enemy_hardened_turns > 0:
		enemy_hardened_turns -= 1
		if enemy_hardened_turns == 0:
			refresh_bars()
	if "regenerate" in enemy.get("passives", []) and enemy_health < enemy_max_health and enemy_health > 0:
		var healed = mini(2, enemy_max_health - enemy_health)
		enemy_health += healed
		popup_text("+%d" % healed, enemy_popup_position(), HEAL_COLOUR)
		refresh_bars()
		await say("The %s oozes back together. (+%d HP)" % [enemy["name"], healed])
	if PlayerState.status_effect != "":
		var fraction = 0.06 if PlayerState.status_effect == "poison" else 0.08
		var damage = maxi(1, roundi(PlayerState.max_health * fraction))
		var description = PlayerState.status_effect_description()
		PlayerState.take_damage(damage)
		Audio.play_sound("player_hit", 1.4)
		popup_text(str(damage), player_popup_position(), Color(0.6, 1, 0.4))
		refresh_bars()
		PlayerState.status_turns_left -= 1
		await say("You are %s! You took %d damage." % [description, damage])
		if PlayerState.status_turns_left <= 0 and PlayerState.health > 0:
			PlayerState.clear_status()
			refresh_bars()
			await say("You feel better.")


# --- Endings ---


func win_battle():
	battle_over = true
	if idle_tween != null:
		idle_tween.kill()
	enemy_sprite.pivot_offset = enemy_sprite.size / 2
	Audio.play_sound("enemy_death")
	var tween = create_tween()
	tween.tween_property(enemy_sprite, "modulate", Color(3, 3, 3, 1), 0.1)
	tween.tween_property(enemy_sprite, "modulate", Color(1, 1, 1, 0), 0.4)
	tween.parallel().tween_property(enemy_sprite, "scale", Vector2(1.4, 0.1), 0.4)
	await tween.finished
	await say("You defeated the %s!" % enemy["name"])
	PlayerState.clear_status()
	PlayerState.record_victory()
	var experience_earned = randi_range(enemy["experience"][0], enemy["experience"][1])
	var gold_earned = randi_range(enemy["gold"][0], enemy["gold"][1])
	PlayerState.earn_gold(gold_earned + stolen_gold)
	await say("You earned %d EXP and %d gold." % [experience_earned, gold_earned])
	if stolen_gold > 0:
		await say("You got your %d stolen gold back, too." % stolen_gold)
	for drop in enemy.get("drops", []):
		if randf() < drop[1]:
			PlayerState.add_item(drop[0])
			Audio.play_sound("obtain_upgrade")
			await say("The %s dropped a %s!" % [enemy["name"], Items.display_name(drop[0])])
	var level_ups = PlayerState.gain_experience(experience_earned)
	for level_up in level_ups:
		Audio.play_sound("level_up")
		refresh_bars()
		await say("You reached level %d!" % level_up["level"])
		await say("Max HP +%d, Max MP +%d, Attack +%d." % [level_up["health"], level_up["magic"], level_up["damage"]])
		for skill_id in Skills.skills_learned_at_level(level_up["level"]):
			await say("You learned %s!" % Skills.skill(skill_id)["name"])
	for line in apply_story_for_victory():
		await say(line)
	leave_battle()


# Bosses move the story along.
func apply_story_for_victory():
	match enemy_id:
		"wizard":
			PlayerState.set_flag("wizard_defeated")
			PlayerState.set_quest_stage("bees", 2)
			return ["The wizard's spell breaks. Somewhere, a lot of bees are buzzing.", "Better tell Granny!"]
		"mole_king":
			PlayerState.set_flag("mole_king_defeated")
			PlayerState.add_item("iron_key")
			PlayerState.set_quest_stage("apprentice", 3)
			return ["The Mole King coughs up an Iron Key!", "It must open the deep gate."]
		"mordrin":
			PlayerState.set_flag("mordrin_defeated")
			PlayerState.set_quest_stage("apprentice", 4)
			return ["Mordrin crumbles into a pile of robes and dust.", "You hear someone shouting from the cage..."]
	return []


func lose_battle():
	battle_over = true
	Audio.stop_music()
	Audio.play_sound("player_death")
	flash_screen(Color(1, 0, 0, 0.5))
	await say("You were defeated...")
	SceneTransition.change_scene_to_file(GAME_OVER_SCENE_PATH)


func leave_battle():
	SceneTransition.change_scene_to_file(PlayerState.current_scene_path)


# --- Messages ---


func say(text):
	message_label.text = text
	message_label.visible_characters = 0
	next_arrow.hide()
	var shown = 0.0
	var characters_per_second = maxf(Settings.characters_per_second() * 1.5, 0.0)
	var total = message_label.get_total_character_count()
	waiting_for_message = true
	await get_tree().process_frame
	while characters_per_second > 0.0 and shown < total:
		if Input.is_action_just_pressed("ui_accept"):
			break
		shown += get_process_delta_time() * characters_per_second
		message_label.visible_characters = int(shown)
		await get_tree().process_frame
	message_label.visible_characters = -1
	next_arrow.show()
	await get_tree().process_frame
	await message_advanced
	waiting_for_message = false
	next_arrow.hide()


func _process(_delta):
	if waiting_for_message and next_arrow.visible and Input.is_action_just_pressed("ui_accept"):
		Audio.play_sound("menu_click")
		emit_signal("message_advanced")
	if waiting_for_message and next_arrow.visible:
		next_arrow.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
	if waiting_for_command and submenu_panel.visible and Input.is_action_just_pressed("ui_cancel"):
		Audio.play_sound("menu_click")
		close_submenu()


# --- Display ---


func tint_bar(bar, colour):
	var fill = bar.get_theme_stylebox("fill").duplicate()
	fill.bg_color = colour
	bar.add_theme_stylebox_override("fill", fill)


func refresh_bars():
	player_name_label.text = "Hero  Lv %d" % PlayerState.level
	player_health_bar.max_value = PlayerState.max_health
	player_health_bar.value = PlayerState.health
	player_health_bar.get_node("Label").text = "HP %d/%d" % [PlayerState.health, PlayerState.max_health]
	player_magic_bar.max_value = PlayerState.max_magic
	player_magic_bar.value = PlayerState.magic
	player_magic_bar.get_node("Label").text = "MP %d/%d" % [PlayerState.magic, PlayerState.max_magic]
	player_status_label.text = PlayerState.status_effect_description().capitalize()
	player_status_label.visible = player_status_label.text != ""
	enemy_health_bar.max_value = enemy_max_health
	enemy_health_bar.value = enemy_health
	enemy_health_bar.get_node("Label").text = "HP %d/%d" % [enemy_health, enemy_max_health]
	var enemy_statuses = []
	if enemy_hardened_turns > 0:
		enemy_statuses.append("Hardened")
	if enemy_enraged:
		enemy_statuses.append("Furious")
	if enemy_charging:
		enemy_statuses.append("Winding up!")
	enemy_status_label.text = "  ".join(enemy_statuses)
	enemy_status_label.visible = not enemy_statuses.is_empty()


func enemy_popup_position():
	return enemy_sprite.position + Vector2(enemy_sprite.size.x / 2 + randf_range(-30, 30), enemy_sprite.size.y * 0.3)


func player_popup_position():
	return Vector2(320 + randf_range(-20, 20), 110)


func popup_text(text, at_position, colour, big = false):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 96 if big else 72)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 12)
	label.position = at_position - Vector2(40, 40)
	popups.add_child(label)
	var tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 70, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.35)
	tween.tween_callback(label.queue_free)


func flash_enemy():
	var tween = create_tween()
	for flash in 3:
		tween.tween_property(enemy_sprite, "modulate", Color(4, 4, 4, 1), 0.05)
		tween.tween_property(enemy_sprite, "modulate", Color(1, 1, 1, 0.5), 0.05)
	tween.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.05)


func dodge_enemy():
	var start = enemy_sprite.position
	var tween = create_tween()
	tween.tween_property(enemy_sprite, "position:x", start.x + 60, 0.1)
	tween.tween_property(enemy_sprite, "position:x", start.x, 0.15)


func lunge_enemy():
	var start = enemy_sprite.position
	var tween = create_tween()
	tween.tween_property(enemy_sprite, "position:y", start.y + 30, 0.08)
	tween.tween_property(enemy_sprite, "position:y", start.y, 0.15)


func wind_up_animation():
	var tween = create_tween()
	tween.tween_property(enemy_sprite, "rotation", -0.15, 0.2)
	tween.tween_property(enemy_sprite, "rotation", 0.0, 0.3)
	refresh_bars()


func shake(strength):
	if not Settings.screen_shake:
		return
	var tween = create_tween()
	for step in 6:
		var offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(shaker, "position", offset, 0.03)
		strength *= 0.7
	tween.tween_property(shaker, "position", Vector2.ZERO, 0.03)


func flash_screen(colour):
	var flash = ColorRect.new()
	flash.color = colour
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween = flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)
