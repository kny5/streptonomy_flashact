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

extends KinematicBody2D


const SPEED = 100

var _direction_speed := Vector2()
var _movement_area := Rect2()

onready var _body := $Body as Sprite


func _ready() -> void:
	set_physics_process(false)

	_body.scale.x = 1 if randi() % 2 == 0 else -1

	($Body/Wings as AnimatedSprite).play()

	# Prevent movement cycle being identical with other flies.
	# warning-ignore:return_value_discarded
	get_tree().create_timer(randf()).connect(
			"timeout", $MoveSwitch as Timer, "start")


func _physics_process(_delta: float) -> void:
	# warning-ignore:return_value_discarded
	move_and_slide(_direction_speed)
	if get_slide_count() > 0:
		# Bounce flies off each other.
		_direction_speed =\
				_direction_speed.bounce(get_slide_collision(0).normal)

		_body.scale.x = -1 if _direction_speed.x < 0 else 1

		($AnimationPlayer as AnimationPlayer).play(
				"lean_left" if _direction_speed.x < 0 else "lean_right")

	if position.x < _movement_area.position.x:
		position.x = _movement_area.position.x

		_direction_speed.x *= -1
		_body.scale.x = 1

		($AnimationPlayer as AnimationPlayer).play("lean_right")
	elif position.x > _movement_area.end.x:
		position.x = _movement_area.end.x

		_direction_speed.x *= -1
		_body.scale.x = -1

		($AnimationPlayer as AnimationPlayer).play("lean_left")
	if position.y < _movement_area.position.y:
		position.y = _movement_area.position.y

		_direction_speed.y *= -1
	elif position.y > _movement_area.end.y:
		position.y = _movement_area.end.y

		_direction_speed.y *= -1


func stop() -> void:
	set_physics_process(false)

	($MoveSwitch as Timer).stop()

	($AnimationPlayer as AnimationPlayer).stop()


func set_movement_area(area: Rect2) -> void:
	var hitbox_radius: float =\
			($CollisionShape2D as CollisionShape2D).shape.radius
	area.position.x += hitbox_radius
	area.position.y += hitbox_radius
	area.size.x -= hitbox_radius * 2
	area.size.y -= hitbox_radius * 2

	_movement_area = area


func get_hitbox_radius() -> float:
	return ($CollisionShape2D as CollisionShape2D).shape.radius


func _on_MoveSwitch_timeout() -> void:
	set_physics_process(not is_physics_processing())

	if is_physics_processing():
		_direction_speed = Vector2.UP.rotated(TAU * randf()) * SPEED
		_body.scale.x = -1 if _direction_speed.x < 0 else 1

		($AnimationPlayer as AnimationPlayer).play(
				"lean_left" if _direction_speed.x < 0 else "lean_right")
	else:
		($AnimationPlayer as AnimationPlayer).play_backwards(
				"lean_left" if _direction_speed.x < 0 else "lean_right")
