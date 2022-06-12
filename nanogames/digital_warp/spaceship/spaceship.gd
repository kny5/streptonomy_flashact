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


signal hit

const SPEED = 4

const MOVE_FADE_LENTGH = 0.1

var _direction_speed := 0

var _has_moved := false
onready var _move := $CollisionShape2D/Move as AudioStreamPlayer2D


func _ready() -> void:
	# warning-ignore:return_value_discarded
	connect("area_entered", self, "_on_area_entered")


func _unhandled_input(_event: InputEvent) -> void:
	# Use `Input` instead of the received event so multiple actions can be
	# detected at once. Not directly placed in `_physics_process()` as to not
	# capture inputs when it shouldn't.
	_direction_speed = int(Input.get_axis("nanogame_right", "nanogame_left"))

	# Toggle particles and fade in/out the movement volume.
	if not _has_moved:
		if _direction_speed != 0:
			_has_moved = true

			($CollisionShape2D/Trail as Particles2D).emitting = true

			var tween := $Tween as Tween
			# warning-ignore:return_value_discarded
			tween.stop_all()
			# warning-ignore:return_value_discarded
			tween.interpolate_method(self, "_update_move_volume",
					db2linear(_move.volume_db), 1, MOVE_FADE_LENTGH)
			# warning-ignore:return_value_discarded
			tween.start()
	elif _direction_speed == 0:
		_has_moved = false

		($CollisionShape2D/Trail as Particles2D).emitting = false

		var tween := $Tween as Tween
		# warning-ignore:return_value_discarded
		tween.stop_all()
		# warning-ignore:return_value_discarded
		tween.interpolate_method(self, "_update_move_volume",
				db2linear(_move.volume_db), 0, MOVE_FADE_LENTGH)
		# warning-ignore:return_value_discarded
		tween.start()

	_direction_speed *= SPEED


func _physics_process(delta: float) -> void:
	if _direction_speed != 0:
		rotation += _direction_speed * delta


func disable_hitbox() -> void:
	($CollisionShape2D as CollisionShape2D).disabled = true


func _update_move_volume(volume: float) -> void:
	_move.volume_db = linear2db(volume)


func _on_area_entered(_area: Area2D) -> void:
	_direction_speed = 0

	# Defer it, to avoid error about flushing queries in physical objects.
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)

	($CollisionShape2D/Trail as Particles2D).emitting = true

	_move.stop()

	($CollisionShape2D/Die as AudioStreamPlayer2D).play()
	($AnimationPlayer as AnimationPlayer).play("die")

	# warning-ignore:return_value_discarded
	($Tween as Tween).stop_all()

	emit_signal("hit")
