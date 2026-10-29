extends PointLight2D

# Gentle flicker for wall torches.

var base_energy = 1.0
var time_offset = 0.0


func _ready():
	base_energy = energy
	time_offset = randf() * 10.0


func _process(_delta):
	var time = Time.get_ticks_msec() / 1000.0 + time_offset
	energy = base_energy * (0.85 + 0.1 * sin(time * 7.0) + 0.05 * sin(time * 23.0))
