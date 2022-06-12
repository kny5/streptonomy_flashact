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

extends Control


signal start_status_changed(is_disabled)

signal practice_mode_started(nanogame, difficulty)

const NANOGAME_BUTTON_WIDTH = 480

const NanogameButton = preload("nanogame_button/nanogame_button.tscn")

var _is_start_ready := false
var _start_quantity := 1

var _page_current := 0

var _is_updating_nanogame_buttons := false

var _nanogames_filtered := []
var _nanogames_selected := []


func _ready() -> void:
	### Filter Setup ###

	var filter_popup: PopupMenu = ($HBoxContainer/NanogameSelector/\
			VBoxContainer/TopBar/Filter as MenuButton).get_popup()
	filter_popup.hide_on_checkable_item_selection = false

	var inputs_size: int = Nanogame.Inputs.size()

	# translation-extract:"Inputs"
	filter_popup.add_separator(tr("Inputs"))
	for i in inputs_size:
		filter_popup.add_check_item(Nanogame.get_input_name(i))
		filter_popup.set_item_checked(i + 1, true)

	# translation-extract:"Timers"
	filter_popup.add_separator(tr("Timers"))
	for i in Nanogame.Timers.size():
		filter_popup.add_check_item(Nanogame.get_timer_name(i))
		filter_popup.set_item_checked(i + inputs_size + 2, true)

	# warning-ignore:return_value_discarded
	filter_popup.connect("index_pressed", self, "_on_Filter_index_pressed")


	_nanogames_filtered = ArcadeManager.get_owned_official_nanogames()\
			if not ArcadeManager.community_mode else\
			ArcadeManager.get_community_nanogames()
	_update_filtered_nanogames()

	# warning-ignore:return_value_discarded
	ArcadeManager.connect("community_mode_changed", self,
			"_on_ArcadeManager_community_mode_changed")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if not is_visible_in_tree():
				return

			_update_column_quantity()

			_focus_correct_ui_element()

			emit_signal("start_status_changed", _nanogames_selected.empty() or\
					_nanogames_selected.size() < min(
							ArcadeManager.get_owned_official_nanogames().size()
							if not ArcadeManager.community_mode else
							ArcadeManager.get_community_nanogames().size(),
							_start_quantity))
		NOTIFICATION_TRANSLATION_CHANGED:
			_update_filtered_nanogames()


func clear_selected_highlight() -> void:
	var has_highlight := false
	for i in _nanogames_selected:
		if i.has_meta("highlight"):
			i.remove_meta("highlight")

			has_highlight = true

	if has_highlight:
		ArcadeManager.sort_owned_official_nanogames()
		_update_filtered_nanogames()


func set_start_quantity(value: int) -> void:
	if value <= 0:
		push_error('Start quantity for selected nanogames must be above "0".')

		return

	_start_quantity = value

	_update_nanogame_spots()

	if _nanogames_selected.empty():
		return

	var nanogames_selected_size: int = _nanogames_selected.size()
	_nanogames_selected.clear()

	_update_start_ready_status()

	var nanogames_available := $HBoxContainer/NanogameSelector/VBoxContainer/\
			Panel/NanogamesAvailable as GridContainer
	for i in nanogames_available.get_child_count():
		if nanogames_available.get_child(i).pressed:
			nanogames_available.get_child(i).pressed = false

			nanogames_selected_size -= 1
			if nanogames_selected_size == 0:
				break

	for i in ($HBoxContainer/NanogamesSelected/Panel/NanogamesActive\
			as VBoxContainer).get_children():
		i.queue_free()


func get_nanogames_selected() -> Array:
	return _nanogames_selected.duplicate()


func _add_nanogame_selected(nanogame: Nanogame) -> void:
	_nanogames_selected.append(nanogame)

	var button := TextureButton.new()
	button.expand = true
	button.texture_normal = nanogame.get_icon() if nanogame.get_icon() != null\
			else preload("res://places/arcade_machine/_assets/unknown.svg")
	# translation-extract:"[No Name]"
	button.hint_tooltip = nanogame.get_name(true)\
			if not nanogame.get_name(true).empty() else "[No Name]"

	# Make the button a perfect square.
	button.rect_min_size.y = ($HBoxContainer/NanogamesSelected/Panel/\
			NanogamesActive as VBoxContainer).rect_size.x
	($HBoxContainer/NanogamesSelected/Panel/NanogamesActive\
			as VBoxContainer).add_child(button)

	# warning-ignore:return_value_discarded
	button.connect("pressed", self, "_on_nanogame_selected_button_pressed",
			[button])

	# warning-ignore:return_value_discarded
	button.connect("button_down", button, "set_self_modulate",
			[ColorN("dark_red")])

	# warning-ignore:return_value_discarded
	button.connect("focus_entered", button, "set_self_modulate",
			[ColorN("tomato")])
	# warning-ignore:return_value_discarded
	button.connect("mouse_entered", button, "set_self_modulate",
			[ColorN("tomato")])

	# warning-ignore:return_value_discarded
	button.connect("focus_exited", button, "set_self_modulate",
			[ColorN("white")])
	# warning-ignore:return_value_discarded
	button.connect("mouse_exited", button, "set_self_modulate",
			[ColorN("white")])

	_update_nanogame_spots()
	_update_start_ready_status()


func _focus_correct_ui_element() -> void:
	if GameManager.get_control_type() == GameManager.ControlTypes.KEYBOARD:
		($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Search\
					as LineEdit).grab_focus()
	elif ($HBoxContainer/NanogameSelector/VBoxContainer/Panel/\
			NanogamesAvailable as GridContainer).get_child_count() > 0:
		($HBoxContainer/NanogameSelector/VBoxContainer/Panel/\
				NanogamesAvailable as GridContainer).get_child(0).grab_focus()


func _update_filtered_nanogames() -> void:
	_nanogames_filtered = ArcadeManager.get_owned_official_nanogames()\
			if not ArcadeManager.community_mode else\
			ArcadeManager.get_community_nanogames()

	var has_nanogames := not _nanogames_filtered.empty()
	if has_nanogames:
		var are_inputs_all_checked := true
		for i in Nanogame.Inputs.size():
			if not _is_filter_checked(Nanogame.Inputs, i):
				are_inputs_all_checked = false

		var are_timers_all_checked := true
		for i in Nanogame.Timers.size():
			if not _is_filter_checked(Nanogame.Timers, i):
				are_timers_all_checked = false

		var search_list: Array =\
				($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Search\
						as LineEdit).text.to_lower().split(",", false)
		if not search_list.empty() or not are_inputs_all_checked or\
				not are_timers_all_checked:
			var nanogame_index := 0
			while true:
				var nanogame: Nanogame = _nanogames_filtered[nanogame_index]
				var match_count := 0
				var negative_unmatch_count := 0
				var is_full_match_obligatory := false

				var empty_entries := 0
				if not search_list.empty():
					var name_lower: String = nanogame.get_name(true).to_lower()
					var kickoff_lower: String =\
							nanogame.get_kickoff(true).to_lower()
					var tags_lower: String = nanogame.get_tags(
							ArcadeManager.community_mode or TranslationServer.\
							get_locale() != "en").to_lower()
					var author_lower: String = nanogame.get_author().to_lower()

					for j in search_list:
						var is_filter_negative: bool = j.begins_with("-")
						var is_filter_obligatory: bool = j.begins_with("*")
						if is_filter_negative or is_filter_obligatory:
							j.erase(0, 1)
							if j.empty():
								empty_entries += 1

								continue

						# Find if anything matches.
						if name_lower.find(j) != -1 or\
								kickoff_lower.find(j) != -1 or\
								tags_lower.find(j) != -1 or\
								(ArcadeManager.community_mode and\
										author_lower.find(j) != -1):
							if is_filter_negative:
								match_count = 0

								break

							match_count += 1
						elif is_filter_obligatory:
							is_full_match_obligatory = true

							break
						elif is_filter_negative:
							negative_unmatch_count += 1

				var search_list_size_adjusted: int =\
						search_list.size() - empty_entries

				# Allow for the nanogame to be present if the search terms
				# where all negatives and none matched.
				if match_count == 0 and\
						negative_unmatch_count == search_list_size_adjusted:
					match_count = search_list_size_adjusted

				if ((is_full_match_obligatory and
						match_count == search_list_size_adjusted) or
						(not is_full_match_obligatory and
								(search_list_size_adjusted == 0 or
										match_count > 0))) and\
						_is_filter_checked(Nanogame.Inputs,
								nanogame.get_input()) and _is_filter_checked(
										Nanogame.Timers, nanogame.get_timer()):
					nanogame_index += 1
				else:
					_nanogames_filtered.remove(nanogame_index)

				if nanogame_index > _nanogames_filtered.size() - 1:
					break

	# Defer it, to avoid wrong button handling when typing too fast.
	call_deferred("_update_nanogame_available_buttons")


	### Empty State ###

	($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Search as LineEdit).\
			editable = has_nanogames
	($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Filter\
			as MenuButton).disabled = not has_nanogames
	($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Randomize\
			as Button).disabled = not has_nanogames

	var empty_message := $HBoxContainer/NanogameSelector/VBoxContainer/Panel/\
			EmptyMessage as RichTextLabel
	empty_message.visible = _nanogames_filtered.empty()

	if not empty_message.visible:
		return

	empty_message.rect_min_size.y = 0
	empty_message.clear()

	empty_message.push_align(RichTextLabel.ALIGN_CENTER)

	if has_nanogames:
		# translation-extract:"No nanogames found."
		empty_message.add_text("No nanogames found.")
	else:
		# translation-extract:"No nanogames available."
		empty_message.add_text(tr("No nanogames available."))
		empty_message.newline()

		if ArcadeManager.community_mode and OS.has_feature("pc"):
			# translation-extract:'Place them in the "[url=%s]%s[/url]"
			# directory,\nthen restart the game.'
			# warning-ignore:return_value_discarded
			empty_message.append_bbcode(tr(
					'Place them in the "[url=%s]%s[/url]" directory,' +
					"\nthen restart the game.") % [
							ProjectSettings.globalize_path(ArcadeManager.\
									COMMUNITY_NANOGAMES_PATH_USER),
							ArcadeManager.COMMUNITY_NANOGAMES_PATH_USER.\
							get_base_dir().get_file()])

	empty_message.pop()

	empty_message.rect_min_size.y = get_font("font").get_height() *\
			empty_message.text.split("\n").size() + 1

	# Re-center it manually, as it's not done automatically.
	empty_message.set_anchors_and_margins_preset(PRESET_HCENTER_WIDE)


func _update_nanogame_available_buttons() -> void:
	# Avoid visual glitches when updating at the same frame.
	if _is_updating_nanogame_buttons:
		return

	var had_focus := false

	for i in ($HBoxContainer/NanogameSelector/VBoxContainer/\
			Panel/NanogamesAvailable as GridContainer).get_children():
		if i.has_focus():
			had_focus = true

		i.queue_free()

	_is_updating_nanogame_buttons = true

	# Wait for the buttons to be freed.
	yield(get_tree(), "idle_frame")

	_is_updating_nanogame_buttons = false

	var nanogames_available := $HBoxContainer/NanogameSelector/VBoxContainer/\
			Panel/NanogamesAvailable as GridContainer
	var page_quantity: int = nanogames_available.columns * 2
	var page_max :=\
			int(ceil(_nanogames_filtered.size() / float(page_quantity)))
	if _page_current == -1 or _page_current > page_max - 1:
		_page_current = page_max
		if page_max > 0:
			_page_current -= 1

	($HBoxContainer/NanogameSelector/VBoxContainer/PageButtons/First\
			as Button).disabled = _page_current == 0
	($HBoxContainer/NanogameSelector/VBoxContainer/PageButtons/Previous\
			as Button).disabled = _page_current == 0
	($HBoxContainer/NanogameSelector/VBoxContainer/PageButtons/Next\
			as Button).disabled = _page_current >= page_max - 1
	($HBoxContainer/NanogameSelector/VBoxContainer/PageButtons/Last\
			as Button).disabled = _page_current >= page_max - 1

	($HBoxContainer/NanogameSelector/VBoxContainer/PageButtons/Status\
			as Label).text = str(_page_current + 1 if page_max > 0
			else _page_current) + " / " + str(page_max)

	if _nanogames_filtered.empty():
		if had_focus:
			_focus_correct_ui_element()

		return

	var nanogame_index: int = _page_current * page_quantity
	var nanogame_index_max := int(min(_nanogames_filtered.size(),
			(_page_current + 1) * page_quantity)) - 1
	while true:
		var new_button := NanogameButton.instance() as Button
		var nanogame: Nanogame = _nanogames_filtered[nanogame_index]
		new_button.nanogame = nanogame

		if not ArcadeManager.community_mode:
			new_button.author_visible = false

		if nanogame.has_meta("highlight"):
			new_button.highlight = true

		if _nanogames_selected.has(nanogame):
			new_button.pressed = true
		elif _nanogames_selected.size() ==\
				min(_start_quantity, _nanogames_filtered.size()):
			new_button.disabled = true

		nanogames_available.add_child(new_button)

		# warning-ignore:return_value_discarded
		new_button.connect("pressed", self,
				"_on_nanogame_available_button_pressed", [new_button])
		# warning-ignore:return_value_discarded
		new_button.connect("about_nanogame_pressed",
				($AboutNanogameDialog as PopupDialog), "popup_nanogame",
				[nanogame])

		if nanogame_index == nanogame_index_max:
			break

		nanogame_index += 1

	# Add spacers to keep the buttons aligned in the grid.
	while nanogames_available.get_child_count() <= nanogames_available.columns:
		var space := Control.new()
		space.size_flags_horizontal = SIZE_EXPAND_FILL
		space.size_flags_vertical = SIZE_EXPAND_FILL
		nanogames_available.add_child(space)

	if had_focus:
		_focus_correct_ui_element()


func _update_column_quantity() -> void:
	if not is_visible_in_tree():
		return

	var nanogames_available := $HBoxContainer/NanogameSelector/VBoxContainer/\
			Panel/NanogamesAvailable as GridContainer
	var columns_old: int = nanogames_available.columns

	nanogames_available.columns =\
			int(max(1, floor((nanogames_available.rect_size.x -\
					nanogames_available.get_constant("hseparation") -\
					get_stylebox("grabber", "VScrollBar").\
					get_minimum_size().x) / (NANOGAME_BUTTON_WIDTH +\
							nanogames_available.get_constant("hseparation")))))

	if nanogames_available.columns != columns_old:
		_update_nanogame_available_buttons()


func _update_nanogame_spots() -> void:
	var nanogame_spots :=\
			$HBoxContainer/NanogamesSelected/Panel/NanogameSpots as TextureRect
	nanogame_spots.rect_position.y =\
			_nanogames_selected.size() * nanogame_spots.texture.get_size().x

	var height: float =\
			(min(ArcadeManager.get_owned_official_nanogames().size()
					if not ArcadeManager.community_mode else
					ArcadeManager.get_community_nanogames().size(),
					_start_quantity) - _nanogames_selected.size()) *\
			nanogame_spots.texture.get_size().x
	if height > 0:
		nanogame_spots.rect_size.y = height
		nanogame_spots.show()
	else:
		nanogame_spots.hide()


func _update_start_ready_status() -> void:
	if _nanogames_selected.size() < min(
			ArcadeManager.get_owned_official_nanogames().size()
			if not ArcadeManager.community_mode else
			ArcadeManager.get_community_nanogames().size(), _start_quantity):
		if _is_start_ready:
			# Re-enable the nanogame buttons if they were disabled.
			for i in ($HBoxContainer/NanogameSelector/VBoxContainer/Panel/\
					NanogamesAvailable as GridContainer).get_children():
				if not i is Button:
					break

				i.disabled = false

			_is_start_ready = false
	else:
		for i in ($HBoxContainer/NanogameSelector/VBoxContainer/Panel/\
				NanogamesAvailable as GridContainer).get_children():
			if not i is Button:
				break

			if not i.pressed:
				i.disabled = true

		_is_start_ready = true

	if is_visible_in_tree():
		emit_signal("start_status_changed", not _is_start_ready)


func _is_filter_checked(type: Dictionary, index: int) -> bool:
	var filter_popup: PopupMenu = ($HBoxContainer/NanogameSelector/\
			VBoxContainer/TopBar/Filter as MenuButton).get_popup()
	match type:
		Nanogame.Inputs:
			return filter_popup.is_item_checked(index + 1)
		Nanogame.Timers:
			return filter_popup.is_item_checked(
					index + Nanogame.Inputs.size() + 2)
		_:
			return false


func _on_nanogame_available_button_pressed(nanogame_button: Button) -> void:
	if nanogame_button.pressed:
		_add_nanogame_selected(nanogame_button.nanogame)
	else:
		var nanogame_index: int =\
				_nanogames_selected.find(nanogame_button.nanogame)
		($HBoxContainer/NanogamesSelected/Panel/NanogamesActive\
				as VBoxContainer).get_child(nanogame_index).queue_free()

		_nanogames_selected.remove(nanogame_index)

		_update_nanogame_spots()
		_update_start_ready_status()


func _on_nanogame_selected_button_pressed(button: TextureButton) -> void:
	var nanogame_index: int = button.get_index()
	for i in ($HBoxContainer/NanogameSelector/VBoxContainer/Panel/\
			NanogamesAvailable as GridContainer).get_children():
		if not i is Button:
			break

		if not i.pressed:
			i.disabled = false
		elif i.nanogame == _nanogames_selected[nanogame_index]:
			i.pressed = false

			if _is_start_ready:
				break

	_nanogames_selected.remove(nanogame_index)

	button.queue_free()
	yield(get_tree(), "idle_frame") # Wait for the button to be freed.

	if nanogame_index <= _nanogames_selected.size() - 1:
		($HBoxContainer/NanogamesSelected/Panel/NanogamesActive\
				as VBoxContainer).get_child(nanogame_index).grab_focus()
	elif nanogame_index > 0:
		($HBoxContainer/NanogamesSelected/Panel/NanogamesActive\
				as VBoxContainer).get_child(nanogame_index - 1).grab_focus()
	else:
		_focus_correct_ui_element()

	_update_nanogame_spots()
	_update_start_ready_status()


func _on_Search_text_changed(_new_text: String) -> void:
	_update_filtered_nanogames()


func _on_Filter_index_pressed(index: int) -> void:
	($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Filter\
			as MenuButton).get_popup().set_item_checked(
					index, not ($HBoxContainer/NanogameSelector/VBoxContainer/\
							TopBar/Filter as MenuButton).\
					get_popup().is_item_checked(index))

	_update_filtered_nanogames()


func _on_Randomize_pressed() -> void:
	var nanogames_available_buttons: Array =\
			($HBoxContainer/NanogameSelector/VBoxContainer/Panel/\
					NanogamesAvailable as GridContainer).get_children()

	# Ramdomize all nanogames if all spots are taken.
	if _nanogames_selected.size() == _start_quantity:
		for i in nanogames_available_buttons:
			if not i is Button:
				break

			i.disabled = false
			i.pressed = false

		_nanogames_selected.clear()

		for i in ($HBoxContainer/NanogamesSelected/Panel/NanogamesActive\
				as VBoxContainer).get_children():
			i.queue_free()

	var nanogames_present: Array = _nanogames_filtered.duplicate()
	nanogames_present.shuffle()

	var spots_remaining: int = _start_quantity - _nanogames_selected.size()
	for i in nanogames_present:
		if _nanogames_selected.has(i):
			continue

		_add_nanogame_selected(i)

		for j in nanogames_available_buttons:
			if not j is Button:
				break

			if j.nanogame == i:
				j.pressed = true

		spots_remaining -= 1
		if spots_remaining == 0:
			return

	# Add nanogames that didn't match the filtering if not enough that did were
	# available.
	nanogames_present = ArcadeManager.get_owned_official_nanogames()\
			if not ArcadeManager.community_mode else\
			ArcadeManager.get_community_nanogames()
	nanogames_present.shuffle()

	for i in nanogames_present:
		if _nanogames_selected.has(i) or _nanogames_filtered.has(i):
			continue

		_add_nanogame_selected(i)

		spots_remaining -= 1
		if spots_remaining == 0:
			return


func _on_EmptyMessage_meta_clicked(meta) -> void:
	# warning-ignore:return_value_discarded
	OS.shell_open(meta)


func _on_First_pressed() -> void:
	_page_current = 0

	_update_nanogame_available_buttons()


func _on_Previous_pressed() -> void:
	_page_current -= 1

	_update_nanogame_available_buttons()


func _on_Next_pressed() -> void:
	_page_current += 1

	_update_nanogame_available_buttons()


func _on_Last_pressed() -> void:
	_page_current = -1

	_update_nanogame_available_buttons()


func _on_AboutNanogameDialog_practice_mode_started(
		nanogame: Nanogame, difficulty: int) -> void:
	emit_signal("practice_mode_started", nanogame, difficulty)


func _on_ArcadeManager_community_mode_changed() -> void:
	_nanogames_selected.clear()

	_page_current = 0

	for i in ($HBoxContainer/NanogamesSelected/Panel/NanogamesActive\
			as VBoxContainer).get_children():
		i.queue_free()

	_update_filtered_nanogames()
	_update_nanogame_spots()
