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


const SPEED = 250

export var flipped := false

var _direction_speed := 0


func _ready() -> void:
	set_physics_process(false)

	if flipped:
		($CollisionShape2D/Sprite as Sprite).offset.x *= -1
		($CollisionShape2D/Sprite as Sprite).flip_h = true

	# warning-ignore:return_value_discarded
	connect("area_entered", self, "_on_area_entered")


func _physics_process(delta: float) -> void:
	if _direction_speed != 0:
		position.x += _direction_speed * delta


func jump(direction: int) -> void:
	_direction_speed = int(clamp(direction, -1, 1)) * SPEED

	($AnimationPlayer as AnimationPlayer).play("jump")
	($AnimationPlayer as AnimationPlayer).queue("idle")


func _on_area_entered(_area: Area2D) -> void:
	set_physics_process(false)

	($AnimationPlayer as AnimationPlayer).play("fall")
