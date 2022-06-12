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

extends Node2D


signal ended(has_won)

const HOUR_CONVERSION = 360 / 12
const MINUTE_LOOSE_CONVERSION = 360 / 6
const MINUTE_PRECISE_CONVERSION = 360 / 60

var _hour_time_goal := 0
var _minute_time_goal := 0

var _difficulty := 0

var _minute: Area2D
onready var _hour := $Hour as Area2D


func nanogame_prepare(difficulty: int, _debug_code: int) -> void:
	_difficulty = difficulty

	_hour_time_goal = randi() % 12
	while true:
		var hour_time: int = randi() % 12
		if hour_time != _hour_time_goal:
			_hour.rotation = deg2rad(hour_time * HOUR_CONVERSION)

			break

	if _hour_time_goal == 0 or _hour_time_goal > 9:
		($Goal/Hour as Sprite).frame = 1

	($Goal/Hour2 as Sprite).frame =\
			_hour_time_goal % 10 if _hour_time_goal > 0 else 2

	if difficulty > 1:
		($Minute as InstancePlaceholder).replace_by_instance()

		_minute = ($Minute as Area2D)

		# Connect signals in-script, as `InstancePlaceholder`s don't store
		# connections for later.
		# warning-ignore:return_value_discarded
		_minute.connect("released", self, "_on_hand_released")
		# warning-ignore:return_value_discarded
		_minute.connect("grabbed", _hour, "set_pickable", [false])
		# warning-ignore:return_value_discarded
		_hour.connect("grabbed", _minute, "set_pickable", [false])

		var minute_time_max: int =  6 if difficulty == 2 else 60
		_minute_time_goal = randi() % minute_time_max
		while true:
			var minute_time: int = randi() % 6
			if minute_time != _minute_time_goal:
				if difficulty == 3:
					# Continue the loop if the goal value is equal to the
					# margin errors.
					if wrapi(minute_time, 0, minute_time_max) == wrapi(
							_minute_time_goal - 1, 0, minute_time_max) or\
							wrapi(minute_time, 0, minute_time_max) == wrapi(
									_minute_time_goal + 1, 0, minute_time_max):
						continue

				_minute.rotation = deg2rad(minute_time *\
						(MINUTE_LOOSE_CONVERSION if difficulty == 2
						else MINUTE_PRECISE_CONVERSION))

				break

		($Goal/Minute as Sprite).show()

		match difficulty:
			2:
				($Goal/Minute as Sprite).frame = _minute_time_goal % 10
			3:
				($Goal/Minute as Sprite).frame =\
						int(floor(_minute_time_goal / 10.0))

				($Goal/Minute2 as Sprite).frame = _minute_time_goal % 10
				($Goal/Minute2 as Sprite).show()


func _on_hand_released() -> void:
	var hour_time := int(rad2deg(_hour.global_rotation))
	if hour_time < 0:
		hour_time += 360
	hour_time /= HOUR_CONVERSION

	if hour_time != _hour_time_goal:
		_hour.input_pickable = true

		if _difficulty > 1:
			_minute.input_pickable = true

		return

	if _difficulty > 1:
		var minute_time := int(rad2deg(_minute.global_rotation))
		if minute_time < 0:
			minute_time += 360

		var is_minute_correct := false
		match _difficulty:
			2:
				# warning-ignore:integer_division
				is_minute_correct = minute_time / MINUTE_LOOSE_CONVERSION ==\
						_minute_time_goal
			3:
				# Give the player a minute of margin error.
				minute_time /= MINUTE_PRECISE_CONVERSION
				is_minute_correct = minute_time == _minute_time_goal or\
						minute_time - 1 == _minute_time_goal or\
						minute_time + 1 == _minute_time_goal

		if not is_minute_correct:
			_hour.input_pickable = true
			_minute.input_pickable = true

			return

		_minute.input_pickable = false

		_minute.energize()

	($Victory as AudioStreamPlayer).play()

	_hour.input_pickable = false

	_hour.energize()

	emit_signal("ended", true)
