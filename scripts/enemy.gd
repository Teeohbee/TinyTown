extends TextureRect

@export var enemy_name = "cyclops"
@export var health = 10
@export var max_health = 10
@export var damage = 3
@export var experience_earned = randi_range(3, 6)
@export var texture_source : Texture2D

func _ready():
	texture = texture_source
