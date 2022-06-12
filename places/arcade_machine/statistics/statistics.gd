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

extends PanelContainer


# As tab switching will make the visibility notifications fire even if the
# container is hidden, that would remove the highlight too soon, so a manual
# check is necessary.
var _was_highlight_shown := false


func _ready() -> void:
	# warning-ignore:return_value_discarded
	ArcadeManager.connect(
			"best_scores_changed", self, "_update_best_scores")
	_update_best_scores()

	update_played_nanogames()


func _notification(what: int) -> void:
	if what != NOTIFICATION_VISIBILITY_CHANGED:
		return

	if _was_highlight_shown:
		_was_highlight_shown = false

		for i in ($VBoxContainer/Scores/Values as VBoxContainer).\
				get_children() + ($VBoxContainer/Scores/Values2\
				as VBoxContainer).get_children():
			i.self_modulate = ColorN("white")

		($VBoxContainer/Nanogames/Values/BestWinStreak as Label).\
				self_modulate = ColorN("white")
	elif ArcadeManager.is_statistics_highlighted() and is_visible_in_tree():
		_was_highlight_shown = true

		ArcadeManager.clear_statistics_highlight()
		ArcadeManager.save_data()


func update_played_nanogames() -> void:
	($VBoxContainer/Nanogames/Values/WonLost as Label).text =\
			str(ArcadeManager.get_nanogames_won_count())

	($VBoxContainer/Nanogames/Values/WonLost as Label).text +=\
			" / " + str(ArcadeManager.get_nanogames_lost_count())

	($VBoxContainer/Nanogames/Values/Total as Label).text = str(
			ArcadeManager.get_nanogames_won_count() +\
			ArcadeManager.get_nanogames_lost_count())

	($VBoxContainer/Nanogames/Values/BestWinStreak as Label).text =\
			str(ArcadeManager.get_best_win_streak())

	if ArcadeManager.is_best_win_streak_highlighted():
		($VBoxContainer/Nanogames/Values/BestWinStreak as Label).\
				self_modulate = ColorN("yellow")


func _update_best_scores() -> void:
	var best_scores = ArcadeManager.get_best_scores()
	var best_scores_size: int = best_scores.size()
	var best_scores_highlighted: Array =\
			ArcadeManager.get_highlighted_best_scores()
	var best_scores_highlighted_size: int = best_scores_highlighted.size()
	var score_value_nodes: Array =\
			($VBoxContainer/Scores/Values as VBoxContainer).get_children() +\
			($VBoxContainer/Scores/Values2 as VBoxContainer).get_children()
	for i in best_scores_size:
		score_value_nodes[i].text = str(best_scores[i])

		if i <= best_scores_highlighted_size and best_scores_highlighted[i]:
			score_value_nodes[i].self_modulate = ColorN("yellow")

	for i in ArcadeManager.BEST_SCORES_SIZE - best_scores_size:
		score_value_nodes[i + best_scores_size].text = "-"
