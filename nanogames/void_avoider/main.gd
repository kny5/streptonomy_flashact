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


# Emitted by a signal from the "Spaceship" when hit.
# warning-ignore:unused_signal
signal ended(has_won)

const SmallHole = preload("black_holes/small_hole/small_hole.tscn")
const BigHole = preload("black_holes/big_hole/big_hole.tscn")

const SPAWN_RADIUS_DISTANCE = 5
const SPAWN_BIG_HOLE_INTERVAL = 2

const STAR_QUANTITY_DIVISOR = 100

var _interval_current := 0

var _difficulty := 0


func _ready() -> void:
	# Delay the play area update, otherwise the values will be incorrect.
	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", $ResizeDelay as Timer, "start")


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_difficulty = difficulty

	_update_play_area()

	if debug_code == 1:
		($Spaceship as Area2D).disable_hitbox()


func nanogame_start() -> void:
	_spawn_black_hole()

	($BlackHoleSpawn as Timer).start()


func _spawn_black_hole() -> void:
	var black_hole: Area2D
	if _interval_current < SPAWN_BIG_HOLE_INTERVAL:
		black_hole = SmallHole.instance() as Area2D
		# Make the "SmallHole"'s always be above "BigHole"'s for visibility.
		black_hole.z_index = 1

		if _difficulty == 3:
			_interval_current += 1
	else:
		black_hole = BigHole.instance() as Area2D

		_interval_current = 0

	add_child(black_hole)

	var spawn_position := Vector2()
	var viewport_size: Vector2 = get_viewport_rect().size
	var canvas_origin = get_canvas_transform().origin
	var spaceship := $Spaceship as Area2D
	var no_spawn_radius: float = spaceship.get_hitbox_radius() *\
			SPAWN_RADIUS_DISTANCE + black_hole.get_hitbox_radius()
	while true:
		# Choose a random location for it to spawn.
		spawn_position.x = randi() % int(viewport_size.x)
		spawn_position.y = randi() % int(viewport_size.y)
		spawn_position -= canvas_origin

		# Avoid spawning it right where the player is.
		if not Geometry.is_point_in_circle(spawn_position,
				spaceship.position, no_spawn_radius):
			break
	black_hole.position = spawn_position

	black_hole.set_target_position(spaceship.position)


func _update_play_area() -> void:
	var display_area := Rect2()
	display_area.position -= get_canvas_transform().origin
	display_area.size = get_viewport_rect().size

	var stars := $Stars as Particles2D
	stars.amount = int(ceil(display_area.size.x / STAR_QUANTITY_DIVISOR))
	stars.process_material.emission_box_extents.x = display_area.size.x / 2
	stars.process_material.emission_box_extents.y = display_area.size.y / 2

	($Spaceship as Area2D).set_movement_area(display_area)

	($BlackHoleSpawn as Timer).wait_time =\
			NanogamePlayer.VIEW_SIZE.y / display_area.size.x
	match _difficulty:
		1:
			($BlackHoleSpawn as Timer).wait_time *= 2
		2:
			($BlackHoleSpawn as Timer).wait_time *= 1.25
