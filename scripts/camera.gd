extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func update_player_hud():
	update_label("Health", "HP: %d/%d" % [PlayerState.health, PlayerState.max_health])
	update_label(
		"Experience", "EXP: %d/%d" % [PlayerState.experience, PlayerState.experience_required]
	)
	update_label("Level", "LVL: %d" % PlayerState.level)


func update_label(name, text):
	get_node("CanvasLayer/CharacterPanel/VBoxContainer/" + name).text = text
