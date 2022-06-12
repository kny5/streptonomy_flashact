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

extends TabDialog


signal practice_mode_started(nanogame, difficulty)

var _nanogame: Nanogame

var _about := RichTextLabel.new()
var _thirdparty := RichTextLabel.new()

var _practice_button: MenuButton


func _ready() -> void:
	### About ###

	_about.bbcode_enabled = true
	_about.focus_mode = Control.FOCUS_ALL

	# translation-extract:"About"
	add_tab("About", _about)

	# warning-ignore:return_value_discarded
	_about.connect("meta_clicked", self, "_on_rich_text_label_meta_clicked")


	### Practice Mode ###

	var practice_container := VBoxContainer.new()

	var practice_label := Label.new()
	# translation-extract:"The practice mode lets your sharpen your skills
	# on a particular nanogame, without needing to worry about
	# energy points.\n\nBe aware that tickets will not be given,
	# and statistics will not be updated."
	practice_label.text = "The practice mode lets your sharpen your skills " +\
			"on a particular nanogame, without needing to worry about " +\
			"energy points.\n\nBe aware that tickets will not be given, " +\
			"and statistics will not be updated."
	practice_label.autowrap = true
	practice_container.add_child(practice_label)
	practice_label.size_flags_vertical = SIZE_EXPAND_FILL

	_practice_button = MenuButton.new()
	_practice_button.flat = false
	# translation-extract:"Choose Start Difficulty"
	_practice_button.text = "Choose Start Difficulty"
	_practice_button.focus_mode = Control.FOCUS_ALL
	_practice_button.rect_min_size.x = 250
	_practice_button.size_flags_horizontal = SIZE_SHRINK_CENTER
	_practice_button.add_font_override(
			"font", preload("res://fonts/font_bold.tres"))
	practice_container.add_child(_practice_button)

	_update_practice_menu()

	# translation-extract:"Practice Mode"
	add_tab("Practice Mode", practice_container)

	# warning-ignore:return_value_discarded
	_practice_button.get_popup().connect(
			"visibility_changed", self, "_on_practice_menu_visibility_changed")
	# warning-ignore:return_value_discarded
	_practice_button.get_popup().connect(
			"id_pressed", self, "_on_practice_menu_id_pressed")


	### Third-party ###

	_thirdparty.bbcode_enabled = true
	_thirdparty.focus_mode = Control.FOCUS_ALL

	# translation-extract:"Third-party"
	add_tab("Third-party", _thirdparty)

	# warning-ignore:return_value_discarded
	_thirdparty.connect(
			"meta_clicked", self, "_on_rich_text_label_meta_clicked")


	# warning-ignore:return_value_discarded
	connect("tab_changed", self, "_on_tab_changed")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_POPUP_HIDE:
			_nanogame = null

			reset()
		NOTIFICATION_TRANSLATION_CHANGED:
			_update_practice_menu()

			if _nanogame != null:
				popup_nanogame(_nanogame)
		NOTIFICATION_THEME_CHANGED:
			if _practice_button == null:
				yield(self, "ready")

			_practice_button.add_stylebox_override(
					"normal", get_stylebox("normal", "ButtonPositive"))
			_practice_button.add_stylebox_override(
					"hover", get_stylebox("hover", "ButtonPositive"))
			_practice_button.add_stylebox_override(
					"pressed", get_stylebox("pressed", "ButtonPositive"))

			var practice_menu: PopupMenu = _practice_button.get_popup()
			practice_menu.add_stylebox_override(
					"panel", get_stylebox("panel", "PopupMenuPositive"))
			practice_menu.add_stylebox_override(
					"hover", get_stylebox("hover", "PopupMenuPositive"))


func popup_nanogame(nanogame: Nanogame) -> void:
	if not nanogame.has_data():
		push_error("Can't show information about a nanogame without data.")

		return

	_nanogame = nanogame

	### About ##

	_about.scroll_to_line(0)
	_about.clear()

	_about.push_align(RichTextLabel.ALIGN_CENTER)

	_about.push_color(
			ColorN("white" if not nanogame.get_name().empty() else "silver"))
	_about.push_bold()
	# translation-extract:"[No Name]"
	_about.add_text(nanogame.get_name(true) if not nanogame.get_name().empty()
			else tr("[No Name]"))
	_about.pop()
	_about.pop()
	_about.newline()

	_about.push_color(ColorN(
			"white" if not nanogame.get_kickoff().empty() else "silver"))
	_about.push_italics()
	# translation-extract:'"%s"'
	# translation-extract:"[No Kickoff]"
	_about.add_text(tr('"%s"') % nanogame.get_kickoff(true)
			if not nanogame.get_kickoff().empty() else tr("[No Kickoff]"))
	_about.pop()
	_about.pop()
	_about.newline()

	_about.push_color(
			ColorN("white" if not nanogame.get_author().empty() else "silver"))
	# translation-extract:"By %s"
	# translation-extract:"[No Author]"
	_about.add_text(tr("By %s") % nanogame.get_author()
			if not nanogame.get_author().empty() else tr("[No Author]"))
	_about.pop()
	_about.newline()

	if not nanogame.get_source().empty():
		_about.push_meta(nanogame.get_source())
		# translation-extract:"Source"
		_about.add_text(tr("Source"))
		_about.pop()
	else:
		_about.push_color(ColorN("silver"))
		# translation-extract:"[No Source]"
		_about.add_text(tr("[No Source]"))
		_about.pop()

	_about.pop()
	_about.newline()

	_about.newline()

	_about.push_color(ColorN("white"
			if not nanogame.get_description().empty() else "silver"))
	# translation-extract:"[No Description]"
	_about.add_text(nanogame.get_description(true)
			if not nanogame.get_description().empty()
			else tr("[No Description]"))
	_about.pop()
	_about.newline()

	_about.newline()

	# translation-extract:"[b]Input:[/b] %s"
	# warning-ignore:return_value_discarded
	_about.append_bbcode(tr("[b]Input:[/b] %s") %
			tr(Nanogame.get_input_name(nanogame.get_input())))
	_about.newline()

	# translation-extract:"[b]Timer:[/b] %s"
	# warning-ignore:return_value_discarded
	_about.append_bbcode(tr("[b]Timer:[/b] %s") %
			tr(Nanogame.get_timer_name(nanogame.get_timer())))
	_about.newline()

	# translation-extract:"[b]Tags:[/b] %s"
	# translation-extract:"[None]"
	# warning-ignore:return_value_discarded
	_about.append_bbcode(tr("[b]Tags:[/b] %s") %
			(nanogame.get_tags(ArcadeManager.community_mode or
							TranslationServer.get_locale() != "en")
					if not nanogame.get_tags().empty() else
					("[color=silver]" + tr("[None]") + "[/color]")))
	_about.newline()

	# translation-extract:"[b]Code License:[/b] %s"
	# warning-ignore:return_value_discarded
	_about.append_bbcode(tr("[b]Code License:[/b] %s") % ("[url=%s]%s[/url]" %
			[Nanogame.get_license_link(nanogame.get_license_code()),
					Nanogame.get_license_name(nanogame.get_license_code())]
			if not Nanogame.get_license_link(
					nanogame.get_license_code()).empty() else
			Nanogame.get_license_name(nanogame.get_license_code())))
	_about.newline()

	# translation-extract:"[b]Assets License:[/b] %s"
	# warning-ignore:return_value_discarded
	_about.append_bbcode(
			tr("[b]Assets License:[/b] %s") % ("[url=%s]%s[/url]" %
			[Nanogame.get_license_link(nanogame.get_license_assets()),
					Nanogame.get_license_name(nanogame.get_license_assets())]
			if not Nanogame.get_license_link(
					nanogame.get_license_assets()).empty() else
			Nanogame.get_license_name(nanogame.get_license_assets())))


	### Third-party ###

	_thirdparty.scroll_to_line(0)
	_thirdparty.clear()

	var index_max: int
	var index_current: = 0
	if not nanogame.get_thirdparty().empty():
		# TODO: Implement checking of right-to-left languages.
		# Use a non-breaking space, so long names are still kept besides the
		# bullet point.
		var bullet_point := "•" + char(0032) + "%s"
		index_max = nanogame.get_thirdparty().size() - 1
		for i in nanogame.get_thirdparty():
			_thirdparty.push_bold()
			# translation-extract:"[No Name]"
			_thirdparty.add_text(bullet_point %
					i["name"] if not i["name"].empty() else tr("[No Name]"))
			_thirdparty.pop()
			_thirdparty.newline()

			_thirdparty.push_indent(2)

			# translation-extract:"By %s"
			# translation-extract:"[No Author]"
			_thirdparty.add_text(tr("By %s") % i["author"]
					if not i["author"].empty() else tr("[No Author]"))
			_thirdparty.newline()

			if not Nanogame.get_license_link(i["license"]).empty():
				_thirdparty.push_meta(Nanogame.get_license_link(i["license"]))
				_thirdparty.add_text(Nanogame.get_license_name(i["license"]))
				_thirdparty.pop()
			else:
				_thirdparty.add_text(Nanogame.get_license_name(i["license"]))
			_thirdparty.newline()

			if not i["source"].empty():
				_thirdparty.push_meta(i["source"])
				# translation-extract:"Source"
				_thirdparty.add_text(tr("Source"))
				_thirdparty.pop()
			else:
				# translation-extract:"[No Source]"
				_thirdparty.add_text(tr("[No Source]"))

			_thirdparty.pop()

			if index_current < index_max:
				_thirdparty.newline()
				_thirdparty.newline()

				index_current += 1
	else:
		_thirdparty.push_align(RichTextLabel.ALIGN_CENTER)
		# translation-extract:"No third-party resources used."
		_thirdparty.add_text(tr("No third-party resources used."))
		_thirdparty.pop()

	popup_centered()


func _update_practice_menu() -> void:
	# Wait for the button to be ready if called right at the start.
	if _practice_button == null:
		yield(get_tree(), "idle_frame")

	var practice_menu: PopupMenu = _practice_button.get_popup()
	practice_menu.clear()

	for i in NanogamePlayer.DIFFICULTY_MAX:
		# translation-extract:"Difficulty %d"
		practice_menu.add_item(
				tr("Difficulty %d") % (i + NanogamePlayer.DIFFICULTY_MIN))
		practice_menu.set_item_id(i, i + NanogamePlayer.DIFFICULTY_MIN)


func _on_tab_changed(tab: int) -> void:
	match tab:
		0:
			_about.grab_focus()
		1: # "Practice Mode".
			_practice_button.grab_focus()
		2:
			_thirdparty.grab_focus()


func _on_rich_text_label_meta_clicked(meta: String) -> void:
	# warning-ignore:return_value_discarded
	OS.shell_open(meta)


func _on_practice_menu_visibility_changed() -> void:
	var practice_menu: PopupMenu = _practice_button.get_popup()
	if practice_menu.visible:
		# Adjust the position so it's spawn above the button, to avoid it
		# hugging the bottom of the screen.
		practice_menu.rect_position.y -=\
				_practice_button.rect_size.y + practice_menu.rect_size.y


func _on_practice_menu_id_pressed(id: int) -> void:
	emit_signal("practice_mode_started", _nanogame, id)

	# Hide later, to avoid nulling the last reference of the nanogame.
	hide()
