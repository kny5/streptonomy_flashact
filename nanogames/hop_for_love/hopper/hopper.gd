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


signal jumped
signal landed(area)

const JUMP_DISTANCE_MIN = 150
const JUMP_DISTANCE_MAX = 400

const JUMP_ANIMATION_LENGTH = 0.6

const TARGET_ARC_START_MIN = -1.5
const TARGET_ARC_START_MAX = -2.47
const TARGET_ARC_END_MIN = -0.3
const TARGET_ARC_END_MAX = -0.12

const TARGET_ANIMATION_LENGTH_HALF = 0.7
const TARGET_COLOR = Color(0.23, 0.23, 0.23)

var position_limit := 0

var is_never_splashing := false

var goal_area: Area2D

var _target_arc_start_current := 0.0
var _target_arc_end_current := 0.0

onready var _target := $Target as CollisionShape2D


func _ready() -> void:
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("nanogame_action"):
		return

	### Jump ###

	set_process(false)
	set_process_unhandled_input(false)

	update()

	_target.disabled = true
	_target.hide()

	var tween := $Tween as Tween
	tween.repeat = false
	# warning-ignore:return_value_discarded
	tween.remove_all()

	var distance: float = min(_target.position.x, position_limit - position.x)
	var animation_length: float =\
			JUMP_ANIMATION_LENGTH / JUMP_DISTANCE_MAX * distance

	# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "position:x", position.x,
			position.x + distance, animation_length)
	# warning-ignore:return_value_discarded
	tween.interpolate_property(
			self, "position:y", position.y, position.y - distance / 2,
			animation_length / 2, Tween.TRANS_CIRC, Tween.EASE_OUT)
	# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "position:y", position.y - distance / 2,
			position.y, animation_length / 2, Tween.TRANS_CIRC, Tween.EASE_IN,
			animation_length / 2)

	var land_area: Area2D
	if not get_overlapping_areas().empty():
		land_area = get_overlapping_areas().front()
	# warning-ignore:return_value_discarded
	tween.interpolate_callback(self, animation_length, "_land", land_area)

	# warning-ignore:return_value_discarded
	tween.start()

	($Noises as AudioStreamPlayer2D).play()

	($AnimationPlayer as AnimationPlayer).playback_speed =\
			JUMP_ANIMATION_LENGTH / animation_length
	($AnimationPlayer as AnimationPlayer).play("jump")

	emit_signal("jumped")


func _process(_delta: float) -> void:
	update()


func _draw() -> void:
	if not is_processing():
		return

	draw_arc(_target.position / 2, _target.position.x / 2,
			_target_arc_start_current, _target_arc_end_current, 16,
			TARGET_COLOR, 2, true)


func activate_target() -> void:
	if not is_processing() and ($Tween as Tween).tell() == 0:
		set_process(true)

		_target.show()
		_move_target()


func _move_target() -> void:
	var tween := $Tween as Tween
	tween.repeat = true
	# warning-ignore:return_value_discarded
	tween.remove_all()

	# warning-ignore:return_value_discarded
	tween.interpolate_property(_target, "position:x", JUMP_DISTANCE_MIN,
			JUMP_DISTANCE_MAX, TARGET_ANIMATION_LENGTH_HALF)
	# warning-ignore:return_value_discarded
	tween.interpolate_property(
			_target, "position:x", JUMP_DISTANCE_MAX, JUMP_DISTANCE_MIN,
			TARGET_ANIMATION_LENGTH_HALF, Tween.TRANS_LINEAR,
			Tween.EASE_IN_OUT, TARGET_ANIMATION_LENGTH_HALF)

	### Target Arc Animation ###

	# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "_target_arc_start_current",
			TARGET_ARC_START_MIN, TARGET_ARC_START_MAX,
			TARGET_ANIMATION_LENGTH_HALF)
	# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "_target_arc_start_current",
			TARGET_ARC_START_MAX, TARGET_ARC_START_MIN,
			TARGET_ANIMATION_LENGTH_HALF, Tween.TRANS_LINEAR,
			Tween.EASE_IN_OUT, TARGET_ANIMATION_LENGTH_HALF)
	# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "_target_arc_end_current",
			TARGET_ARC_END_MIN, TARGET_ARC_END_MAX,
			TARGET_ANIMATION_LENGTH_HALF)
	# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "_target_arc_end_current",
			TARGET_ARC_END_MAX, TARGET_ARC_END_MIN,
			TARGET_ANIMATION_LENGTH_HALF, Tween.TRANS_LINEAR,
			Tween.EASE_IN_OUT, TARGET_ANIMATION_LENGTH_HALF)


	# warning-ignore:return_value_discarded
	tween.start()


func _land(area:Area2D=null):
	($AnimationPlayer as AnimationPlayer).playback_speed = 1

	if area != null or is_never_splashing:
		if goal_area != null and area == goal_area:
			($AnimationPlayer as AnimationPlayer).play("land_blush")
		else:
			# Avoid showing the target's past position in the first frame.
			_target.position.x = JUMP_DISTANCE_MIN

			set_process(true)
			set_process_unhandled_input(true)

			_target.disabled = false
			_target.show()

			_move_target()

			($AnimationPlayer as AnimationPlayer).play("land")
	else:
		($AnimationPlayer as AnimationPlayer).play("splash")

	emit_signal("landed", area)
