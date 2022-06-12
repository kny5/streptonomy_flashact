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

var _floor_spacing := 0
var _is_on_floor := true


func _ready() -> void:
	# warning-ignore:narrowing_conversion
	_floor_spacing = NanogamePlayer.VIEW_SIZE.y - position.y

	# warning-ignore:return_value_discarded
	connect("area_entered", self, "_on_area_entered")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("nanogame_action"):
		return

	set_process_unhandled_input(false)

	($ShiftScaler as Node2D).scale.y *= -1

	($Noises as AudioStreamPlayer2D).play()

	var animation_player := $AnimationPlayer as AnimationPlayer
	animation_player.play("shift")
	animation_player.queue("land")
	animation_player.queue("idle")

	var tween := $Tween as Tween
	# Shift between the floor and ceiling depeding where the player is.
	# warning-ignore:return_value_discarded
	tween.interpolate_property(
			self, "position:y", position.y, _floor_spacing if _is_on_floor
			else int(NanogamePlayer.VIEW_SIZE.y - _floor_spacing),
			animation_player.get_animation("shift").length)
	# warning-ignore:return_value_discarded
	tween.interpolate_callback(
			self, animation_player.get_animation("shift").length,
			"set_process_unhandled_input", true)
	# warning-ignore:return_value_discarded
	tween.start()

	_is_on_floor = not _is_on_floor


func disable_hitbox() -> void:
	($CollisionShape2D as CollisionShape2D).disabled = true


func _on_area_entered(_area: Area2D) -> void:
	($ShiftScaler/Body as Sprite).hide()
	($ShiftScaler/Spark as Sprite).hide()

	($ShiftScaler/Explosion as Particles2D).emitting = true

	# Defer it, to avoid error about flushing queries in physical objects.
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)

	($Noises as AudioStreamPlayer2D).stream = preload("_assets/explosion.wav")
	($Noises as AudioStreamPlayer2D).play()

	($AnimationPlayer as AnimationPlayer).stop()

	emit_signal("hit")
