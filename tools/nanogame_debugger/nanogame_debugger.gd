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


const DEBUG_SESSION_PATH = "res://tools/nanogame_debugger/debug_session.ini"

var _timer := 0
var _time_left = 0.0

var _is_saving_blocked := false

var _nanogame_path := ""

var _is_auto_hiding := false

onready var _nanogame_player := $NanogamePlayer as NanogamePlayer

onready var _time := $TopBar/HBoxContainer/Time as Label


func _ready() -> void:
	set_process(false)

	($NanogamePlayer as NanogamePlayer).energy_lock = true

	if get_tree().paused:
		($TopBar/HBoxContainer/Pause as Button).pressed = true

	# Re-use existing icons.
	($BottomBar/HBoxContainer/OpenNanogameButton as Button).icon =\
			get_icon("folder", "FileDialog")
	($BottomBar/HBoxContainer/ReloadNanogame as Button).icon =\
			get_icon("reload", "FileDialog")
	($BottomBar/HBoxContainer/ToggleAutoHide as Button).icon =\
			get_icon("toggle_hidden", "FileDialog")

	_is_saving_blocked = true

	var difficulty := $TopBar/HBoxContainer/Difficulty as SpinBox
	difficulty.min_value = NanogamePlayer.DIFFICULTY_MIN
	difficulty.max_value = NanogamePlayer.DIFFICULTY_MAX
	var speed := $TopBar/HBoxContainer/Speed as SpinBox
	speed.min_value = NanogamePlayer.SPEED_MIN
	speed.max_value = NanogamePlayer.SPEED_MAX

	_load_session()

	_is_saving_blocked = false

	_save_session()

	# Make the `SpinBox`es lose focus when the mouse exits then, so they don't
	# interrupt input while playing.
	for i in [difficulty, speed, $BottomBar/HBoxContainer/Code as SpinBox]:
		# warning-ignore:return_value_discarded
		i.get_line_edit().connect("mouse_exited", i.get_line_edit(),
				"release_focus")
		# warning-ignore:return_value_discarded
		i.connect("mouse_exited", i.get_line_edit(), "release_focus")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			if ($TopBar/HBoxContainer/Pause as Button).pressed:
				return

			_is_saving_blocked = true

			($TopBar/HBoxContainer/Pause as Button).pressed = true

			_is_saving_blocked = false
		NOTIFICATION_UNPAUSED:
			if not ($TopBar/HBoxContainer/Pause as Button).pressed:
				return

			_is_saving_blocked = true

			($TopBar/HBoxContainer/Pause as Button).pressed = false

			_is_saving_blocked = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and _nanogame_player.is_playing():
		get_tree().paused = not get_tree().paused


func _process(_delta: float) -> void:
	var time_adjusted: float = stepify(_nanogame_player.get_time(), 0.1)
	if _time_left != time_adjusted:
		_time_left = time_adjusted

		_time.text = "%1.1f" % time_adjusted


func _load_nanogame(path: String) -> int:
	var nanogame := Nanogame.new()
	var error_code: int = nanogame.load_data(path.get_base_dir())
	if nanogame.load_data(path.get_base_dir()) != OK:
		($NanogameError as AcceptDialog).popup_centered()

		return error_code

	_timer = nanogame.get_timer()

	_nanogame_path = nanogame.get_directory_path() + "/"

	_nanogame_player.clear_nanogames()
	_nanogame_player.add_nanogames([nanogame])

	($TopBar/HBoxContainer/Start as Button).disabled = false

	($BottomBar/HBoxContainer/CurrentNanogame as Label).text =\
			nanogame.get_name() if not nanogame.get_name().empty()\
			else "[Nameless Nanogame]"

	($BottomBar/HBoxContainer/ReloadNanogame as Button).disabled = false

	_save_session()

	return OK


func _update_references() -> void:
	var is_showing_references: bool =\
			($BottomBar/HBoxContainer/ToggleReferences as Button).pressed
	($TimerReference as ColorRect).visible = is_showing_references
	($PauseReference as ColorRect).visible = is_showing_references

	($TouchNavigationReference as Panel).hide()
	($TouchActionReference as Panel).hide()

	if not is_showing_references:
		return

	match _nanogame_player.get_nanogames().front().get_input():
		Nanogame.Inputs.NAVIGATION:
			($TouchNavigationReference as Panel).show()
			($TouchActionReference as Panel).hide()
		Nanogame.Inputs.ACTION:
			($TouchNavigationReference as Panel).hide()
			($TouchActionReference as Panel).show()
		Nanogame.Inputs.NAVIGATION_ACTION:
			($TouchNavigationReference as Panel).show()
			($TouchActionReference as Panel).show()


func _load_session() -> void:
	var config := ConfigFile.new()
	var error_code: int = config.load(DEBUG_SESSION_PATH)
	if error_code != OK:
		if error_code != ERR_FILE_NOT_FOUND:
			push_error("Unable to load debug session. Error code: " +
					str(error_code))

		return

	# Timer Lock.
	if config.has_section_key("status", "lock_timer"):
		var value = config.get_value("status", "lock_timer", null)
		if value != null and value is bool:
			($TopBar/HBoxContainer/LockTimer as Button).pressed = value

	# Difficulty.
	if config.has_section_key("status", "difficulty"):
		var value = config.get_value("status", "difficulty", null)
		if value != null and value is int and\
				value >= NanogamePlayer.DIFFICULTY_MIN and\
				value <= NanogamePlayer.DIFFICULTY_MAX:
			($TopBar/HBoxContainer/Difficulty as SpinBox).value = value

	# Difficulty Lock.
	if config.has_section_key("status", "lock_difficulty"):
		var value = config.get_value("status", "lock_difficulty", null)
		if value != null and value is bool:
			($TopBar/HBoxContainer/LockDifficulty as Button).pressed = value

	# Speed.
	if config.has_section_key("status", "speed"):
		var value = config.get_value("status", "speed", null)
		if value != null and value is int and\
				value >= NanogamePlayer.SPEED_MIN and\
				value <= NanogamePlayer.SPEED_MAX:
			($TopBar/HBoxContainer/Speed as SpinBox).value = value

	# Speed Lock.
	if config.has_section_key("status", "lock_speed"):
		var value = config.get_value("status", "lock_speed", null)
		if value != null and value is bool:
			($TopBar/HBoxContainer/LockSpeed as Button).pressed = value

	# Nanogame Path.
	if config.has_section_key("nanogame", "nanogame_path"):
		var value = config.get_value("nanogame", "nanogame_path", null)
		if value != null and value is String and not value.empty() and\
				_load_nanogame(value.plus_file("nanogame.json")) == OK:
			($OpenNanogame as FileDialog).current_path = value

	# Debug Code.
	if config.has_section_key("nanogame", "code"):
		var value = config.get_value("nanogame", "code", null)
		if value != null and value is int and value >= 0:
			($BottomBar/HBoxContainer/Code as SpinBox).value = value
			_nanogame_player.debug_code = value

	# References.
	if config.has_section_key("hud", "references"):
		var value = config.get_value("hud", "references", null)
		if value != null and value is bool:
			($BottomBar/HBoxContainer/ToggleReferences as Button).pressed =\
					value

	# Auto Hide.
	if config.has_section_key("hud", "auto_hide"):
		var value = config.get_value("hud", "auto_hide", null)
		if value != null and value is bool:
			($BottomBar/HBoxContainer/ToggleAutoHide as Button).pressed = value


func _save_session() -> void:
	if _is_saving_blocked:
		return

	var config := ConfigFile.new()
	config.set_value("status", "lock_timer", _nanogame_player.timer_lock)
	config.set_value("status", "difficulty", _nanogame_player.difficulty)
	config.set_value("status", "lock_difficulty",
			_nanogame_player.difficulty_lock)
	config.set_value("status", "speed", _nanogame_player.speed)
	config.set_value("status", "lock_speed", _nanogame_player.speed_lock)

	config.set_value("nanogame", "nanogame_path", _nanogame_path)
	config.set_value("nanogame", "code", _nanogame_player.debug_code)
	config.set_value("hud", "references",\
			($BottomBar/HBoxContainer/ToggleReferences as Button).pressed)
	config.set_value("hud", "auto_hide",\
			($BottomBar/HBoxContainer/ToggleAutoHide as Button).pressed)

	var error_code: int = config.save(DEBUG_SESSION_PATH)
	if error_code != OK:
		push_error("Unable to save debug session. Error code: " +
				str(error_code))


func _on_NanogamePlayer_stopped() -> void:
	($TimerReference as ColorRect).hide()
	($PauseReference as ColorRect).hide()
	($TouchNavigationReference as Panel).hide()
	($TouchActionReference as Panel).hide()


func _on_NanogamePlayer_kickoff_started() -> void:
	($KickoffDim as ColorRect).show()

	_time.text = "%1.1f" % _nanogame_player.get_time()

	if not _nanogame_player.difficulty_lock:
		($TopBar/HBoxContainer/Difficulty as SpinBox).value =\
				_nanogame_player.difficulty
	if not _nanogame_player.speed_lock:
		($TopBar/HBoxContainer/Speed as SpinBox).value = _nanogame_player.speed


func _on_NanogamePlayer_error_occured() -> void:
	set_process(false)

	get_tree().paused = false

	($KickoffDim as ColorRect).hide()

	($TopBar/HBoxContainer/Timer as TextureRect).self_modulate =\
			ColorN("white")
	_time.text = "0.0"

	($TopBar/HBoxContainer/Start as Button).icon = preload("_assets/start.svg")
	($TopBar/HBoxContainer/Pause as Button).disabled = true

	($BottomBar/HBoxContainer/OpenNanogameButton as Button).disabled = false
	($BottomBar/HBoxContainer/ReloadNanogame as Button).disabled = false

	($NanogameError as AcceptDialog).popup_centered()


func _on_bar_mouse_entered() -> void:
	if not _is_auto_hiding:
		return

	($TopBar as PanelContainer).modulate.a = 1
	($BottomBar as PanelContainer).modulate.a = 1


func _on_bar_mouse_exited() -> void:
	if not _is_auto_hiding or not _nanogame_player.is_playing():
		return

	($TopBar as PanelContainer).modulate.a = 0
	($BottomBar as PanelContainer).modulate.a = 0


func _on_LockTimer_toggled(button_pressed: bool) -> void:
	_nanogame_player.timer_lock = button_pressed

	_save_session()


func _on_Difficulty_value_changed(value: float) -> void:
	_nanogame_player.difficulty = int(value)

	_save_session()


func _on_LockDifficulty_toggled(button_pressed: bool) -> void:
	_nanogame_player.difficulty_lock = button_pressed

	_save_session()


func _on_Speed_value_changed(value: float) -> void:
	_nanogame_player.speed = int(value)

	_save_session()


func _on_LockSpeed_toggled(button_pressed: bool) -> void:
	_nanogame_player.speed_lock = button_pressed

	_save_session()


func _on_Start_pressed() -> void:
	var is_playing: bool = _nanogame_player.is_playing()
	if not is_playing:
		_nanogame_player.start()

		# Stop if the nanogame player is not in a playable state, as it likely
		# errored out.
		if not _nanogame_player.is_playing():
			return

		match _timer:
			Nanogame.Timers.OBJECTIVE:
				($TopBar/HBoxContainer/Timer as TextureRect).self_modulate =\
						ColorN("orange")
			Nanogame.Timers.SURVIVAL:
				($TopBar/HBoxContainer/Timer as TextureRect).self_modulate =\
						ColorN("green")

		($TopBar/HBoxContainer/Start as Button).icon =\
				preload("_assets/stop.svg")

		if ($BottomBar/HBoxContainer/ToggleReferences as Button).pressed:
			_update_references()

		_nanogame_player.start()
	else:
		set_process(false)

		get_tree().paused = false

		_nanogame_player.stop()

		($KickoffDim as ColorRect).hide()

		($TopBar/HBoxContainer/Timer as TextureRect).self_modulate =\
				ColorN("white")
		_time.text = "0.0"

		($TopBar/HBoxContainer/Start as Button).icon =\
				preload("_assets/start.svg")

	($TopBar/HBoxContainer/Pause as Button).disabled = is_playing

	($BottomBar/HBoxContainer/OpenNanogameButton as Button).disabled =\
			not is_playing
	($BottomBar/HBoxContainer/ReloadNanogame as Button).disabled =\
			not is_playing


func _on_Pause_toggled(button_pressed: bool) -> void:
	get_tree().paused = button_pressed


func _on_ReloadNanogame_pressed() -> void:
	_load_nanogame(_nanogame_path.plus_file("nanogame.json"))


func _on_Code_value_changed(value: float) -> void:
	_nanogame_player.debug_code = int(value)

	_save_session()


func _on_ToggleReferences_toggled(_button_pressed: bool) -> void:
	if _nanogame_player.is_playing():
		_update_references()

	_save_session()


func _on_ToggleAutoHide_toggled(button_pressed: bool) -> void:
	_is_auto_hiding = button_pressed

	_save_session()
