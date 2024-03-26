extends Node

enum QuestStatuses { NOT_STARTED, ACCEPTED, COMPLETED }

@export var reset_position = Vector2(520, 296)
@export var last_position = {}
@export var enemy_name = "cyclops"
@export var health = 15
@export var max_health = 15
@export var damage = 5
@export var quest_status = QuestStatuses.NOT_STARTED


func progress_quest_status():
	quest_status = quest_status + 1
