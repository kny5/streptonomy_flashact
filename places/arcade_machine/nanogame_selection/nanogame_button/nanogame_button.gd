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

extends Button


# Emitted by a signal from the "AboutNanogame" button.
# warning-ignore:unused_signal
signal about_nanogame_pressed

# Extra padding to workaround Godot's current lack of kerning in dynamic fonts.
const ELLIPSIS_PADDING_WORKAROUD = 12

var nanogame: Nanogame setget set_nanogame

var author_visible := true setget set_author_visible

var highlight := false setget set_highlight

var _is_ignoring_theme_notification := false


func _ready() -> void:
	# Delay the ellipsis update, otherwise the check will be incorrect.
	# warning-ignore:return_value_discarded
	connect("resized", $EllipsisUpdateDelay as Timer, "start")

	if nanogame != null:
		($EllipsisUpdateDelay as Timer).start()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			if highlight and not _is_ignoring_theme_notification:
				_update_styleboxes()
		NOTIFICATION_TRANSLATION_CHANGED:
			set_nanogame(nanogame)


func set_nanogame(new_nanogame: Nanogame) -> void:
	if new_nanogame == null or not new_nanogame.has_data():
		return

	nanogame = new_nanogame

	($Contents/Icon as TextureRect).texture = new_nanogame.get_icon()\
			if new_nanogame.get_icon() != null else\
			preload("res://places/arcade_machine/_assets/unknown.svg")

	# translation-extract:"[No Name]"
	($Contents/Information/Main/Text/Name/Label as Label).text =\
			new_nanogame.get_name(true)\
			if not new_nanogame.get_name().empty() else "[No Name]"
	($Contents/Information/Main/Text/Name as HBoxContainer).modulate = ColorN(
			"white" if not new_nanogame.get_name().empty() else "silver")

	# translation-extract:'"%s"'
	# translation-extract:"[No Kickoff]"
	($Contents/Information/Main/Text/Kickoff/Label as Label).text =\
			tr('"%s"') % tr(new_nanogame.get_kickoff(true))\
			if not new_nanogame.get_kickoff().empty() else "[No Kickoff]"
	($Contents/Information/Main/Text/Kickoff as HBoxContainer).modulate =\
			ColorN("white" if not new_nanogame.get_kickoff().empty()
			else "silver")

	# translation-extract:"By %s"
	# translation-extract:"[No Author]"
	($Contents/Information/Extra/Author/Label as Label).text =\
			(tr("By %s") % new_nanogame.get_author())\
			if not new_nanogame.get_author().empty() else "[No Author]"
	($Contents/Information/Extra/Author as HBoxContainer).modulate = ColorN(
			"white" if not new_nanogame.get_author().empty() else "silver")

	if is_inside_tree():
		_update_label_ellipsis()

	### Input Icon ###

	var input_icon: StreamTexture
	match new_nanogame.get_input():
		Nanogame.Inputs.NAVIGATION:
			input_icon = preload("res://places/arcade_machine/_assets/" +\
					"input_types_small/navigation.svg")
		Nanogame.Inputs.ACTION:
			input_icon = preload("res://places/arcade_machine/_assets/" +\
					"input_types_small/action.svg")
		Nanogame.Inputs.NAVIGATION_ACTION:
			input_icon = preload("res://places/arcade_machine/_assets/" +\
					"input_types_small/navigation_action.svg")
		Nanogame.Inputs.DRAG_DROP:
			input_icon = preload("res://places/arcade_machine/_assets/" +\
					"input_types_small/drag_drop.svg")

	($Contents/Information/Extra/Input as TextureRect).texture =\
			input_icon
	# translation-extract:"Input: %s"
	($Contents/Information/Extra/Input as TextureRect).hint_tooltip =\
			tr("Input: %s") %\
			tr(Nanogame.get_input_name(new_nanogame.get_input()))


	### Timer Icons ###

	var timer_icon: StreamTexture
	match new_nanogame.get_timer():
		Nanogame.Timers.OBJECTIVE:
			timer_icon = preload(
					"res://places/arcade_machine/_assets/timer_objective.svg")
		Nanogame.Timers.SURVIVAL:
			timer_icon = preload(
					"res://places/arcade_machine/_assets/timer_survival.svg")

	($Contents/Information/Extra/Timer as TextureRect).texture =\
			timer_icon
	# translation-extract:"Timer: %s"
	($Contents/Information/Extra/Timer as TextureRect).hint_tooltip =\
			tr("Timer: %s") %\
			tr(Nanogame.get_timer_name(new_nanogame.get_timer()))


func set_author_visible(is_visible: bool) -> void:
	author_visible = is_visible

	($Contents/Information/Extra/Author as HBoxContainer).visible = is_visible


func set_highlight(is_highlighted: bool) -> void:
	highlight = is_highlighted
	_update_styleboxes()


func _update_label_ellipsis() -> void:
	var font: Font = get_font("font")

	var name_ellipsis := $Contents/Information/Main/Text/Name/Ellipsis as Label
	var name_label := $Contents/Information/Main/Text/Name/Label as Label
	# translation-extract:"[No Name]"
	name_ellipsis.visible = font.get_string_size((tr(nanogame.get_name(true)))\
			if not nanogame.get_name().empty() else tr("[No Name]")).x +\
			ELLIPSIS_PADDING_WORKAROUD > name_label.rect_size.x +\
			(name_ellipsis.rect_size.x if name_ellipsis.visible else 0.0)
	name_label.hint_tooltip = name_label.text if name_ellipsis.visible else ""

	var kickoff_ellipsis :=\
			$Contents/Information/Main/Text/Kickoff/Ellipsis as Label
	var kickoff_label := $Contents/Information/Main/Text/Kickoff/Label as Label
	# translation-extract:"[No Kickoff]"
	kickoff_ellipsis.visible = font.get_string_size((tr(nanogame.get_kickoff(
			true))) if not nanogame.get_kickoff().empty() else\
			tr("[No Kickoff]")).x + ELLIPSIS_PADDING_WORKAROUD >\
			kickoff_label.rect_size.x + (kickoff_ellipsis.rect_size.x
					if kickoff_ellipsis.visible else 0.0)
	kickoff_label.hint_tooltip =\
			kickoff_label.text if kickoff_ellipsis.visible else ""

	var author_ellipsis := $Contents/Information/Extra/Author/Ellipsis as Label
	var author_label := $Contents/Information/Extra/Author/Label as Label
	# translation-extract:"By %s"
	# translation-extract:"[No Author]"
	author_ellipsis.visible = font.get_string_size(tr("By %s") %\
			nanogame.get_author() if not nanogame.get_author().empty()
			else tr("[No Author]")).x + ELLIPSIS_PADDING_WORKAROUD >\
			author_label.rect_size.x + (author_ellipsis.rect_size.x
			if author_ellipsis.visible else 0.0)
	author_label.hint_tooltip =\
			author_label.text if author_ellipsis.visible else ""


func _update_styleboxes() -> void:
	_is_ignoring_theme_notification = true

	add_stylebox_override(
			"normal", get_stylebox("normal", "ButtonHighlight")
			if highlight else null)
	add_stylebox_override(
			"hover", get_stylebox("hover", "ButtonHighlight")
			if highlight else null)
	add_stylebox_override(
			"pressed", get_stylebox("pressed", "ButtonHighlight")
			if highlight else null)
	add_stylebox_override(
			"disabled", get_stylebox("disabled", "ButtonHighlight")
			if highlight else null)

	_is_ignoring_theme_notification = false
