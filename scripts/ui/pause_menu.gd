extends CanvasLayer

# The field menu: bag, skills, quest log, status, options, save and quit.
# Left column picks a section; its list appears on the right. Cancel steps back out.

const Items = preload("res://scripts/data/items.gd")
const Skills = preload("res://scripts/data/skills.gd")
const Quests = preload("res://scripts/data/quests.gd")
const TITLE_SCENE_PATH = "res://scenes/title_screen.tscn"

var menu_open = false
var current_section = ""
var opened_on_frame = 0

@onready var section_buttons = $MenuPanel/Buttons
@onready var gold_label = $GoldPanel/Rows/Gold
@onready var time_label = $GoldPanel/Rows/Time
@onready var content_rows = $ContentPanel/Rows
@onready var heading_label = $ContentPanel/Rows/Heading
@onready var content_list = $ContentPanel/Rows/Scroll/List
@onready var description_label = $ContentPanel/Rows/Description
@onready var options_menu = $ContentPanel/OptionsMenu


func _ready():
	for button in section_buttons.get_children():
		var section = str(button.name)
		button.pressed.connect(func(): enter_section(section))
		button.focus_entered.connect(func(): on_section_focused(section))
	options_menu.closed.connect(leave_section)


func is_open():
	return menu_open


func open_menu():
	menu_open = true
	opened_on_frame = Engine.get_process_frames()
	get_tree().paused = true
	Audio.play_sound("menu_click")
	show()
	refresh_side_panel()
	section_buttons.get_node("Items").grab_focus()
	show_section("Items")


func close_menu():
	Audio.play_sound("menu_click")
	hide()
	get_tree().paused = false
	# Let the closing button press drain before the player can act again.
	await get_tree().process_frame
	menu_open = false


func _process(_delta):
	if not menu_open or Engine.get_process_frames() == opened_on_frame:
		return
	time_label.text = "Time " + PlayerState.format_play_time(PlayerState.play_time_seconds)
	if current_section == "Options":
		return
	var cancel_pressed = Input.is_action_just_pressed("ui_cancel")
	if current_section != "" and cancel_pressed:
		leave_section()
	elif current_section == "" and (cancel_pressed or Input.is_action_just_pressed("open_menu")):
		close_menu()


func refresh_side_panel():
	gold_label.text = "%d G" % PlayerState.gold


func on_section_focused(section):
	Audio.play_sound("menu_select")
	if current_section == "":
		show_section(section)


# Previews a section on the right without moving focus into it.
func show_section(section):
	options_menu.visible = section == "Options"
	content_rows.visible = section != "Options"
	description_label.text = ""
	clear_list()
	match section:
		"Items":
			heading_label.text = "Items"
			fill_items()
		"Skills":
			heading_label.text = "Skills"
			fill_skills()
		"Quests":
			heading_label.text = "Quests"
			fill_quests()
		"Status":
			heading_label.text = "Status"
			fill_status()
		"Save":
			heading_label.text = "Save"
			add_text_row("Save your progress here.")
			add_text_row(PlayerState.save_summary())
		"Title":
			heading_label.text = "Quit to Title"
			add_text_row("Unsaved progress since your last save will be lost.")
		"Close":
			heading_label.text = "Close"
			add_text_row("Back to the adventure.")


func enter_section(section):
	Audio.play_sound("menu_click")
	match section:
		"Close":
			close_menu()
			return
		"Save":
			save_game()
			return
		"Title":
			quit_to_title()
			return
		"Options":
			current_section = "Options"
			show_section("Options")
			options_menu.focus_first_row()
			return
	var first_button = first_focusable_row()
	if first_button == null:
		return
	current_section = section
	first_button.grab_focus()


func leave_section():
	var section = current_section
	current_section = ""
	show_section(section)
	section_buttons.get_node(section).grab_focus()


func first_focusable_row():
	for row in content_list.get_children():
		if row is Button and not row.disabled:
			return row
	return null


func clear_list():
	for child in content_list.get_children():
		content_list.remove_child(child)
		child.queue_free()


func add_text_row(text, colour = Color.WHITE):
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(840, 0)
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", colour)
	content_list.add_child(label)
	return label


func add_button_row(text, description, on_pressed, icon = null):
	var button = Button.new()
	button.text = text
	button.icon = icon
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 40)
	button.focus_entered.connect(func():
		Audio.play_sound("menu_select")
		description_label.text = description)
	if on_pressed != null:
		button.pressed.connect(on_pressed)
	content_list.add_child(button)
	return button


# --- Sections ---


func fill_items():
	if PlayerState.inventory.is_empty():
		add_text_row("Your bag is empty.")
		return
	var item_ids = PlayerState.inventory.keys()
	item_ids.sort_custom(func(a, b): return Items.is_key_item(a) == false and Items.is_key_item(b))
	for item_id in item_ids:
		var definition = Items.item(item_id)
		var label = "%s  x%d" % [definition["name"], PlayerState.item_count(item_id)]
		var description = definition["description"]
		if Items.is_key_item(item_id):
			description += "  (Key item)"
		add_button_row(label, description, func(): use_item_in_field(item_id), Items.icon(item_id))


func use_item_in_field(item_id):
	var definition = Items.item(item_id)
	if not definition.get("usable_in_field", false):
		description_label.text = "You can't use that here."
		return
	var message = PlayerState.use_item(item_id)
	Audio.play_sound("heal")
	refresh_after_use(message)


func refresh_after_use(message):
	var section = current_section
	show_section(section)
	description_label.text = message
	var first_button = first_focusable_row()
	if first_button == null:
		current_section = ""
		section_buttons.get_node(section).grab_focus()
		description_label.text = message
	else:
		first_button.grab_focus()
		description_label.text = message


func fill_skills():
	var known = Skills.known_skills(PlayerState)
	if known.is_empty():
		add_text_row("No skills yet. You'll learn one at level 2.")
		return
	for skill_id in known:
		var definition = Skills.skill(skill_id)
		var label = "%s  %d MP" % [definition["name"], definition["magic_cost"]]
		var on_pressed = null
		if definition["effect"] == "heal":
			on_pressed = func(): use_heal_skill_in_field(skill_id)
		add_button_row(label, definition["description"], on_pressed)


func use_heal_skill_in_field(skill_id):
	var definition = Skills.skill(skill_id)
	if PlayerState.magic < definition["magic_cost"]:
		description_label.text = "Not enough MP."
		return
	if not PlayerState.is_hurt():
		description_label.text = "You're already at full health."
		return
	PlayerState.magic -= definition["magic_cost"]
	var healed = PlayerState.heal(ceili(PlayerState.max_health * definition["heal_fraction"]))
	Audio.play_sound("heal")
	refresh_after_use("Recovered %d HP." % healed)


func fill_quests():
	var shown_any = false
	for show_completed in [false, true]:
		for quest_id in Quests.QUEST_ORDER:
			var stage = PlayerState.quest_stage(quest_id)
			if stage == 0:
				continue
			var complete = PlayerState.is_quest_complete(quest_id)
			if complete != show_completed:
				continue
			var definition = Quests.quest(quest_id)
			var title = ("[Done] " if complete else "") + definition["name"]
			add_button_row(title, Quests.stage_description(quest_id, stage), null)
			shown_any = true
	if not shown_any:
		add_text_row("No quests yet. Try talking to the townsfolk.")


func fill_status():
	var lines = [
		"Level %d   (EXP %d/%d)" % [PlayerState.level, PlayerState.experience, PlayerState.experience_required],
		"HP %d/%d   MP %d/%d" % [PlayerState.health, PlayerState.max_health, PlayerState.magic, PlayerState.max_magic],
		"Attack %d-%d" % [PlayerState.min_damage, PlayerState.max_damage],
		"Defence %d%%" % roundi(PlayerState.damage_reduction * 100),
		"",
		"Battles won %d   Win streak %d" % [PlayerState.battles_won, PlayerState.kills_since_last_defeat],
		"",
		"Equipment",
	]
	for line in lines:
		add_text_row(line)
	var equipment = {
		"sword_upgrade": "Blacksmith's Sword  (+3-4 attack)",
		"bow_upgrade": "Archer's Bow  (+3-4 attack, Volley)",
		"armour_upgrade": "Castle Armour  (35% defence)",
		"axe_upgrade": "Woodcutter's Axe  (+4-5 attack, Timber!)",
	}
	var has_any = false
	for flag in equipment.keys():
		if PlayerState.get(flag):
			add_text_row("  " + equipment[flag], Color(1, 0.9, 0.6))
			has_any = true
	if not has_any:
		add_text_row("  Just the clothes on your back.", Color(0.7, 0.7, 0.75))


func save_game():
	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.save_here():
		Audio.play_sound("obtain_upgrade")
		show_section("Save")
		description_label.text = "Game saved."
	else:
		description_label.text = "Couldn't save the game."


func quit_to_title():
	menu_open = false
	hide()
	SceneTransition.change_scene_to_file(TITLE_SCENE_PATH)
