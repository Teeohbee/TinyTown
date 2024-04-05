extends TextureRect

@export var health = 10
@export var max_health = 10
@export var min_damage = 2
@export var max_damage = 4
@export var experience_earned = randi_range(3, 6)


func damage():
	return randi_range(min_damage, max_damage)
