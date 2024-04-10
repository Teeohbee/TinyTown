extends StaticBody2D

signal gain_bow_upgrade
# Returns the dialogue for this character
func dialogue():
	if PlayerState.kill_count < 7:
		return ["Hah! Another bullseye! Oh... Hi!", "You as good a shot as me?", "I'll give you my trusty bow if you", "can kill 7 enemies without dying"]
	if PlayerState.kill_count >= 7 and PlayerState.bow_upgrade == false:
		emit_signal("gain_bow_upgrade")
		return ["No way! You actually did it?", "This is so unfair... fine, have it!"]
	if PlayerState.kill_count >= 7 and PlayerState.bow_upgrade == true:
		return ["I've got nothing to say to you..."]
