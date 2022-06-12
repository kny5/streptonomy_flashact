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


signal picked(baggage)

const _COLORS = [
	Color(0.78, 0.21, 0.21),
	Color(0, 0.66, 0.49),
	Color(0.22, 0.54, 0.71),
]

const _MASKS = [
	preload("_assets/masks/mask_1.png"),
	preload("_assets/masks/mask_2.png"),
	preload("_assets/masks/mask_3.png"),
]

const _PATTERNS = [
	preload("_assets/patterns/pattern_1.png"),
	preload("_assets/patterns/pattern_2.png"),
	preload("_assets/patterns/pattern_3.png"),
]

const LOOKS_TYPE_SIZE = 4
const LOOKS_INDEX_MAX = 3


func _input_event(
		_viewport: Object, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
			event.button_mask == BUTTON_LEFT:
		emit_signal("picked", self)

		# Workaround a Godot bug that makes `Light2D` masks stop working when
		# they overlap.
		($Mask as Light2D).range_item_cull_mask = 4
		($Pattern as TextureRect).light_mask = 4
		($ColorblindHelper as ColorRect).light_mask = 4
		($ColorblindHelper/StripSecond as ColorRect).light_mask = 4
		($Decoration as Sprite).light_mask = 4


func generate(looks_correct:=[], imitate:=0) -> void:
	var imitate_order := [false, false, false, false]

	if not looks_correct.empty():
		if looks_correct.size() != LOOKS_TYPE_SIZE:
			push_error('`looks_correct` array must be of size "' +
					str(LOOKS_TYPE_SIZE) + '".')

			return

		if imitate < 0 or imitate > LOOKS_TYPE_SIZE:
			push_error('Invalid `imitate` value of "' + str(imitate) + '".')

			return

		for i in looks_correct:
			if not i is int or i < 0 or i >= LOOKS_INDEX_MAX:
				push_error("`looks_correct` array has non-integer contents " +
						"or their indexes are invalid.")

				return

		if imitate > 0:
			for i in imitate:
				imitate_order[i] = true

			imitate_order.shuffle()
	else:
		looks_correct = [-1, -1, -1, -1]

	($Base as Sprite).frame = _decide_index(looks_correct[0])\
			if not imitate_order[0] else looks_correct[0]
	($Mask as Light2D).texture = _MASKS[($Base as Sprite).frame]

	($Pattern as TextureRect).texture = _PATTERNS[_decide_index(
			looks_correct[1]) if not imitate_order[1] else looks_correct[1]]

	var color: Color = _COLORS[_decide_index(looks_correct[2])\
			if not imitate_order[2] else looks_correct[2]]
	($Pattern as TextureRect).self_modulate = color

	($ColorblindHelper as ColorRect).visible =\
			color == _COLORS[1] or color == _COLORS[2]
	($ColorblindHelper/StripSecond as ColorRect).visible = color == _COLORS[2]

	($Decoration as Sprite).frame = _decide_index(looks_correct[3])\
			if not imitate_order[3] else looks_correct[3]


func get_looks() -> Array:
	return [($Base as Sprite).frame, _PATTERNS.find(($Pattern as TextureRect).\
			texture), _COLORS.find(($Pattern as TextureRect).self_modulate),
			($Decoration as Sprite).frame]


func _decide_index(avoid: int) -> int:
	var value: int
	while true:
		value = randi() % LOOKS_INDEX_MAX
		if value != avoid:
			break

	return value
