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


# Emitted via `call_deferred()`.
# warning-ignore:unused_signal
signal eat()

const SPEED = 100
const ANIMATION_LENGTH = 0.2
const SIZE_MAX = 1000
const ROTATION_MIN = rad2deg(PI * 0.75)
const ROTATION_MAX = rad2deg(PI * 1.25)

var last_fly := false

var _direction_speed := 0

var _fly_caught: KinematicBody2D

onready var _tongue := $Tongue as NinePatchRect


func _unhandled_input(_event: InputEvent) -> void:
	# Use `Input` instead of the received event so multiple actions can be
	# detected at once. Not directly placed in `_physics_process()` as to not
	# capture inputs when it shouldn't.
	_direction_speed = int(Input.get_axis("nanogame_left", "nanogame_right"))

	if Input.is_action_just_pressed("nanogame_action") and\
			not ($Tween as Tween).is_active():
		_launch_tongue()

		# Double speed to facilitate targetting good flies behind bad ones.
		_direction_speed *= 2

	_direction_speed *= SPEED


func _physics_process(delta: float) -> void:
	if _direction_speed == 0:
		return

	_tongue.rect_rotation += _direction_speed * delta
	_tongue.rect_rotation =\
			clamp(_tongue.rect_rotation, ROTATION_MIN, ROTATION_MAX)


func _launch_tongue() -> void:
	var tween := $Tween as Tween
	# warning-ignore:return_value_discarded
	tween.interpolate_property(_tongue, "rect_size:y", _tongue.rect_size.y,
			SIZE_MAX, ANIMATION_LENGTH)
	# warning-ignore:return_value_discarded
	tween.interpolate_callback(self, ANIMATION_LENGTH, "_retreat_tongue")
	# warning-ignore:return_value_discarded
	tween.start()

	($Tongue/Anchor/FlyHitbox/Slurp as AudioStreamPlayer2D).play()

	($FrogAnimation as AnimationPlayer).play("gulp")
	($IndicatorAnimation as AnimationPlayer).play("fade_out")


func _retreat_tongue() -> void:
	var animation_length_adjusted: float = (_tongue.rect_size.y -
			_tongue.rect_min_size.y) / SIZE_MAX * ANIMATION_LENGTH

	var tween := $Tween as Tween
	# warning-ignore:return_value_discarded
	tween.remove_all()

	# warning-ignore:return_value_discarded
	tween.interpolate_property(_tongue, "rect_size:y", _tongue.rect_size.y,
			_tongue.rect_min_size.y, animation_length_adjusted)

	var is_fly_bad := false
	if _fly_caught != null:
		($Tongue/Anchor/FlyHitbox/FlyFollow as RemoteTransform2D).\
				remote_path = _fly_caught.get_path()

		# warning-ignore:return_value_discarded
		tween.interpolate_callback(
				_fly_caught, animation_length_adjusted, "queue_free")

		if _fly_caught.has_meta("bad"):
			is_fly_bad = true

			# warning-ignore:return_value_discarded
			tween.interpolate_callback(self, animation_length_adjusted, "set",
					"_direction_speed", 0)

			# warning-ignore:return_value_discarded
			tween.interpolate_callback(self, animation_length_adjusted,
					"set_physics_process", false)
			# warning-ignore:return_value_discarded
			tween.interpolate_callback(self, animation_length_adjusted,
					"set_process_unhandled_input", false)

			# warning-ignore:return_value_discarded
			tween.interpolate_callback($FrogAnimation as AnimationPlayer,
					animation_length_adjusted, "play", "sicken")
		else:
			if last_fly:
				set_physics_process(false)

				# warning-ignore:return_value_discarded
				tween.interpolate_callback($FrogAnimation as AnimationPlayer,
						animation_length_adjusted, "queue", "lick_lips")

			# Defer it, so the tweens are set first.
			call_deferred("emit_signal", "eat")

	if (not last_fly or _fly_caught == null) and not is_fly_bad:
		# warning-ignore:return_value_discarded
		tween.interpolate_callback($IndicatorAnimation as AnimationPlayer,
				animation_length_adjusted, "play", "fade_in")

	# warning-ignore:return_value_discarded
	tween.interpolate_callback(
			$Tongue/Anchor/FlyHitbox/CollisionShape2D as CollisionShape2D,
			animation_length_adjusted, "set_disabled", false)

	# warning-ignore:return_value_discarded
	tween.start()


func _on_FlyHitbox_body_entered(body: KinematicBody2D) -> void:
	if _fly_caught != null:
		return

	_fly_caught = body
	_fly_caught.stop()

	# Defer it, to avoid error about flushing queries in physical objects.
	($Tongue/Anchor/FlyHitbox/CollisionShape2D as CollisionShape2D).\
			set_deferred("disabled", true)

	_retreat_tongue()

	# Defer it, so it syncs with the disabling of the "FlyHitbox".
	set_deferred("_fly_caught", null)


func _on_FrogAnimation_animation_finished(anim_name: String) -> void:
	if anim_name != "sicken":
		return

	set_physics_process(true)
	set_process_unhandled_input(true)

	($IndicatorAnimation as AnimationPlayer).play("fade_in")
