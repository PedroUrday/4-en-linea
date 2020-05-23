extends Sprite

export (String) var color

func move_toward(target_position, motion_duration):
	$Tween.interpolate_property(self, 'position', position, target_position, motion_duration)
	$Tween.start()
