###############################################################################
# Librerama                                                                   #
# Copyright (C) 2022 Michael Alexsander                                       #
#-----------------------------------------------------------------------------#
# This file is part of Librerama.                                             #
#                                                                             #
# Librerama is free software: you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by        #
# the Free Software Foundation, either version 3 of the License, or           #
# (at your option) any later version.                                         #
#                                                                             #
# Librerama is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
# GNU General Public License for more details.                                #
#                                                                             #
# You should have received a copy of the GNU General Public License           #
# along with Librerama.  If not, see <http://www.gnu.org/licenses/>.          #
###############################################################################

extends Area2D


signal traveled

const TRAVEL_DISTANCE = 340


func travel(rotation: float) -> void:
	var tween := $Tween as Tween
	# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "position", position,
			position + Vector2.DOWN.rotated(rotation) * TRAVEL_DISTANCE,
			($AnimationPlayer as AnimationPlayer).get_animation(
					"travel").length)
	# warning-ignore:return_value_discarded
	tween.start()

	($Sprite as Sprite).rotation = rotation

	# Randomly flip the sprite and particles to add variation.
	if randi() % 2 == 0:
		($Sprite as Sprite).flip_h = true
		($Sprite/Trail as Particles2D).scale.x = -1

	($AnimationPlayer as AnimationPlayer).play("travel")


func _on_AnimationPlayer_animation_finished(_anim_name: String) -> void:
	emit_signal("traveled")

	queue_free()
