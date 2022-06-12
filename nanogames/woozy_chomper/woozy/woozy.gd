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


signal eat

signal damaged

const SPEED_MOVE = 400
const SPEED_ROTATE = 4

const HEAD_RADIUS = 64

const SEGMENT_GAIN = 2
const SEGMENT_DELAY_BASE = 0.2
const Segment = preload("segment/segment.tscn")

var last_fruit := false
var double_segment_gain := false
var damage_enabled := true

var _direction_speed := 0
var _movement_area := Rect2()

var _is_outside := false
var _is_outside_restricted := false

onready var _segments := $Segments as Node
onready var _tween := $Tween as Tween


func _ready() -> void:
	set_physics_process(false)

	var head_size: Vector2 = Vector2(HEAD_RADIUS, HEAD_RADIUS)
	_movement_area.position -= head_size
	_movement_area.size = NanogamePlayer.VIEW_SIZE + head_size * 2

	for i in ($Segments as Node).get_children():
		i.position = position
		i.show_segment(true)

	# warning-ignore:return_value_discarded
	connect("area_entered", self, "_on_area_entered")


func _unhandled_input(_event: InputEvent) -> void:
	# Use `Input` instead of the received event so multiple actions can be
	# detected at once. Not directly placed in `_physics_process()` as to not
	# capture inputs when it shouldn't.
	_direction_speed = int(Input.get_axis(
			"nanogame_left", "nanogame_right")) * SPEED_ROTATE


func _physics_process(delta: float) -> void:
	if _direction_speed != 0:
		rotation += _direction_speed * delta

	position -= Vector2(0, SPEED_MOVE * delta).rotated(rotation)

	# Teleport to the opposite site (or just kill off, if specified) when the
	# head gets outside.
	if not _is_outside:
		var position_new: Vector2 = position
		if position.x > _movement_area.size.x:
			_is_outside = true
			position_new.x = _movement_area.position.x
		elif position.x < _movement_area.position.x:
			_is_outside = true
			position_new.x = _movement_area.size.x

		if position.y > _movement_area.size.y:
			_is_outside = true
			position_new.y = _movement_area.position.y
		elif position.y < _movement_area.position.y:
			_is_outside = true
			position_new.y = _movement_area.size.y

		if _is_outside:
			if _is_outside_restricted and damage_enabled:
				_die()

				return

			position = position_new
			set_meta("teleport", true)
	elif position.x <= _movement_area.size.x and\
			position.x >= _movement_area.position.x and\
			position.y <= _movement_area.size.y and\
			position.y >= _movement_area.position.y:
		_is_outside = false


func start_movement() -> void:
	set_physics_process(true)


func restrict_outside() -> void:
	_is_outside_restricted = true

	# Adjust the movement area so the head doesn't go outside.
	_movement_area.position.x += HEAD_RADIUS * 2
	_movement_area.position.y += HEAD_RADIUS * 1.5
	_movement_area.size.x -= HEAD_RADIUS * 3
	_movement_area.size.y -= HEAD_RADIUS * 2



func get_segments() -> Array:
	return ($Segments as Node).get_children()


func _die() -> void:
	set_physics_process(false)

	# warning-ignore:return_value_discarded
	_tween.stop_all()

	# Defer it, to avoid error about flushing queries in physical objects.
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)

	($SegmentsUpdate as Timer).stop()
	($EyesAnimate as Timer).stop()

	($AnimationPlayer as AnimationPlayer).play("die")

	emit_signal("damaged")


func _on_area_entered(area: Area2D) -> void:
	var segments := $Segments as Node
	if segments.is_a_parent_of(area):
		if damage_enabled:
			_die()

		return

	area.eat()

	($Saliva as Particles2D).emitting = true

	if last_fruit:
		set_physics_process(false)

		# warning-ignore:return_value_discarded
		_tween.stop_all()

		($Noises as AudioStreamPlayer2D).stop()
		($Noises as AudioStreamPlayer2D).stream =\
				preload("_assets/eat_bloat.wav")

		($SegmentsUpdate as Timer).stop()
		($EyesAnimate as Timer).stop()

		for i in _segments.get_children():
			i.bloat()
	else:
		# Yield it, to avoid errors about flushing queries in physical objects.
		yield(get_tree(), "idle_frame")
		for i in SEGMENT_GAIN * (2 if double_segment_gain else 1):
			var segment_new: Area2D = Segment.instance()
			segments.add_child(segment_new)

			segment_new.position =\
					segments.get_child(segments.get_child_count() - 2).position
			segment_new.show_segment()

	($AnimationPlayer as AnimationPlayer).stop()
	($AnimationPlayer as AnimationPlayer).play("eat")
	($AnimationPlayer as AnimationPlayer).queue("idle")

	emit_signal("eat")


func _on_SegmentsUpdate_timeout() -> void:
	var segment_previous: Area2D = self
	for i in _segments.get_children():
		if not segment_previous.has_meta("teleport"):
			# warning-ignore:return_value_discarded
			_tween.interpolate_property(i, "position", i.position,
					segment_previous.position, SEGMENT_DELAY_BASE)
		else:
			segment_previous.remove_meta("teleport")

			# Defer it, so the following segments are teleported properly one
			# at each update.
			i.set_deferred("position", segment_previous.position)
			i.call_deferred("set_meta", "teleport", true)

		segment_previous = i

	# warning-ignore:return_value_discarded
	_tween.start()


func _on_EyesAnimate_timeout() -> void:
	# warning-ignore:return_value_discarded
	_tween.interpolate_property($Head/EyeLeft as Sprite, "rotation",
			($Head/EyeLeft as Sprite).rotation, rand_range(-PI / 2, PI / 2),
			0.5)
	# warning-ignore:return_value_discarded
	_tween.interpolate_property($Head/EyeRight as Sprite, "rotation",
			($Head/EyeRight as Sprite).rotation, rand_range(-PI / 2, PI / 2),
			0.5)
	# warning-ignore:return_value_discarded
	_tween.start()
