extends TextureRect

@export var health = 15
@export var max_health = 15
@export var min_damage = 2
@export var max_damage = 5
@export var experience_earned = randi_range(3, 6)


func damage():
	return randi_range(min_damage, max_damage)
