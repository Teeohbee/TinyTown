extends Area2D

# Walk onto this to travel to another map, arriving at the named spawn point there.

@export_file("*.tscn") var target_scene = ""
@export var target_spawn = ""


func _ready():
	area_entered.connect(_on_area_entered)


func _on_area_entered(area):
	if area.is_in_group("player"):
		area.warp_to(target_scene, target_spawn)
