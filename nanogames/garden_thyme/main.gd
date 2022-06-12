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

var _flowers_watered := 0


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	var fence_height: float = ($Background/Fence as TextureRect).rect_size.y
	var playable_area :=\
			Rect2(Vector2(0, fence_height), Vector2(NanogamePlayer.VIEW_SIZE.x,
					NanogamePlayer.VIEW_SIZE.y - fence_height))

	($YSort/WateringCan as Area2D).set_movement_area(playable_area)

	# Avoid any other stuff entering the start area.
	playable_area.size.y -= fence_height

	var flowers: Array = ($Flowers as Node2D).get_children()
	var avoidables: Array = flowers.duplicate()

	if difficulty > 1:
		($YSort/Dog as InstancePlaceholder).replace_by_instance()
		var dog := $YSort/Dog as Area2D

		# Connect signals in-script, as `InstancePlaceholder`s don't store
		# connections for later.
		# warning-ignore:return_value_discarded
		dog.connect("area_entered", self, "_on_Dog_area_entered")

		var dog_extents: Vector2 = dog.get_hitbox_extents()
		var dog_spawn_area: Vector2 = playable_area.size / 1.7
		# Choose a random location for it to spawn.
		dog.position.x = randi() % int(dog_spawn_area.x - dog_extents.x * 2)
		dog.position.y = randi() % int(dog_spawn_area.y - dog_extents.y * 2)
		dog.position +=\
				dog_spawn_area / 2 + playable_area.position + dog_extents

		if difficulty == 3:
			dog.enable_walk(Rect2(dog_spawn_area / 2 + playable_area.position,
					dog_spawn_area))
		else:
			# Place it at the front, so it isn't skipped.
			avoidables.insert(0, dog)

		if debug_code == 1:
			dog.disable_hitbox()

	var flower_extents: Vector2 = flowers[0].get_hitbox_extents()
	var flower_spawn_area: Vector2 = playable_area.size - flower_extents * 2
	var avoidable_distance: Vector2 = flower_extents * 3
	for i in flowers:
		var spawn_position := Vector2()
		while true:
			# Choose a random location for it to spawn.
			spawn_position.x = randi() % int(flower_spawn_area.x)
			spawn_position.y = randi() % int(flower_spawn_area.y)

			spawn_position += playable_area.position + flower_extents

			var is_valid := true
			# Avoid spawning it inside other stuff.
			for j in avoidables:
				if j == i:
					break

				# Check if the rectangles overlap.
				if spawn_position.x + avoidable_distance.x >\
						j.position.x - j.get_hitbox_extents().x and\
						spawn_position.x - avoidable_distance.x <\
						j.position.x + j.get_hitbox_extents().x and\
						spawn_position.y + avoidable_distance.y >\
						j.position.y - j.get_hitbox_extents().y and\
						spawn_position.y - avoidable_distance.y <\
						j.position.y + j.get_hitbox_extents().y:
					is_valid = false

					break

			if is_valid:
				break

		i.position = spawn_position


func _on_Flower_area_entered(_area: Area2D) -> void:
	_flowers_watered += 1
	if _flowers_watered < ($Flowers as Node2D).get_child_count():
		return

	($YSort/WateringCan as Area2D).disappear()

	# Avoid hose from continuing moving after the game ends.
	($YSort/WateringCan as Area2D).set_physics_process(false)

	($Victory as AudioStreamPlayer).play()
	($AnimationPlayer as AnimationPlayer).play("win")

	emit_signal("ended", true)


func _on_Dog_area_entered(_area: Area2D) -> void:
	($YSort/WateringCan as Area2D).disappear()

	# Avoid hose from continuing moving after the game ends.
	($YSort/WateringCan as Area2D).set_physics_process(false)

	($AnimationPlayer as AnimationPlayer).play("lose")

	emit_signal("ended", false)
