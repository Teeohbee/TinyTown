extends CanvasLayer

# The one dialogue box for the whole game.
#   await Dialogue.say(["Hello!", "Lovely day."], "Granny")
#   var picked = await Dialogue.choose("Buy a potion?", ["Yes", "No"])   # returns the index
# Accept finishes the typewriter, then moves to the next line.

signal line_advanced
signal choice_made(choice_index)

var open = false
var typing = false
var accepting_input = false
var typed_characters = 0.0
var choosing = false

@onready var box = $Box
@onready var text_label = $Box/Text
@onready var next_arrow = $Box/NextArrow
@onready var speaker_panel = $Box/SpeakerPanel
@onready var speaker_name_label = $Box/SpeakerPanel/SpeakerName
@onready var choices_panel = $Choices
@onready var choice_list = $Choices/ChoiceList


func is_open():
	return open


func say(lines, speaker = ""):
	open_box(speaker)
	for line in lines:
		await show_line(line)
		await line_advanced
	close_box()


# Shows the question in the box with a list of answers beside it. Cancel picks the last one.
func choose(question, options, speaker = ""):
	open_box(speaker)
	await show_line(question)
	next_arrow.hide()
	for child in choice_list.get_children():
		child.queue_free()
	for index in options.size():
		var button = Button.new()
		button.text = options[index]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): pick_choice(index))
		button.focus_entered.connect(func(): Audio.play_sound("menu_select"))
		choice_list.add_child(button)
	choices_panel.reset_size()
	choices_panel.offset_top = choices_panel.offset_bottom - (options.size() * 52 + 32)
	choices_panel.show()
	choosing = true
	await get_tree().process_frame
	choice_list.get_child(0).grab_focus()
	var picked = await choice_made
	choosing = false
	choices_panel.hide()
	close_box()
	return picked


func pick_choice(index):
	if not choosing:
		return
	Audio.play_sound("menu_click")
	emit_signal("choice_made", index)


func open_box(speaker):
	open = true
	accepting_input = false
	speaker_name_label.text = speaker
	speaker_panel.visible = speaker != ""
	text_label.text = ""
	box.show()
	# Ignore the button press that started the conversation.
	await get_tree().process_frame
	accepting_input = true


func close_box():
	box.hide()
	# Stay "open" until the frame ends so the closing press doesn't also move or talk.
	await get_tree().process_frame
	if not box.visible:
		open = false


func show_line(line):
	text_label.text = line
	text_label.visible_characters = 0
	typed_characters = 0.0
	next_arrow.hide()
	typing = true
	if Settings.characters_per_second() <= 0.0:
		finish_typing()
	while typing:
		await get_tree().process_frame


func finish_typing():
	typing = false
	text_label.visible_characters = -1
	next_arrow.show()


func _process(delta):
	if not open:
		return
	if typing:
		typed_characters += delta * Settings.characters_per_second()
		var previous = text_label.visible_characters
		text_label.visible_characters = int(typed_characters)
		if text_label.visible_characters != previous and text_label.visible_characters % 3 == 0:
			Audio.play_sound("text_blip", 2.2)
		if text_label.visible_characters >= text_label.get_total_character_count():
			finish_typing()
	else:
		next_arrow.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
	if choosing:
		if Input.is_action_just_pressed("ui_cancel"):
			pick_choice(choice_list.get_child_count() - 1)
		return
	if accepting_input and Input.is_action_just_pressed("ui_accept"):
		if typing:
			finish_typing()
		else:
			Audio.play_sound("menu_click")
			emit_signal("line_advanced")
