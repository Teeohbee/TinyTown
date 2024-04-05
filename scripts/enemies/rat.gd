extends TextureRect

@export var health = 12
@export var max_health = 12
@export var min_damage = 1
@export var max_damage = 4
@export var experience_earned = randi_range(3, 6)


func damage():
	return randi_range(min_damage, max_damage)
