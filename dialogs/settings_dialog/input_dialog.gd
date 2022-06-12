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

extends SimpleDialog


var _has_joypads := false

var _input_name := ""
var _event: InputEvent


func _ready() -> void:
	update_on_translation_change = false

	rect_size = Vector2(700, 300)

	set_confirmation_mode(true)

	set_process_input(false)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_POST_POPUP:
			_has_joypads = GameManager.is_using_joypad()

			_input_name = ""
			_event = null

			_update_text()

			set_ok_enabled(false)

			set_process_input(true)
		NOTIFICATION_POPUP_HIDE:
			set_process_input(false)
		NOTIFICATION_TRANSLATION_CHANGED:
			_update_text()


func _input(event: InputEvent) -> void:
	if _has_joypads:
		if not event is InputEventJoypadButton and\
				not event is InputEventJoypadMotion:
			return
	elif not event is InputEventKey:
		return

	if event.is_action("pause") or event.is_action("ui_cancel"):
		_update_text(true)

		return

	if event is InputEventJoypadMotion:
		event.axis_value = -1 if event.axis_value < 0 else 1
	else:
		event.pressed = true

	_event = event
	accept_event()

	_update_text()

	set_ok_enabled(true)

	set_process_input(false)


func _update_text(is_invalid:=false) -> void:
	var instructions := ""
	if is_invalid:
		# translation-extract:"Invalid input, try another."
		instructions = "Invalid input, try another."
	elif _event == null:
		# translation-extract:"Press the desired new input in your joypad."
		# translation-extract:"Press the desired new input in your keyboard."
		instructions = "Press the desired new input in your joypad."\
				if _has_joypads else\
				"Press the desired new input in your keyboard."
	else:
		instructions = "Is this the new desired input?"

	var input_status := ""
	if is_invalid:
		# translation-extract:"[Invalid Input]"
		input_status = "[color=#" + ColorN("tomato").to_html() + "]" +\
				tr("[Invalid Input]") + "[/color]"
	elif _event == null:
		# translation-extract:"[None Selected]"
		input_status = "[color=silver]" + tr("[None Selected]") + "[/color]"
	else:
		if _event is InputEventJoypadButton:
			input_status = Input.get_joy_button_string(_event.button_index)
		elif _event is InputEventJoypadMotion:
			input_status = GameManager.get_joystick_name(_event)
		else:
			# translation-extract:"Up"
			# translation-extract:"Down"
			# translation-extract:"Left"
			# translation-extract:"Right"
			# translation-extract:"Space"
			input_status = OS.get_scancode_string(_event.scancode)

		_input_name = input_status

	set_bbcode_text("[center]" + tr(instructions) + "\n\n[b]" + input_status +
			"[/b][/center]")


func get_input() -> InputEvent:
	return _event


func get_input_name() -> String:
	return _input_name
