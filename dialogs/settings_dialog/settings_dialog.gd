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


const FONT_BOLD = preload("res://fonts/font_bold.tres")

var _language_button := OptionButton.new()

var _inputs_section := VBoxContainer.new()
var _control_type_button := OptionButton.new()
var _input_buttons := ButtonGroup.new()
var _input_dialog :=\
		preload("res://dialogs/simple_dialog/simple_dialog.tscn").instance()\
		as SimpleDialog

var _switch_touch_controls := CheckBox.new()

var _volume_buttons := []


func _ready() -> void:
	var is_not_mobile: bool = not OS.has_feature("mobile")

	### General ###

	var general := VBoxContainer.new()

	var language_container := HBoxContainer.new()
	general.add_child(language_container)

	var language_label := Label.new()
	# translation-extract:"Language:"
	language_label.text = "Language:"
	language_label.valign = Label.VALIGN_CENTER
	language_label.clip_text = true
	language_label.size_flags_horizontal = SIZE_EXPAND_FILL
	language_label.size_flags_vertical = SIZE_FILL
	language_label.add_font_override("font", FONT_BOLD)
	language_container.add_child(language_label)

	_language_button.clip_text = true
	_language_button.rect_min_size.x = 400
	# translation-extract:"System Default"
	_language_button.add_item("System Default")
	_language_button.add_separator()

	var file := File.new()
	# warning-ignore:return_value_discarded
	file.open("res://dialogs/settings_dialog/language_names.json", File.READ)
	var language_names: Dictionary = parse_json(file.get_as_text())
	file.close()

	var is_locale_system_default := GameManager.is_locale_system_default()
	var selected_id := 2 # Skip the "System Default" and the separator IDs.
	for i in ProjectSettings.get_setting("locale/locale_filter")[1]:
		_language_button.add_item(language_names[i])

		if is_locale_system_default:
			continue

		if i == TranslationServer.get_locale():
			_language_button.selected = selected_id
		else:
			selected_id += 1
	if is_locale_system_default:
		_language_button.selected = 0

	language_container.add_child(_language_button)
	# warning-ignore:return_value_discarded
	_language_button.connect(
			"item_selected", self, "_on_language_button_item_selected")

	if is_not_mobile:
		var fullscreen_window := CheckBox.new()
		# translation-extract:"Fullscreen Window"
		fullscreen_window.text = "Fullscreen Window"
		fullscreen_window.clip_text = true
		fullscreen_window.pressed = OS.window_fullscreen
		general.add_child(fullscreen_window)
		# warning-ignore:return_value_discarded
		fullscreen_window.connect(
				"toggled", self, "_on_fullscreen_window_toggled")

	var pause_focus_lost := CheckBox.new()
	# translation-extract:"Pause When the Game Loses Focus"
	pause_focus_lost.text = "Pause When the Game Loses Focus"
	pause_focus_lost.clip_text = true
	pause_focus_lost.pressed =\
			ProjectSettings.get_setting("game_settings/pause_focus_lost")
	general.add_child(pause_focus_lost)
	# warning-ignore:return_value_discarded
	pause_focus_lost.connect(
			"toggled", self, "_on_pause_focus_lost_toggled")

	if is_not_mobile:
		var mute_focus_lost := CheckBox.new()
		# translation-extract:"Mute When the Game Loses Focus"
		mute_focus_lost.text = "Mute When the Game Loses Focus"
		mute_focus_lost.clip_text = true
		mute_focus_lost.pressed =\
				ProjectSettings.get_setting("game_settings/mute_focus_lost")
		general.add_child(mute_focus_lost)
		# warning-ignore:return_value_discarded
		mute_focus_lost.connect("toggled", self, "_on_mute_focus_lost_toggled")

	var show_community_warning := CheckBox.new()
	# translation-extract:"Show Warning About Community Nanogames"
	show_community_warning.text = "Show Warning About Community Nanogames"
	show_community_warning.clip_text = true
	show_community_warning.pressed =\
			ProjectSettings.get_setting("game_settings/show_community_warning")
	general.add_child(show_community_warning)
	# warning-ignore:return_value_discarded
	show_community_warning.connect(
			"toggled", self, "_on_show_community_warning_toggled")

	# translation-extract:"General"
	add_tab("General", general)


	### Controls ###

	var controls := VBoxContainer.new()

	var control_type_container := HBoxContainer.new()
	controls.add_child(control_type_container)

	var control_type_label := Label.new()
	# translation-extract:"Main Control:"
	control_type_label.text = "Main Control:"
	control_type_label.clip_text = true
	control_type_label.size_flags_horizontal = SIZE_EXPAND_FILL
	control_type_label.add_font_override("font", FONT_BOLD)
	control_type_container.add_child(control_type_label)

	_control_type_button.size_flags_horizontal = SIZE_EXPAND_FILL

	# translation-extract:"Automatic"
	_control_type_button.add_item("Automatic")
	_control_type_button.add_separator()
	# translation-extract:"Touchscreen"
	_control_type_button.add_item("Touchscreen")
	# translation-extract:"Joypad"
	_control_type_button.add_item("Joypad")
	# translation-extract:"Joypad and Touchscreen"
	_control_type_button.add_item("Joypad and Touchscreen")
	if is_not_mobile:
		# translation-extract:"Keyboard and Mouse"
		_control_type_button.add_item("Keyboard and Mouse")

	var main_control: int = GameManager.main_control
	# Skip the separator ID if necessary.
	_control_type_button.selected =\
			main_control if main_control == 0 else main_control + 1

	control_type_container.add_child(_control_type_button)
	# warning-ignore:return_value_discarded
	_control_type_button.connect(
			"item_selected", self, "_on_control_type_button_item_selected")

	var control_separator := HSeparator.new()
	controls.add_child(control_separator)

	# translation-extract:"Switch Touch Controls Positions"
	_switch_touch_controls.text = "Switch Touch Controls Positions"
	_switch_touch_controls.clip_text = true
	_switch_touch_controls.pressed = ProjectSettings.get_setting(
			"game_settings/switch_touch_controls")
	_switch_touch_controls.hide()
	controls.add_child(_switch_touch_controls)
	# warning-ignore:return_value_discarded
	_switch_touch_controls.connect(
			"toggled", self, "_on_switch_touch_controls_toggled")

	var nanogame_input_actions: Array =\
			GameManager.get_nanogame_input_actions()
	var inputs := {
		# translation-extract:"Up:"
		"Up:": nanogame_input_actions[0],
		# translation-extract:"Down:"
		"Down:": nanogame_input_actions[1],
		# translation-extract:"Left:"
		"Left:": nanogame_input_actions[2],
		# translation-extract:"Right:"
		"Right:": nanogame_input_actions[3],
		# translation-extract:"Action:"
		"Action:": nanogame_input_actions[4],
	}

	var input_buttons_container := GridContainer.new()
	input_buttons_container.columns = 2
	_inputs_section.add_child(input_buttons_container)

	for i in inputs.keys():
		var label := Label.new()
		label.text = i
		label.clip_text = true
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		label.add_font_override("font", FONT_BOLD)
		input_buttons_container.add_child(label)

		var input_button := Button.new()
		input_button.toggle_mode = true
		input_button.group = _input_buttons
		input_button.size_flags_horizontal = SIZE_EXPAND_FILL
		input_button.set_meta("action", inputs[i])
		input_buttons_container.add_child(input_button)
		# warning-ignore:return_value_discarded
		input_button.connect("pressed", _input_dialog, "popup_centered")

	_inputs_section.hide()
	controls.add_child(_inputs_section)

	_input_dialog.set_script(
			preload("res://dialogs/settings_dialog/input_dialog.gd"))
	_inputs_section.add_child(_input_dialog)
	# warning-ignore:return_value_discarded
	_input_dialog.connect("ok_pressed", self, "_on_input_dialog_ok_pressed")
	# warning-ignore:return_value_discarded
	_input_dialog.connect("hide", self, "_on_input_dialog_hide")

	# warning-ignore:return_value_discarded
	GameManager.connect("control_type_changed", self, "_update_inputs_section")
	_update_inputs_section()

	# translation-extract:"Controls"
	add_tab("Controls", controls)


	### Volume ###

	var volume := VBoxContainer.new()

	for i in AudioServer.bus_count:
		if i == 0:
			continue # Skip "Master" bus.

		var volume_button_container := HBoxContainer.new()
		volume.add_child(volume_button_container)

		var label := Label.new()
		# translation-extract:"Everything:"
		# translation-extract:"Music:"
		# translation-extract:"Effects:"
		label.text = AudioServer.get_bus_name(i) + ":"
		label.clip_text = true
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		label.add_font_override("font", FONT_BOLD)
		volume_button_container.add_child(label)

		var volume_button := CheckButton.new()
		volume_button.pressed = not AudioServer.is_bus_mute(i)
		_volume_buttons.append(volume_button)
		volume_button_container.add_child(volume_button)
		# warning-ignore:return_value_discarded
		volume_button.connect(
				"toggled", self, "_on_volume_button_toggled", [i])

		var slider := HSlider.new()
		slider.max_value = 1
		slider.step = 0.01
		slider.value = db2linear(AudioServer.get_bus_volume_db(i))
		volume.add_child(slider)
		# warning-ignore:return_value_discarded
		slider.connect(
				"value_changed", self, "_on_volume_slider_value_changed", [i])

	_update_volume_buttons()

	# translation-extract:"Volume"
	add_tab("Volume", volume)


	# warning-ignore:return_value_discarded
	connect("tab_changed", self, "_on_tab_changed")


func _update_inputs_section() -> void:
	if _input_dialog.visible:
		_input_dialog.hide()

	var control_type: int = GameManager.get_control_type()

	_switch_touch_controls.visible =\
			control_type == GameManager.ControlTypes.TOUCH

	_inputs_section.visible = not _switch_touch_controls.visible
	if not _inputs_section.visible:
		return

	var has_joypad: bool = GameManager.is_using_joypad()
	for i in _input_buttons.get_buttons():
		for j in InputMap.get_action_list(i.get_meta("action")):
			if has_joypad:
				if not j is InputEventJoypadButton and\
						not j is InputEventJoypadMotion:
					continue

				if j is InputEventJoypadButton:
					i.text = Input.get_joy_button_string(j.button_index)
				else:
					i.text = GameManager.get_joystick_name(j)

				break
			elif j is InputEventKey:
				i.text = OS.get_scancode_string(j.scancode)

				break

	_inputs_section.show()


func _update_volume_buttons() -> void:
	for i in _volume_buttons.size():
		_volume_buttons[i].text = str(int(db2linear(
				AudioServer.get_bus_volume_db(i + 1)) * 100)) + "%"


func _on_tab_changed(tab: int) -> void:
	match tab:
		0: # "General".
			_language_button.grab_focus()
		1: # "Controls".
			_control_type_button.grab_focus()
		2: # "Volume".
			_volume_buttons.front().grab_focus()


func _on_language_button_item_selected(id: int) -> void:
	if id == 0:
		GameManager.set_locale_system_default()
	else:
		# Change ID to ignore the "System Default" and separator items.
		TranslationServer.set_locale(ProjectSettings.get_setting(
				"locale/locale_filter")[1][id - 2])

	GameManager.save_settings()


func _on_fullscreen_window_toggled(button_pressed: bool) -> void:
	OS.window_fullscreen = button_pressed

	GameManager.save_settings()


func _on_pause_focus_lost_toggled(button_pressed: bool) -> void:
	ProjectSettings.set_setting(
			"game_settings/pause_focus_lost", button_pressed)

	GameManager.save_settings()


func _on_mute_focus_lost_toggled(button_pressed: bool) -> void:
	ProjectSettings.set_setting(
			"game_settings/mute_focus_lost", button_pressed)

	GameManager.save_settings()


func _on_show_community_warning_toggled(button_pressed: bool) -> void:
	ProjectSettings.set_setting(
			"game_settings/show_community_warning", button_pressed)

	GameManager.save_settings()


func _on_control_type_button_item_selected(id: int) -> void:
	# Change ID to ignore the separator item.
	if id != GameManager.ControlTypes.AUTOMATIC:
		id -= 1

	GameManager.main_control = id

	_update_inputs_section()

	GameManager.save_settings()


func _on_switch_touch_controls_toggled(button_pressed: bool) -> void:
	ProjectSettings.set_setting(
			"game_settings/switch_touch_controls", button_pressed)

	GameManager.save_settings()


func _on_volume_button_toggled(button_pressed: bool, bus: int) -> void:
	AudioServer.set_bus_mute(bus, not button_pressed)

	GameManager.save_settings()


func _on_volume_slider_value_changed(value: float, bus: int) -> void:
	AudioServer.set_bus_volume_db(bus, linear2db(value))

	_update_volume_buttons()

	GameManager.save_settings()


func _on_input_dialog_ok_pressed() -> void:
	var input_button: Button = _input_buttons.get_pressed_button()

	var action_name: String = input_button.get_meta("action")
	if GameManager.get_control_type() == GameManager.ControlTypes.KEYBOARD:
		InputMap.get_action_list(action_name)[0].scancode =\
				_input_dialog.get_input().scancode
	else:
		InputMap.action_erase_event(
				action_name, InputMap.get_action_list(action_name)[1])
		InputMap.action_add_event(action_name, _input_dialog.get_input())

	input_button.text = _input_dialog.get_input_name()

	GameManager.save_settings()


func _on_input_dialog_hide() -> void:
	_input_buttons.get_pressed_button().pressed = false
