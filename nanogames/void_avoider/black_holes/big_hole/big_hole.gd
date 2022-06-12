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


const SPEED = 75

var _direction_speed := Vector2()


func _ready() -> void:
	($Spawn as AudioStreamPlayer2D).play()


func _physics_process(delta: float) -> void:
	position += _direction_speed * delta


func set_target_position(target_position: Vector2) -> void:
	_direction_speed = (target_position - position).normalized() * SPEED


func get_hitbox_radius() -> float:
	return ($CollisionShape2D as CollisionShape2D).shape.radius


func _on_AnimationPlayer_animation_finished(_anim_name: String) -> void:
	($AnimationPlayer as AnimationPlayer).play("pulse")
