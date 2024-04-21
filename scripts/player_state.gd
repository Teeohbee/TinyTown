extends Node

enum QuestStatuses { NOT_STARTED, ACCEPTED, COMPLETED }

var reset_position = Vector2(584, 280)
var last_position = {}
var health = 15
var max_health = 15
var min_damage = 4
var max_damage = 6
var damage_reduction = 0.25
var quest_status = QuestStatuses.NOT_STARTED
var level = 1
var experience = 0
var experience_required = 10
var kill_count = 0
var engaging_boss = false
var sword_upgrade = false
var bow_upgrade = false
var armour_upgrade = false


func damage():
	return randi_range(min_damage, max_damage)


func progress_quest_status():
	quest_status = quest_status + 1


func will_level_up(experience_earned):
	return experience + experience_earned >= experience_required


func gain_experience(experience_earned):
	experience += experience_earned
	while experience >= experience_required:
		max_health += 5
		health += 5
		level += 1
		experience -= experience_required
		experience_required = roundi(experience_required * 1.5)


func apply_sword_upgrade():
	sword_upgrade = true
	min_damage += 3
	max_damage += 4


func apply_bow_upgrade():
	bow_upgrade = true
	min_damage += 3
	max_damage += 4


func apply_armour_upgrade():
	armour_upgrade = true
	damage_reduction = 0.25


func quest_completed():
	return quest_status == QuestStatuses.COMPLETED
