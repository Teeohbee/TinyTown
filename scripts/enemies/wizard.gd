extends TextureRect

@export var health = 50
@export var max_health = 50
@export var min_damage = 5
@export var max_damage = 10
@export var experience_earned = 100


func damage():
	return randi_range(min_damage, max_damage)
