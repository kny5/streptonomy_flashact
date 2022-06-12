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

extends CanvasLayer


signal control_type_changed

signal dim_changed

# Emitted in `fade_in()`.
# warning-ignore:unused_signal
signal faded_in
# Emitted in `fade_out()`.
# warning-ignore:unused_signal
signal faded_out

enum ControlTypes {
	AUTOMATIC,
	TOUCH,
	JOYPAD,
	JOYPAD_TOUCH,
	KEYBOARD,
}

const VERSION = "0.6.0"

const SETTINGS_PATH = "user://settings.ini"

const REPOSITORY_LINK = "https://codeberg.org/Librerama/librerama"

const FADE_SPEED = 0.6

const _NANOGAME_INPUT_ACTIONS = [
	"nanogame_up",
	"nanogame_down",
	"nanogame_left",
	"nanogame_right",
	"nanogame_action"
]

const JOYSTICK_SCROLL_SPEED = 500

var main_control: int = ControlTypes.AUTOMATIC setget set_main_control

var dim := false setget set_dim

var _is_switching_scene := false

var _system_locale := ""

var _is_locale_system_default := false
var _is_turning_locale_system_default := false

var _rtl_focused: RichTextLabel


func _ready() -> void:
	set_process(false)

	OS.min_window_size = Vector2(133, 100)

	AudioServer.set_bus_volume_db(1, linear2db(0.5))
	AudioServer.set_bus_volume_db(2, linear2db(0.8))

	if OS.has_feature("release"):
		randomize()

	### Load Settings ###

	var config := ConfigFile.new()
	var error_code: int = config.load(SETTINGS_PATH)
	if error_code != OK:
		if error_code != ERR_FILE_NOT_FOUND:
			push_error("Unable to load settings data. Error code: " +
					str(error_code))
		else:
			save_settings()

		return

	if config.has_section_key("general", "language"):
		var value = config.get_value("general", "language", null)
		if value != null and value is String and not value.empty() and\
				ProjectSettings.get_setting(
						"locale/locale_filter")[1].has(value):
			TranslationServer.set_locale(value)
		else:
			set_locale_system_default()
	else:
		set_locale_system_default()

	if config.has_section_key("general", "fullscreen_window"):
		var value = config.get_value("general", "fullscreen_window", null)
		if value != null and value is bool:
			OS.window_fullscreen = value

	for i in ["pause_focus_lost", "mute_focus_lost", "show_community_warning"]:
		if config.has_section_key("general", i):
			var value = config.get_value("general", i, null)
			if value != null and value is bool:
				ProjectSettings.set_setting("game_settings/" + i, value)

	if config.has_section_key("controls", "main_control"):
		var value = config.get_value("controls", "main_control", null)
		if value != null and value is int and value >= 0 and\
				value < ControlTypes.size():
			set_main_control(value)

	for i in _NANOGAME_INPUT_ACTIONS:
		var input_events: Array = InputMap.get_action_list(i)

		if config.has_section_key("controls", i + "_keyboard"):
			var value = config.get_value("controls", i + "_keyboard", null)
			if value != null and value is int and\
					OS.get_scancode_string(value) != "":
				input_events[0].scancode = value

		if config.has_section_key("controls", i + "_joypad"):
			var value = config.get_value("controls", i + "_joypad", null)
			if value != null:
				if value is Vector2 and value.x >= 0 and value.x <\
						JOY_AXIS_MAX and (value.y == -1 or value.y == 1):
					input_events[1].axis = value.x
					input_events[1].axis_value = value.y
				elif value is int and value >= 0 and value <= JOY_BUTTON_MAX:
					InputMap.action_erase_event(i, input_events[1])

					var input := InputEventJoypadButton.new()
					input.button_index = value
					InputMap.action_add_event(i, input)

	if config.has_section_key("controls", "switch_touch_controls"):
		var value = config.get_value("controls", "switch_touch_controls", null)
		if value != null and value is bool:
			ProjectSettings.set_setting(
					"game_settings/switch_touch_controls", value)

	for i in AudioServer.bus_count:
		if i == 0:
			continue # Skip "Master" bus.

		var bus_name: String = AudioServer.get_bus_name(i).to_lower()

		if config.has_section_key("audio", bus_name + "_mute"):
			var value = config.get_value("audio", bus_name + "_mute", null)
			if value != null and value is bool:
				AudioServer.set_bus_mute(i, value)

		if config.has_section_key("audio", bus_name + "_volume"):
			var value = config.get_value("audio", bus_name + "_volume", null)
			if value != null and value is float and value >= 0 and value <= 1:
				AudioServer.set_bus_volume_db(i, linear2db(value))


	save_settings()

	# warning-ignore:return_value_discarded
	get_viewport().connect(
			"gui_focus_changed", self, "_on_viewport_gui_focus_changed")

	# warning-ignore:return_value_discarded
	Input.connect(
			"joy_connection_changed", self, "_on_Input_joy_connection_changed")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_FOCUS_IN:
			if not OS.has_feature("mobile") and ProjectSettings.get_setting(
					"game_settings/mute_focus_lost"):
				AudioServer.set_bus_mute(0, false)

			if _is_locale_system_default and _system_locale != OS.get_locale():
				set_locale_system_default()
		NOTIFICATION_WM_FOCUS_OUT:
			if not OS.has_feature("mobile") and ProjectSettings.get_setting(
					"game_settings/mute_focus_lost"):
				AudioServer.set_bus_mute(0, true)
		NOTIFICATION_TRANSLATION_CHANGED:
			if not _is_turning_locale_system_default:
				_is_locale_system_default = false


func _process(delta: float) -> void:
	if _rtl_focused == null:
		return

	if Input.is_action_pressed("menu_scroll_up"):
		_rtl_focused.get_v_scroll().value -= JOYSTICK_SCROLL_SPEED *\
				Input.get_action_strength("menu_scroll_up") * delta
	elif Input.is_action_pressed("menu_scroll_down"):
		_rtl_focused.get_v_scroll().value += JOYSTICK_SCROLL_SPEED *\
				Input.get_action_strength("menu_scroll_down") * delta


func switch_main_scene(to_scene: PackedScene) -> void:
	if _is_switching_scene:
		push_error("The game manager is already switching the main scene.")

		return

	fade_in()

	_is_switching_scene = true

	yield(self, "faded_in")
	# warning-ignore:return_value_discarded
	get_tree().change_scene_to(to_scene)

	_is_switching_scene = false

	fade_out()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("general", "language", TranslationServer.get_locale()
			if not _is_locale_system_default else "")

	config.set_value("general", "fullscreen_window", OS.window_fullscreen)

	for i in ["pause_focus_lost", "mute_focus_lost", "show_community_warning"]:
		config.set_value("general", i,
				ProjectSettings.get_setting("game_settings/" + i))

	config.set_value("controls", "main_control", main_control)

	for i in _NANOGAME_INPUT_ACTIONS:
		var input_events: Array = InputMap.get_action_list(i)
		config.set_value("controls", i + "_keyboard", input_events[0].scancode)
		config.set_value(
				"controls", i + "_joypad", input_events[1].button_index
				if input_events[1] is InputEventJoypadButton else
				Vector2(input_events[1].axis, input_events[1].axis_value))

	config.set_value("controls", "switch_touch_controls",
			ProjectSettings.get_setting("game_settings/switch_touch_controls"))

	for i in AudioServer.bus_count:
		if i == 0:
			continue # Skip "Master" bus.

		var bus_name: String = AudioServer.get_bus_name(i).to_lower()
		config.set_value(
				"audio", bus_name + "_mute", AudioServer.is_bus_mute(i))
		config.set_value("audio", bus_name + "_volume",
				db2linear(AudioServer.get_bus_volume_db(i)))

	var error_code: int = config.save(SETTINGS_PATH)
	if error_code != OK:
		push_error("Unable to save settings data. Error code: " +
				str(error_code))


func fade_in() -> void:
	if _is_switching_scene:
		push_warning("The game manager has fading priority when switching " +\
				"the main scene.")

		return

	var fade := $Fade as ColorRect

	# Avoid UI interaction while the player is being blinded.
	fade.mouse_filter = fade.MOUSE_FILTER_STOP
	if fade.get_focus_owner() != null:
		fade.get_focus_owner().release_focus();

	var tween := $Tween as Tween
	# warning-ignore:return_value_discarded
	tween.remove_all()
	# warning-ignore:return_value_discarded
	tween.interpolate_property(fade, "color:a", 0, 1, FADE_SPEED)
	# warning-ignore:return_value_discarded
	tween.interpolate_method(self, "_update_volume_fade", 1, 0, FADE_SPEED)
	# warning-ignore:return_value_discarded
	tween.interpolate_callback(
			fade, FADE_SPEED, "set_mouse_filter", fade.MOUSE_FILTER_IGNORE)
	# warning-ignore:return_value_discarded
	tween.interpolate_callback(self, FADE_SPEED, "emit_signal", "faded_in")
	# warning-ignore:return_value_discarded
	tween.start()


func fade_out() -> void:
	if _is_switching_scene:
		push_warning("The game manager has fading priority when switching " +\
				"the main scene.")

		return

	var tween := $Tween as Tween
	# warning-ignore:return_value_discarded
	tween.remove_all()
	# warning-ignore:return_value_discarded
	tween.interpolate_property($Fade as ColorRect, "color:a", 1, 0, FADE_SPEED)
	# warning-ignore:return_value_discarded
	tween.interpolate_method(self, "_update_volume_fade", 0, 1, FADE_SPEED)
	# warning-ignore:return_value_discarded
	tween.interpolate_callback(self, FADE_SPEED, "emit_signal", "faded_out")
	# warning-ignore:return_value_discarded
	tween.start()


func set_main_control(control: int) -> void:
	if control < 0 or control >= ControlTypes.size():
		push_error('Invalid control type of index "' + str(control) + '".')

	if control == main_control:
		return

	var control_type = get_control_type()

	main_control = control

	if control_type != get_control_type():
		emit_signal("control_type_changed")


func set_dim(is_visible: bool) -> void:
	if dim == is_visible:
		return

	dim = is_visible

	if get_tree().current_scene is CanvasItem:
		get_tree().current_scene.modulate =\
				ColorN("dimgray" if is_visible else "white")

	emit_signal("dim_changed")


func set_locale_system_default() -> void:
	_is_locale_system_default = true
	_is_turning_locale_system_default = true

	_system_locale = OS.get_locale()
	var languages: Array =\
			ProjectSettings.get_setting("locale/locale_filter")[1]
	if languages.has(_system_locale):
		TranslationServer.set_locale(_system_locale)
	else:
		var locale_bits: PoolStringArray = _system_locale.split("_")
		if not locale_bits.empty() and languages.has(locale_bits[0]):
			TranslationServer.set_locale(locale_bits[0])
		else:
			TranslationServer.set_locale("en")

	# Wait for the translation change notification to blow off first.
	yield(get_tree(), "idle_frame")
	_is_turning_locale_system_default = false


func is_locale_system_default() -> bool:
	return _is_locale_system_default


func is_using_joypad() -> bool:
	var control_type: int = get_control_type()
	return control_type == ControlTypes.JOYPAD or\
			control_type == ControlTypes.JOYPAD_TOUCH


func get_nanogame_input_actions() -> Array:
	return _NANOGAME_INPUT_ACTIONS.duplicate()


func get_control_type() -> int:
	if main_control != ControlTypes.AUTOMATIC:
		return main_control

	if Input.get_connected_joypads().empty() and OS.has_touchscreen_ui_hint():
		return ControlTypes.TOUCH

	if not Input.get_connected_joypads().empty():
		return ControlTypes.JOYPAD_TOUCH if OS.has_touchscreen_ui_hint()\
				else ControlTypes.JOYPAD

	return ControlTypes.KEYBOARD


func get_joystick_name(joystick: InputEventJoypadMotion) -> String:
	# translation-extract:"Left Stick Up"
	# translation-extract:"Left Stick Down"
	# translation-extract:"Left Stick Left"
	# translation-extract:"Left Stick Right"
	# translation-extract:"Right Stick Up"
	# translation-extract:"Right Stick Down"
	# translation-extract:"Right Stick Left"
	# translation-extract:"Right Stick Right"
	# translation-extract:"DPAD Up"
	# translation-extract:"DPAD Down"
	# translation-extract:"DPAD Left"
	# translation-extract:"DPAD Right"
	# translation-extract:"Face Button Top"
	# translation-extract:"Face Button Left"
	# translation-extract:"Face Button Bottom"

	var joystick_name: String = Input.get_joy_axis_string(joystick.axis)
	# Remove the "X"/"Y".
	joystick_name = joystick_name.left(joystick_name.length() - 1)

	match joystick.axis:
		JOY_ANALOG_LX, JOY_ANALOG_RX:
			joystick_name += "Left" if joystick.axis_value < 0 else "Right"
		JOY_ANALOG_LY, JOY_ANALOG_RY:
			joystick_name += "Up" if joystick.axis_value < 0 else "Down"

	return joystick_name


func _update_volume_fade(volume: float) -> void:
	AudioServer.set_bus_volume_db(0, linear2db(volume))


func _on_viewport_gui_focus_changed(node: Control) -> void:
	_rtl_focused = node if node is RichTextLabel else null


func _on_Input_joy_connection_changed(_device: int, _connected: bool) -> void:
	if main_control != ControlTypes.AUTOMATIC:
		return

	emit_signal("control_type_changed")
