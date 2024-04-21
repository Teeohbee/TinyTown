extends StaticBody2D

signal gain_armour_upgrade


# Returns the dialogue for this character
func dialogue():
	if PlayerState.armour_upgrade == false:
		$AnimatedSprite2D.play("open")
		emit_signal("gain_armour_upgrade")
		return ["You found some armour!"]
