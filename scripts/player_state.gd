extends Node

enum QuestStatuses { NOT_STARTED, ACCEPTED, COMPLETED }

@export var reset_position = Vector2(520, 296)
@export var last_position = {}
@export var health = 10
@export var max_health = 10
@export var min_damage = 4
@export var max_damage = 6
@export var quest_status = QuestStatuses.NOT_STARTED
@export var level = 1
@export var experience = 0
@export var experience_required = 10
@export var kill_count = 0
@export var engaging_boss = false
@export var sword_upgrade = false
@export var bow_upgrade = false


func damage():
	return randi_range(min_damage, max_damage)


func progress_quest_status():
	quest_status = quest_status + 1


func will_level_up(experience_earned):
	return experience + experience_earned >= experience_required


func gain_experience(experience_earned):
	experience += experience_earned
	while experience >= experience_required:
		max_health = max_health + 5
		level += 1
		experience = experience - experience_required
		experience_required = roundi(experience_required * 1.5)


func apply_sword_upgrade():
	sword_upgrade = true
	min_damage += 3
	max_damage += 4


func apply_bow_upgrade():
	bow_upgrade = true
	min_damage += 3
	max_damage += 4
