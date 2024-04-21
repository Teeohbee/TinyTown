extends Camera2D

var paused = false
var flash = false
@onready
var sword_upgrade_icon = $CanvasLayer/CharacterPanel/VBoxContainer/HBoxContainer/SwordUpgrade
@onready var bow_upgrade_icon = $CanvasLayer/CharacterPanel/VBoxContainer/HBoxContainer/BowUpgrade
@onready
var armour_upgrade_icon = $CanvasLayer/CharacterPanel/VBoxContainer/HBoxContainer/ArmourUpgrade


func _process(delta):
	handle_pause()
	if paused:
		flash_text(delta)


# Handles the pause action
func handle_pause():
	if Input.is_action_just_pressed("ui_cancel"):
		paused = !paused
		get_tree().paused = paused
		$CanvasLayer/PauseLabel.visible = paused
		if paused:
			$CanvasLayer/PauseLabel.modulate.a = 1
			flash = true


# Flashes the "Paused" text
func flash_text(delta):
	var speed = 1
	if flash:
		$CanvasLayer/PauseLabel.modulate.a -= delta * speed
		if $CanvasLayer/PauseLabel.modulate.a <= 0:
			flash = false
	else:
		$CanvasLayer/PauseLabel.modulate.a += delta * speed
		if $CanvasLayer/PauseLabel.modulate.a >= 1:
			flash = true


func update_player_hud():
	update_sword_upgrade()
	update_bow_upgrade()
	update_armour_upgrade()
	update_label("Health", "HP: %d/%d" % [PlayerState.health, PlayerState.max_health])
	update_label(
		"Experience", "EXP: %d/%d" % [PlayerState.experience, PlayerState.experience_required]
	)
	update_label("Level", "LVL: %d" % PlayerState.level)


func update_label(name, text):
	get_node("CanvasLayer/CharacterPanel/VBoxContainer/" + name).text = text


func update_sword_upgrade():
	if PlayerState.sword_upgrade == true:
		sword_upgrade_icon.show()
	else:
		sword_upgrade_icon.hide()


func update_bow_upgrade():
	if PlayerState.bow_upgrade == true:
		bow_upgrade_icon.show()
	else:
		bow_upgrade_icon.hide()


func update_armour_upgrade():
	if PlayerState.armour_upgrade == true:
		armour_upgrade_icon.show()
	else:
		armour_upgrade_icon.hide()
