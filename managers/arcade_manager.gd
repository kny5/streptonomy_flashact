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

extends Node


signal community_mode_changed

signal best_scores_changed()

const SAVE_PATH = "user://save.ini"

const OFFICIAL_NANOGAMES_PATH = "res://nanogames/"
const COMMUNITY_NANOGAMES_PATH_RES = "res://community_nanogames/"
const COMMUNITY_NANOGAMES_PATH_USER = "user://community_nanogames/"

const BEST_SCORES_SIZE = 6

var tickets := 0 setget set_tickets

var community_mode := false setget set_community_mode

var _nanogames_official := []
var _nanogames_community := []

var _nanogames_official_owned := []

var _best_scores := []
var _best_scores_highlighted := []

var _nanogames_won_count := 0
var _nanogames_lost_count := 0

var _win_streak_current := 0
var _win_streak_best := 0
var _win_streak_best_highlighted := false


func _ready() -> void:
	for i in BEST_SCORES_SIZE:
		_best_scores_highlighted.append(false)

	var directory := Directory.new()

	### Load Official Nanogames ###

	# warning-ignore:return_value_discarded
	directory.open(OFFICIAL_NANOGAMES_PATH)
	# warning-ignore:return_value_discarded
	directory.list_dir_begin(true, true)
	var file_name: String = directory.get_next()
	var nanogame: Nanogame
	while not file_name.empty():
		nanogame = Nanogame.new()
		# Don't check if an official nanogame is valid, as it wastes time, and
		# if happens to not be, it's better to just crash the game to make
		# itself obvious.
		# warning-ignore:return_value_discarded
		nanogame.load_data(OFFICIAL_NANOGAMES_PATH.plus_file(file_name), true)
		_nanogames_official.append(nanogame)

		file_name = directory.get_next()

	directory.list_dir_end()

	# TODO: Remove this once proper nanogame buying is implemented.
	_nanogames_official_owned = _nanogames_official
	sort_owned_official_nanogames()


	### Load Community Nanogames ###

	if not directory.dir_exists(COMMUNITY_NANOGAMES_PATH_USER):
		var error_code: int = directory.make_dir(COMMUNITY_NANOGAMES_PATH_USER)
		if error_code != OK:
			push_error("Unable to create directory for community " +\
					"nanogames. Error code: " + str(error_code))

			return

	if directory.open(COMMUNITY_NANOGAMES_PATH_USER) == OK:
		# warning-ignore:return_value_discarded
		directory.list_dir_begin(true, true)
		file_name = directory.get_next()
		while not file_name.empty():
			if not ProjectSettings.load_resource_pack(
					COMMUNITY_NANOGAMES_PATH_USER.plus_file(file_name), false):
				push_error(
						'Unable to load resource package "' + file_name + '".')
			else:
				print("Resource pack (nanogame) loaded: " + file_name)

			file_name = directory.get_next()

		directory.list_dir_end()

		if directory.open(COMMUNITY_NANOGAMES_PATH_RES) == OK:
			# warning-ignore:return_value_discarded
			directory.list_dir_begin(true, true)
			file_name = directory.get_next()
			while not file_name.empty():
				nanogame = Nanogame.new()
				# warning-ignore:return_value_discarded
				if nanogame.load_data(COMMUNITY_NANOGAMES_PATH_RES.plus_file(
						file_name)) == OK:
					_nanogames_community.append(nanogame)

				file_name = directory.get_next()

			directory.list_dir_end()

			_sort_community_nanogames()


	### Load Save ###

	var config := ConfigFile.new()
	var error_code: int = config.load(SAVE_PATH)
	if error_code != OK:
		if error_code != ERR_FILE_NOT_FOUND:
			push_error("Unable to load settings data. Error code: " +
					str(error_code))
		else:
			save_data()

		return

	if config.has_section_key("arcade", "tickets"):
		var value = config.get_value("arcade", "tickets", null)
		if value != null and value is int and value >= 0:
			tickets = value

	if config.has_section_key("arcade", "community_mode"):
		var value = config.get_value("arcade", "community_mode", null)
		if value != null and value is bool:
			community_mode = value

	# TODO: Uncomment this once proper nanogame buying is implemented.
#	if config.has_section_key("arcade", "nanogames_owned"):
#		var value = config.get_value("arcade", "nanogames_owned", null)
#		if value != null and value is PoolStringArray:
#			var nanogame_new_quantity := 0
#			if config.has_section_key("arcade", "nanogames_highlighted"):
#				var value_new = config.get_value(
#						"arcade", "nanogames_highlighted", null)
#				if value_new != null and value_new is int and value_new > 0:
#					nanogame_new_quantity = value_new
#
#			for i in value:
#				for j in _nanogames_official:
#					if j.get_name() == i:
#						if _nanogames_official_owned.has(j):
#							break
#
#						_nanogames_official_owned.append(j)
#
#						if nanogame_new_quantity > 0:
#							j.set_meta("highlight", true)
#
#						break
#
#				if nanogame_new_quantity > 0:
#					nanogame_new_quantity -= 1
#
#			sort_owned_official_nanogames()

	if config.has_section_key("statistics", "best_scores"):
		var value = config.get_value("statistics", "best_scores", null)
		if value != null and value is Array:
			if value.size() > BEST_SCORES_SIZE:
				value.resize(BEST_SCORES_SIZE)

			for i in value:
				if i == null or not i is int or i < 1:
					value = null

					break

			if value != null:
				_best_scores = value

	if config.has_section_key("statistics", "best_scores_highlighted"):
		var value = config.get_value("statistics", "best_scores_highlighted", null)
		if value != null and value is Array:
			for i in value:
				if i == null or not i is bool:
					value = null

					break

			if value.size() > _best_scores.size():
				value.resize(_best_scores.size())
			while value.size() < BEST_SCORES_SIZE:
				value.append(false)

			if value != null:
				_best_scores_highlighted = value

	if config.has_section_key("statistics", "nanogames_won"):
		var value = config.get_value("statistics", "nanogames_won", null)
		if value != null and value is int and value >= 0:
			_nanogames_won_count = value

	if config.has_section_key("statistics", "nanogames_lost"):
		var value = config.get_value("statistics", "nanogames_lost", null)
		if value != null and value is int and value >= 0:
			_nanogames_lost_count = value

	if config.has_section_key("statistics", "win_streak_best"):
		var value = config.get_value("statistics", "win_streak_best", null)
		if value != null and value is int and value >= 0:
			_win_streak_best = value

	if config.has_section_key("statistics", "win_streak_best_highlighted"):
		var value = config.get_value(
				"statistics", "win_streak_best_highlighted", null)
		if value != null and value is bool:
			_win_streak_best_highlighted = value


	save_data()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		sort_owned_official_nanogames()
		_sort_community_nanogames()


func own_random_official_nanogame() -> void:
	if _nanogames_official.empty():
		return

	var nanogames: Array = _nanogames_official.duplicate()
	while true:
		var nanogame: Nanogame = nanogames[randi() % nanogames.size()]
		if _nanogames_official_owned.has(nanogame):
			nanogames.erase(nanogame)

			if _nanogames_official.empty():
				return

			continue

		nanogame.set_meta("highlight", true)

		var nanogame_name: String = tr(nanogame.get_name()).to_lower()
		for i in _nanogames_official_owned.size():
			if not _nanogames_official_owned[i].has_meta("highlight") or\
					nanogame_name <\
					tr(_nanogames_official_owned[i].get_name()).to_lower():
				_nanogames_official_owned.insert(i, nanogame)

				return

		_nanogames_official_owned.append(nanogame)

		break


# Sorts the list of official nanogames owned alphabetically, putting the
# highlighted ones at the beginning. Needs to be called manually when removing
# the "highlight" metadata.
func sort_owned_official_nanogames() -> void:
	var nanogames_sorted := []
	for i in _nanogames_official_owned:
		var nanogame: Nanogame = i
		var nanogame_name: String = tr(nanogame.get_name()).to_lower()
		var is_highlighted: bool = nanogame.has_meta("highlight")
		var is_inserted := false
		for j in nanogames_sorted.size():
			var is_index_before: bool = nanogame_name <\
					tr(nanogames_sorted[j].get_name()).to_lower()
			var is_index_highlighted: bool =\
					nanogames_sorted[j].has_meta("highlight")
			if not is_highlighted and not is_index_highlighted and\
					is_index_before or\
					is_highlighted and is_index_highlighted and\
					is_index_before or\
					is_highlighted and not is_index_highlighted:
				nanogames_sorted.insert(j, nanogame)

				is_inserted = true

				break

		if not is_inserted:
			nanogames_sorted.append(nanogame)

	_nanogames_official_owned = nanogames_sorted


func claim_best_score(score: int) -> void:
	if score < 1:
		push_error(
				'Score value must be above "0" to be added to the statistics.')

		return

	var best_scores_size: int = _best_scores.size()
	var is_better_score := false
	for i in best_scores_size:
		if score <= _best_scores[i]:
			continue

		_best_scores.insert(i, score)
		if best_scores_size + 1 > BEST_SCORES_SIZE:
			_best_scores.resize(BEST_SCORES_SIZE)

		is_better_score = true

		_best_scores_highlighted.insert(i, true)
		_best_scores_highlighted.resize(BEST_SCORES_SIZE)

		emit_signal("best_scores_changed")

		break

	if not is_better_score:
		if best_scores_size == BEST_SCORES_SIZE:
			return

		_best_scores.append(score)
		_best_scores_highlighted[-1] = true

		emit_signal("best_scores_changed")


func add_nanogame_win() -> void:
	_nanogames_won_count += 1

	_win_streak_current += 1
	if _win_streak_current > _win_streak_best:
		_win_streak_best = _win_streak_current

		_win_streak_best_highlighted = true


func add_nanogame_loss() -> void:
	_nanogames_lost_count += 1

	_win_streak_current = 0


func break_win_streak() -> void:
	_win_streak_current = 0


func clear_statistics_highlight() -> void:
	for i in _best_scores_highlighted.size():
		_best_scores_highlighted[i] = false

	_win_streak_best_highlighted = false


func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("arcade", "tickets", tickets)
	config.set_value("arcade", "community_mode", community_mode)

	var nanogame_names := PoolStringArray()
	var nanogame_highlight_quantity := 0
	for i in _nanogames_official_owned:
		nanogame_names.append(i.get_name())
		if i.has_meta("highlight"):
			nanogame_highlight_quantity += 1
	config.set_value("arcade", "nanogames_owned", nanogame_names)
	config.set_value(
			"arcade", "nanogames_highlighted", nanogame_highlight_quantity)

	config.set_value("statistics", "best_scores", _best_scores)
	config.set_value(
			"statistics", "best_scores_highlighted", _best_scores_highlighted)
	config.set_value("statistics", "nanogames_won", _nanogames_won_count)
	config.set_value("statistics", "nanogames_lost", _nanogames_lost_count)
	config.set_value("statistics", "win_streak_best", _win_streak_best)
	config.set_value("statistics", "win_streak_best_highlighted",
			_win_streak_best_highlighted)

	var error_code: int = config.save(SAVE_PATH)
	if error_code != OK:
		push_error("Unable to save settings data. Error code: " +
				str(error_code))


func set_tickets(value: int) -> void:
	if value < 0:
		push_error('Unvalid ticket quantity value of "' + str(value) +
				'". It must be a positive number.')

		return

	tickets = value


func set_community_mode(is_enabled: bool) -> void:
	if community_mode == is_enabled:
		return

	community_mode = is_enabled

	emit_signal("community_mode_changed")


func get_official_nanogames() -> Array:
	return _nanogames_official.duplicate()


func get_community_nanogames() -> Array:
	return _nanogames_community.duplicate()


func get_owned_official_nanogames() -> Array:
	return _nanogames_official_owned.duplicate()


func has_highlighted_owned_nanogames() -> bool:
	return not _nanogames_official_owned.empty() and\
			_nanogames_official_owned.front().has_meta("highlight")


func get_best_scores() -> Array:
	return _best_scores.duplicate()


func get_highlighted_best_scores() -> Array:
	return _best_scores_highlighted.duplicate()


func get_nanogames_won_count() -> int:
	return _nanogames_won_count


func get_nanogames_lost_count() -> int:
	return _nanogames_lost_count


func get_best_win_streak() -> int:
	return _win_streak_best


func is_best_win_streak_highlighted() -> bool:
	return _win_streak_best_highlighted


func is_statistics_highlighted() -> bool:
	if _win_streak_best_highlighted:
		return true

	for i in _best_scores_highlighted:
		if i:
			return true

	return false


func _sort_community_nanogames() -> void:
	var nanogames_sorted := []
	for i in _nanogames_community:
		var nanogame: Nanogame = i
		var nanogame_name: String = tr(nanogame.get_name()).to_lower()
		var is_inserted := false
		for j in nanogames_sorted.size():
			if nanogame_name < tr(nanogames_sorted[j].get_name()).to_lower():
				nanogames_sorted.insert(j, nanogame)

				is_inserted = true

				break

		if not is_inserted:
			nanogames_sorted.append(nanogame)

	_nanogames_community = nanogames_sorted
