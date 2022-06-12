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


signal ended(has_won)

const FLY_GOAL = 4
const FLY_BAD_QUANTITY = 2

const Fly = preload("res://nanogames/buzzing_lunch/flies/fly/fly.tscn")
const FlyPoison = preload(\
		"res://nanogames/buzzing_lunch/flies/fly_poison/fly_poison.tscn")

var _flies_eaten := 0


func nanogame_prepare(difficulty: int, _debug_code: int) -> void:
	var flies := []
	for i in FLY_GOAL:
		flies.append(Fly.instance())

	match difficulty:
		2:
			for i in FLY_BAD_QUANTITY:
				flies.append(FlyPoison.instance())
		3:
			for i in FLY_BAD_QUANTITY * 2:
				flies.append(FlyPoison.instance())

	var spawn_area :=\
			Vector2(NanogamePlayer.VIEW_SIZE.x, NanogamePlayer.VIEW_SIZE.y / 2)

	# Use a single radius value, as both fly types have it at the same size.
	var fly_radius: float = flies[0].get_hitbox_radius()
	var spawn_area_adjusted := spawn_area - Vector2(fly_radius, fly_radius) * 2
	for i in flies:
		var spawn_position := Vector2()
		while true:
			# Choose a random location for it to spawn.
			spawn_position.x =\
					fly_radius + randi() % int(spawn_area_adjusted.x)
			spawn_position.y =\
					fly_radius + randi() % int(spawn_area_adjusted.y)

			var is_valid := true
			# Avoid spawning it inside other flies.
			for j in flies:
				if j == i:
					break

				if spawn_position.distance_to(j.position) <= fly_radius * 2:
					is_valid = false

					break

			if is_valid:
				break

		add_child(i)
		i.set_movement_area(Rect2(Vector2(), spawn_area))
		i.position = spawn_position


func _on_Frog_eat() -> void:
	_flies_eaten += 1

	if _flies_eaten == FLY_GOAL:
		emit_signal("ended", true)
	elif _flies_eaten == FLY_GOAL - 1:
		($Frog as Node2D).last_fly = true
