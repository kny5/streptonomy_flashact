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


signal touched(index)

var gem_color := Color(1, 1, 1) setget set_gem_color

var _is_touched := false


func _unhandled_input(event: InputEvent) -> void:
	if _is_touched and event is InputEventMouse and\
			event.button_mask != BUTTON_LEFT:
		_is_touched = false


func _input_event(
		_viewport: Object, event: InputEvent, _shape_idx: int) -> void:
	if _is_touched or not event is InputEventMouse or\
			event.button_mask != BUTTON_LEFT:
		return

	_is_touched = true

	emit_signal("touched", get_index())


func set_gem_color(color: Color) -> void:
	gem_color = color

	($Gem as Sprite).self_modulate = color


func play_sound(pitch:=1.0) -> void:
	($Noise as AudioStreamPlayer2D).pitch_scale = pitch
	($Noise as AudioStreamPlayer2D).play()
