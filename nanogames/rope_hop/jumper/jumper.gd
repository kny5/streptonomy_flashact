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


signal hit

const SPEED = 600

var _direction_speed := 0

onready var _collision_width_half: int =\
		($CollisionShape2D as CollisionShape2D).shape.extents.x

onready var _sprite_offset_x: int =\
		($CollisionShape2D/Sprite as Sprite).offset.x


func _ready() -> void:
	set_physics_process(false)

	# warning-ignore:return_value_discarded
	connect("area_entered", self, "_on_area_entered")


func _unhandled_input(_event: InputEvent) -> void:
	# Use `Input` instead of the received event so multiple actions can be
	# detected at once. Not directly placed in `_physics_process()` as to not
	# capture inputs when it shouldn't.
	_direction_speed = int(Input.get_axis("nanogame_left", "nanogame_right"))

	if not is_processing() and Input.is_action_just_pressed("nanogame_action"):
		($AnimationPlayer as AnimationPlayer).play("jump")
		($AnimationPlayer as AnimationPlayer).queue("idle")

	if _direction_speed != 0:
		($CollisionShape2D/Sprite as Sprite).offset.x =\
				abs(_sprite_offset_x) * _direction_speed
		($CollisionShape2D/Sprite as Sprite).flip_h = _direction_speed == -1

	_direction_speed *= SPEED


func _physics_process(delta: float) -> void:
	if _direction_speed == 0:
		return

	position.x += _direction_speed * delta
	position.x = clamp(position.x, _collision_width_half,
			NanogamePlayer.VIEW_SIZE.x - _collision_width_half)


func disable_hitbox() -> void:
	($CollisionShape2D as CollisionShape2D).disabled = true


func _on_area_entered(_area: Area2D) -> void:
	set_physics_process(false)

	($AnimationPlayer as AnimationPlayer).play("fall")

	emit_signal("hit")
