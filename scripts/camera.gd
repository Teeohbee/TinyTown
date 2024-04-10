extends Camera2D


func update_player_hud():
	update_sword_upgrade()
	update_bow_upgrade()
	update_label("Health", "HP: %d/%d" % [PlayerState.health, PlayerState.max_health])
	update_label(
		"Experience", "EXP: %d/%d" % [PlayerState.experience, PlayerState.experience_required]
	)
	update_label("Level", "LVL: %d" % PlayerState.level)


func update_label(name, text):
	get_node("CanvasLayer/CharacterPanel/VBoxContainer/" + name).text = text


func update_sword_upgrade():
	var sword_upgrade_icon = $CanvasLayer/CharacterPanel/VBoxContainer/HBoxContainer/SwordUpgrade
	if PlayerState.sword_upgrade == true:
		sword_upgrade_icon.show()
	else:
		sword_upgrade_icon.hide()


func update_bow_upgrade():
	var bow_upgrade_icon = $CanvasLayer/CharacterPanel/VBoxContainer/HBoxContainer/BowUpgrade
	if PlayerState.bow_upgrade == true:
		bow_upgrade_icon.show()
	else:
		bow_upgrade_icon.hide()
