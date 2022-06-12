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


signal grabbed
signal released

var _is_grabbed := false

onready var _turn := $Turn as AudioStreamPlayer
onready var _turn_stop := $TurnStop as Timer


func _unhandled_input(event: InputEvent) -> void:
	if not _is_grabbed or not event is InputEventMouse:
		return

	if event.button_mask != BUTTON_LEFT:
		_is_grabbed = false

		_switch_grab_effect()

		emit_signal("released")

		return

	event.position.x -= get_canvas_transform().origin.x

	var rotation_old = rotation
	rotation = position.angle_to_point(event.position) - PI / 2
	if rotation != rotation_old:
		if not _turn.playing:
			_turn.play()

		_turn_stop.start()

func _input_event(
		_viewport: Object, event: InputEvent, _shape_idx: int) -> void:
	if _is_grabbed or not event is InputEventMouse or\
			event.button_mask != BUTTON_LEFT:
		return

	_is_grabbed = true

	_switch_grab_effect()

	emit_signal("grabbed")


func energize() -> void:
	# warning-ignore:return_value_discarded
	($Tween as Tween).interpolate_property($Handle/Glow as Sprite,
			"self_modulate:a", ($Handle/Glow as Sprite).self_modulate.a, 1,
			0.1)
	# warning-ignore:return_value_discarded
	($Tween as Tween).start()


func _switch_grab_effect() -> void:
	if _is_grabbed:
		($Handle/Grab).play()

	# warning-ignore:return_value_discarded
	($Tween as Tween).interpolate_property($Handle/Glow as Sprite,
			"self_modulate:a", ($Handle/Glow as Sprite).self_modulate.a,
			float(_is_grabbed) / 2, 0.1)
	# warning-ignore:return_value_discarded
	($Tween as Tween).start()
