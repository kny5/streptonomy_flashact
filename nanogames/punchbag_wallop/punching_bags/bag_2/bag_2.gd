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


signal broke

const BREAK_TARGET = 8
const AWAY_TARGET = 2

var _punch_count := 0

var _can_be_hit := true


func hit() -> bool:
	if not _can_be_hit:
		return false

	_punch_count += 1

	($AnimationPlayer as AnimationPlayer).stop()

	if _punch_count < BREAK_TARGET:
		if _punch_count % AWAY_TARGET == 0:
			_can_be_hit = false

			($AnimationPlayer as AnimationPlayer).play("flinch_away")
		else:
			($AnimationPlayer as AnimationPlayer).play("flinch")
	else:
		_can_be_hit = false

		($AnimationPlayer as AnimationPlayer).play("break")
		emit_signal("broke")

	return true


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "flinch_away":
		_can_be_hit = true
