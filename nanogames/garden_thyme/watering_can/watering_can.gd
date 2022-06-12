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


const SPEED = 450

var _direction_speed := Vector2()
var _movement_area := Rect2()


func _unhandled_input(_event: InputEvent) -> void:
	# Use `Input` instead of the received event so multiple actions can be
	# detected at once. Not directly placed in `_physics_process()` as to not
	# capture inputs when it shouldn't.
	_direction_speed = Input.get_vector("nanogame_left", "nanogame_right",
			"nanogame_up", "nanogame_down").normalized() * SPEED


func _physics_process(delta: float) -> void:
	if _direction_speed == Vector2.ZERO:
		return

	position += _direction_speed * delta
	position.x =\
			clamp(position.x, _movement_area.position.x, _movement_area.end.x)
	position.y =\
			clamp(position.y, _movement_area.position.y, _movement_area.end.y)


func disappear() -> void:
	# Defer it, to avoid error about flushing queries in physical objects.
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)

	($AnimationPlayer as AnimationPlayer).play_backwards("tilt")


func set_movement_area(area: Rect2) -> void:
	var hitbox_extents: Vector2 =\
			($CollisionShape2D as CollisionShape2D).shape.extents
	area.position.x += hitbox_extents.x
	area.position.y += hitbox_extents.y
	area.size.x -= hitbox_extents.x * 2
	area.size.y -= hitbox_extents.y * 2

	_movement_area = area


func get_hitbox_extents() -> Vector2:
	return ($CollisionShape2D as CollisionShape2D).shape.extents
