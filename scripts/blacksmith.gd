extends StaticBody2D

signal gain_sword_upgrade

# Returns the dialogue for this character
func dialogue():
	if PlayerState.level == 1:
		return ["Hrmph, you look weak...", "Too weak to wield my swords", "Come back when you're stronger"]
	if PlayerState.level == 2:
		return ["You've got stronger, not bad", "A little more and I'll give you", "one of my swords!"]
	if PlayerState.level >= 3 and PlayerState.sword_upgrade == false:
		emit_signal("gain_sword_upgrade")
		return ["Very well, a promise is a promise.", "Here, your new blade"]
	if PlayerState.level >= 3 and PlayerState.sword_upgrade == true:
		return ["How's that new sword treating you?", "Go get killing son"]
