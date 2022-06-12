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

extends TextureRect


# Emitted by the respective animations.
# warning-ignore:unused_signal
signal animation_show_finished
# warning-ignore:unused_signal
signal animation_match_finished

var _action := ""


func show_input() -> void:
	match randi() % 5:
		0:
			_action = "nanogame_up"
			texture = load("res://nanogames/input_flow/input/_assets/" +
					"direction_vertical.svg")
		1:
			_action = "nanogame_down"
			texture = load("res://nanogames/input_flow/input/_assets/" +
					"direction_vertical.svg")
			flip_v = true
		2:
			_action = "nanogame_left"
			texture = load("res://nanogames/input_flow/input/_assets/" +
					"direction_horizontal.svg")
		3:
			_action = "nanogame_right"
			texture = load("res://nanogames/input_flow/input/_assets/" +
					"direction_horizontal.svg")
			flip_h = true
		4:
			_action = "nanogame_action"
			texture =\
					load("res://nanogames/input_flow/input/_assets/action.svg")

	($Beat as AudioStreamPlayer2D).play()

	($AnimationPlayer as AnimationPlayer).play("show")


func try_input(event: InputEvent) -> bool:
	if not event.is_action_pressed(_action):
		($AnimationPlayer as AnimationPlayer).play("fail")

		return false

	($Beat as AudioStreamPlayer2D).play()

	($AnimationPlayer as AnimationPlayer).play("match")

	return true
