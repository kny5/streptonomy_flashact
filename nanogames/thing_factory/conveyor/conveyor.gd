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

extends TextureRect


signal end_reached(thing)

const THING_MOVE_DURATION = 2.5


func place_thing(thing: Area2D) -> void:
	if thing.is_inside_tree():
		push_error("Unable to place thing. It's already inside the tree.")

		return

	add_child(thing)
	thing.position = ($SpawnStart as Position2D).position

	# warning-ignore:return_value_discarded
	($Tween as Tween).interpolate_property(
			thing, "position:x", thing.position.x,
			($SpawnEnd as Position2D).position.x, THING_MOVE_DURATION)
	# warning-ignore:return_value_discarded
	($Tween as Tween).start()


func stop_things() -> void:
	# warning-ignore:return_value_discarded
	($Tween as Tween).stop_all()


func _on_Tween_tween_completed(object: Object, _key: NodePath) -> void:
	if not object.is_destroyed():
		emit_signal("end_reached", object)

	object.queue_free()
