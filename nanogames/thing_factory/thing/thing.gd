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


signal destroyed(index)

var thing_index := 0 setget set_thing_index


func _input_event(
		_viewport: Object, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton or not event.is_pressed() or\
			event.button_mask != BUTTON_LEFT:
		return

	($Sprite as Sprite).hide()
	($Explosion as Particles2D).emitting = true
	($CollisionShape2D as CollisionShape2D).disabled = true
	($Destroy as AudioStreamPlayer2D).play()

	emit_signal("destroyed", thing_index)


func set_thing_index(index: int) -> void:
	if index < 0 or index >= ($Sprite as Sprite).hframes:
		push_error('Invalid thing of index "' + str(thing_index) + '".')

		return

	thing_index = index
	($Sprite as Sprite).frame = index


func is_destroyed() -> bool:
	return ($CollisionShape2D as CollisionShape2D).disabled


func get_thing_index_size() -> int:
	return ($Sprite as Sprite).hframes
