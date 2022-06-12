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

const COLOR_NEUTRAL = Color(0.1, 0.1, 0.1)
const COLOR_CORRECT = Color(0, 1, 0.5)
const COLOR_WRONG = Color(1, 0.16, 0.16)

var correct_count := 0

var _difficulty := 0


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("nanogame_action") or _difficulty < 1:
		return

	set_process_unhandled_input(false)

	var animation_player := $AnimationPlayer as AnimationPlayer
	var target := $Meter/Indicators/Target as ColorRect
	if ($Meter/Indicators/Pointer as Sprite).position.x >=\
			target.rect_position.x and\
			($Meter/Indicators/Pointer as Sprite).position.x <=\
			target.rect_position.x + target.rect_size.x:
		($Lights as HBoxContainer).get_child(correct_count).get_child(0).\
				color = COLOR_CORRECT

		correct_count += 1
		if correct_count == _difficulty:
			animation_player.play("light_dance")

			emit_signal("ended", true)

			return

		($Effects as AudioStreamPlayer).stream = preload("_assets/correct.wav")
		($Effects as AudioStreamPlayer).play()

		animation_player.stop(false)

		($CorrectPause as Timer).start()
		yield($CorrectPause as Timer, "timeout")

		animation_player.play()
	else:
		($Lights as HBoxContainer).get_child(correct_count).get_child(0).\
				color = COLOR_WRONG

		var pointer_time: float = animation_player.current_animation_position
		animation_player.play("machine_shake")
		yield(animation_player, "animation_finished")

		($Lights as HBoxContainer).get_child(correct_count).get_child(0).\
				color = COLOR_NEUTRAL

		animation_player.play("pointer_move")
		animation_player.seek(pointer_time)

	($PointerCooldown as Timer).start()
	yield($PointerCooldown as Timer, "timeout")

	set_process_unhandled_input(true)


func nanogame_prepare(difficulty: int, _debug_code: int) -> void:
	_difficulty = difficulty

	var target := $Meter/Indicators/Target as ColorRect
	# Shrink the target size according to difficulty level.
	target.rect_size.x /= 1.0 + 0.5 * (difficulty - 1)

	target.rect_position.x = rand_range(0, ($Meter/Indicators as\
			TextureRect).rect_size.x - target.rect_size.x)

	if difficulty > 1:
		($Lights/Border2 as TextureRect).show()

		if difficulty == 3:
			($Lights/Border3 as TextureRect).show()
