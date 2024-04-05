extends TextureRect

@export var health = 7
@export var max_health = 7
@export var min_damage = 3
@export var max_damage = 4
@export var experience_earned = randi_range(3, 6)


func damage():
	return randi_range(min_damage, max_damage)
