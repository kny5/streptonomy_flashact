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

const Thing = preload("thing/thing.tscn")

var _difficulty := 0

onready var _thing_correct := $ThingSign/ThingCorrect as Area2D


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_difficulty = difficulty

	### Conveyor Handling ###

	if difficulty > 1:
		($CanvasLayer/Conveyors/Conveyor2 as InstancePlaceholder).\
				replace_by_instance()

		if debug_code != 1:
			# Connect signals in-script, as `InstancePlaceholder`s don't store
			# connections for later.
			# warning-ignore:return_value_discarded
			($CanvasLayer/Conveyors/Conveyor2 as TextureRect).connect(
					"end_reached", self, "_on_conveyor_end_reached")

		if difficulty == 3:
			($CanvasLayer/Conveyors/Conveyor3 as InstancePlaceholder).\
					replace_by_instance()

			if debug_code != 1:
				# warning-ignore:return_value_discarded
				($CanvasLayer/Conveyors/Conveyor3 as TextureRect).connect(
						"end_reached", self, "_on_conveyor_end_reached")

	if debug_code == 1:
		($CanvasLayer/Conveyors/Conveyor as TextureRect).disconnect(
				"end_reached", self, "_on_conveyor_end_reached")


	_thing_correct.thing_index =\
			randi() % _thing_correct.get_thing_index_size()


func nanogame_start() -> void:
	_spawn_things()

	($ThingSpawn as Timer).start()


func _spawn_things() -> void:
	var conveyors: Array =\
			($CanvasLayer/Conveyors as VBoxContainer).get_children()
	if _difficulty < 3:
		# Remove placeholders.
		for i in conveyors.size():
			if conveyors[i] is InstancePlaceholder:
				conveyors.resize(i)

				break

	var conveyor_wrong: int = randi() % conveyors.size()
	for i in conveyors:
		var thing := Thing.instance() as Area2D

		var thing_index = randi() % thing.get_thing_index_size()
		if _difficulty > 1:
			# Make one (and only one) conveyor have a thing with the wrong index.
			if i.get_index() != conveyor_wrong:
				thing_index = _thing_correct.thing_index
			else:
				while true:
					thing_index = randi() % thing.get_thing_index_size()
					if thing_index != _thing_correct.thing_index:
						break
		thing.thing_index = thing_index

		i.place_thing(thing)

		# warning-ignore:return_value_discarded
		thing.connect("destroyed", self, "_on_thing_destroyed")


func _fail() -> void:
	for i in ($CanvasLayer/Conveyors as VBoxContainer).get_children():
		if i is InstancePlaceholder:
			break

		i.stop_things()

	($ThingSpawn as Timer).stop()

	($Alarm as AudioStreamPlayer).play()

	($AnimationPlayer as AnimationPlayer).play("fail")

	emit_signal("ended", false)


func _on_conveyor_end_reached(thing: Area2D) -> void:
	if thing.thing_index != _thing_correct.thing_index:
		_fail()


func _on_thing_destroyed(index: int) -> void:
	if index == _thing_correct.thing_index:
		_fail()
