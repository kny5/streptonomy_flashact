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


# Emitted by a signal from the "Settings" button.
# warning-ignore:unused_signal
signal settings_requested

signal stop_requested

# Emitted from the gates animations.
# warning-ignore:unused_signal
signal gates_changed

signal animation_finished

const TOUCH_CONTROLS_MARGIN = 112

const STATUS_TWEEN_SPEED_BASE = 0.25
const STATUS_TWEEN_SPEED_MAX = 1

var practice_mode := false setget set_practice_mode

var _difficulty := 0
var _speed := 0
var _energy := 0
var _score := 0

var _has_joycursor_moved := false

var _messages := {}

var _nanogame: Nanogame

# Stored, as the methods that set their values can be called several times.
onready var _time = $Timer/HBoxContainer/Time as Label
onready var _joycursor := $Joycursor as Sprite


func _ready() -> void:
	if GameManager.get_control_type() == GameManager.ControlTypes.JOYPAD:
		($Pause as Button).hide()

	var file := File.new()
	# warning-ignore:return_value_discarded
	file.open("res://places/arcade_machine/nanogame_hud/messages.json", File.READ)
	_messages = parse_json(file.get_as_text())
	file.close()

	# warning-ignore:return_value_discarded
	GameManager.connect("control_type_changed", self, "_update_input_elements")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			($PauseScreen as ColorRect).show()
			($PauseScreen/VBoxContainer/Menu/Continue as Button).grab_focus()

			if _nanogame == null:
				return

			### Pause Screen Nanogame Information ###

			($PauseScreen/VBoxContainer/NanogameInfo/Icon as TextureRect).\
					texture = _nanogame.get_icon()\
					if _nanogame.get_icon() != null else\
					preload("res://places/arcade_machine/_assets/unknown.svg")

			($PauseScreen/VBoxContainer/NanogameInfo/Name as Label).text =\
					_nanogame.get_name() if not _nanogame.get_name().empty()\
					else "[No Name]"
			($PauseScreen/VBoxContainer/NanogameInfo/Name as Label).\
					self_modulate = ColorN("white"
							if not _nanogame.get_name().empty() else "silver")

			($PauseScreen/VBoxContainer/NanogameInfo/Kickoff as Label).text =\
					_nanogame.get_kickoff()\
					if not _nanogame.get_kickoff().empty() else "[No Kickoff]"
			($PauseScreen/VBoxContainer/NanogameInfo/Kickoff as Label).\
					self_modulate = ColorN("white"
							if not _nanogame.get_name().empty() else "silver")

			var input_icon: StreamTexture
			match _nanogame.get_input():
				Nanogame.Inputs.NAVIGATION:
					input_icon = preload("res://places/arcade_machine/" +\
							"_assets/input_types_small/navigation.svg")
				Nanogame.Inputs.ACTION:
					input_icon = preload("res://places/arcade_machine/" +\
							"_assets/input_types_small/action.svg")
				Nanogame.Inputs.NAVIGATION_ACTION:
					input_icon = preload("res://places/arcade_machine/" +\
							"_assets/input_types_small/navigation_action.svg")
				Nanogame.Inputs.DRAG_DROP:
					input_icon = preload("res://places/arcade_machine/" +\
							"_assets/input_types_small/drag_drop.svg")

			($PauseScreen/VBoxContainer/NanogameInfo/Input as TextureRect).\
					texture = input_icon
			# translation-extract:"Input: %s"
			($PauseScreen/VBoxContainer/NanogameInfo/Input as TextureRect).\
					hint_tooltip = tr("Input: %s") %\
					tr(Nanogame.get_input_name(_nanogame.get_input()))

			($PauseScreen/VBoxContainer/NanogameDescription as RichTextLabel).\
					text = _nanogame.get_description()\
					if not _nanogame.get_description().empty() else\
					"[No Description]"
			($PauseScreen/VBoxContainer/NanogameDescription as RichTextLabel).\
					self_modulate = ColorN(
							"white" if not _nanogame.get_description().empty()
							else "silver")
		NOTIFICATION_UNPAUSED:
			# Check if the touch buttons settings where modified ot not.
			_update_input_elements()

			($PauseScreen as ColorRect).hide()
		NOTIFICATION_THEME_CHANGED:
			var continue_button :=\
					$PauseScreen/VBoxContainer/Menu/Continue as Button
			continue_button.add_stylebox_override("normal",
					get_stylebox("normal", "ButtonPositive"))
			continue_button.add_stylebox_override("hover",
					get_stylebox("hover", "ButtonPositive"))
			continue_button.add_stylebox_override("pressed",
					get_stylebox("pressed", "ButtonPositive"))

			var stop := $PauseScreen/VBoxContainer/Menu/Stop as Button
			stop.add_stylebox_override(
					"normal", get_stylebox("normal", "ButtonNegative"))
			stop.add_stylebox_override(
					"hover", get_stylebox("hover", "ButtonNegative"))
			stop.add_stylebox_override(
					"pressed", get_stylebox("pressed", "ButtonNegative"))
		NOTIFICATION_TRANSLATION_CHANGED:
			if _nanogame == null:
				return

			# translation-extract:"Input: %s"
			($PauseScreen/VBoxContainer/NanogameInfo/Input as TextureRect).\
					hint_tooltip = tr("Input: %s") %\
					tr(Nanogame.get_input_name(_nanogame.get_input()))


func animate_player_start(starting_nanogame: Nanogame) -> void:
	_nanogame = starting_nanogame

	_set_speed_label(NanogamePlayer.SPEED_MIN)
	_set_difficulty_label(NanogamePlayer.DIFFICULTY_MIN)
	_set_energy_label(NanogamePlayer.ENERGY_MAX)
	_set_score_label(0)

	($GateTop/Status/DifficultyIcon as TextureRect).self_modulate =\
			ColorN("white")
	($GateTop/Status/SpeedIcon as TextureRect).self_modulate = ColorN("white")
	($GateTop/Status/EnergyIcon as TextureRect).self_modulate = ColorN("gold")

	($GateTop/Icon as TextureRect).texture = preload("_assets/starting.svg")

	# translation-extract:"Starting"
	($GateBottom/VBoxContainer/State as Label).text = "Starting"
	($GateBottom/VBoxContainer/Message as Label).text =\
			_messages["start"][randi() % _messages["start"].size()]

	($PauseScreen/VBoxContainer/Status/DifficultyIcon as TextureRect).\
			self_modulate = ColorN("white")
	($PauseScreen/VBoxContainer/Status/SpeedIcon as TextureRect).\
			self_modulate = ColorN("white")
	($PauseScreen/VBoxContainer/Status/EnergyIcon as TextureRect).\
			self_modulate = ColorN("gold")

	($HUDAnimations as AnimationPlayer).play("close_gates")
	($HUDAnimations as AnimationPlayer).queue("player_start")


func animate_nanogame_start(nanogame: Nanogame) -> void:
	# Remove the color modulation if the previous nanogame was nameless.
	if _nanogame != null and _nanogame.get_name().empty():
		($GateBottom/VBoxContainer/Message as Label).self_modulate =\
				ColorN("white")

	_nanogame = nanogame

	($HUDAnimations as AnimationPlayer).queue("nanogame_start")
	($HUDAnimations as AnimationPlayer).queue("open_gates")


func animate_nanogame_won(next_nanogame: Nanogame, is_harder:=false) -> void:
	($GateTop/Icon as TextureRect).texture = preload("_assets/victory.svg")

	# translation-extract:"Victory!"
	($GateBottom/VBoxContainer/State as Label).text = "Victory!"
	if not is_harder:
		($GateBottom/VBoxContainer/Message as Label).text =\
				_messages["win"][randi() % _messages["win"].size()]

		match _difficulty:
			1:
				($Music as AudioStreamPlayer).stream =\
						preload("_assets/nanogame_won_1.ogg")
			2:
				($Music as AudioStreamPlayer).stream =\
						preload("_assets/nanogame_won_2.ogg")
			3:
				($Music as AudioStreamPlayer).stream =\
						preload("_assets/nanogame_won_3.ogg")
	else:
		($GateBottom/VBoxContainer/Message as Label).text =\
				_messages["winHarder"][randi() % _messages["winHarder"].size()]

		match _difficulty:
			1:
				($Music as AudioStreamPlayer).stream =\
						preload("_assets/difficulty_increased_1.ogg")
			2:
				($Music as AudioStreamPlayer).stream =\
						preload("_assets/difficulty_increased_2.ogg")

	($HUDAnimations as AnimationPlayer).play("close_gates")
	($HUDAnimations as AnimationPlayer).queue("nanogame_result")

	animate_nanogame_start(next_nanogame)


func animate_nanogame_lost(next_nanogame: Nanogame) -> void:
	($GateTop/Icon as TextureRect).texture = preload("_assets/failure.svg")

	# translation-extract:"Failure!"
	($GateBottom/VBoxContainer/State as Label).text = "Failure!"
	($GateBottom/VBoxContainer/Message as Label).text =\
			_messages["lose"][randi() % _messages["lose"].size()]

	match _difficulty:
		1:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_lost_1.ogg")
		2:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_lost_2.ogg")
		3:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_lost_3.ogg")

	($HUDAnimations as AnimationPlayer).play("close_gates")
	($HUDAnimations as AnimationPlayer).queue("nanogame_result")

	if next_nanogame != null:
		animate_nanogame_start(next_nanogame)
	else:
		($HUDAnimations as AnimationPlayer).queue("player_stop")
		($HUDAnimations as AnimationPlayer).queue("open_gates")


func hide_kickoff() -> void:
	($HUDAnimations as AnimationPlayer).play("hide_kickoff")


func update_status_labels() -> void:
	var tween := $Tween as Tween
	# warning-ignore:return_value_discarded
	tween.stop_all()

	### Difficulty ###

	var difficulty_old := int(($GateTop/Status/Difficulty as Label).text)
	if _difficulty != difficulty_old:
		var interpolation_speed: float = min(STATUS_TWEEN_SPEED_MAX,
				STATUS_TWEEN_SPEED_BASE * abs(difficulty_old - _difficulty))
		# warning-ignore:return_value_discarded
		tween.interpolate_method(self, "_set_difficulty_label", difficulty_old,
				_difficulty, interpolation_speed, Tween.TRANS_LINEAR,
				Tween.EASE_IN_OUT, STATUS_TWEEN_SPEED_BASE)

		var difficulty_icon := $GateTop/Status/DifficultyIcon as TextureRect
		# warning-ignore:return_value_discarded
		tween.interpolate_property(difficulty_icon, "self_modulate",
				difficulty_icon.self_modulate, ColorN("dodgerblue"),
				STATUS_TWEEN_SPEED_BASE)
		# warning-ignore:return_value_discarded
		tween.interpolate_property(difficulty_icon, "self_modulate",
				ColorN("dodgerblue"), ColorN("white")
				if _difficulty < NanogamePlayer.DIFFICULTY_MAX
				else ColorN("gold"), STATUS_TWEEN_SPEED_BASE,
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT,
				interpolation_speed + STATUS_TWEEN_SPEED_BASE)

		($PauseScreen/VBoxContainer/Status/DifficultyIcon as TextureRect).\
				self_modulate = ColorN("white")\
				if _difficulty < NanogamePlayer.DIFFICULTY_MAX\
				else ColorN("gold")


	### Speed ###

	var speed_old := int(($GateTop/Status/Speed as Label).text)
	if _speed != speed_old:
		var interpolation_speed: float = min(STATUS_TWEEN_SPEED_MAX,
				STATUS_TWEEN_SPEED_BASE * abs(speed_old - _speed))
		# warning-ignore:return_value_discarded
		tween.interpolate_method(self, "_set_speed_label", speed_old, _speed,
				interpolation_speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT,
				STATUS_TWEEN_SPEED_BASE)

		var speed_icon := $GateTop/Status/SpeedIcon as TextureRect
		# warning-ignore:return_value_discarded
		tween.interpolate_property(speed_icon, "self_modulate",
				speed_icon.self_modulate, ColorN("dodgerblue"),
				STATUS_TWEEN_SPEED_BASE)
		# warning-ignore:return_value_discarded
		tween.interpolate_property(speed_icon, "self_modulate",
				ColorN("dodgerblue"), ColorN("white")
				if _speed < NanogamePlayer.SPEED_MAX else ColorN("gold"),
				STATUS_TWEEN_SPEED_BASE, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT,
				interpolation_speed + STATUS_TWEEN_SPEED_BASE)

		($PauseScreen/VBoxContainer/Status/SpeedIcon as TextureRect).\
				self_modulate = ColorN("white")\
				if _speed < NanogamePlayer.SPEED_MAX else ColorN("gold")

		var is_speed_max: bool = _speed == NanogamePlayer.SPEED_MAX
		# Visually notify that the difficulty can increase if speed is at max
		# but the difficulty isn't, or remove it if it just increased.
		if  _difficulty < NanogamePlayer.DIFFICULTY_MAX and\
				(is_speed_max or speed_old == NanogamePlayer.SPEED_MAX):
			var difficulty_icon :=\
					$GateTop/Status/DifficultyIcon as TextureRect
			# warning-ignore:return_value_discarded
			tween.interpolate_property(difficulty_icon, "self_modulate",
					ColorN("white") if is_speed_max else ColorN("purple"),
					ColorN("purple") if is_speed_max else ColorN("white"),
					STATUS_TWEEN_SPEED_BASE)

			($PauseScreen/VBoxContainer/Status/DifficultyIcon as TextureRect).\
					self_modulate = ColorN("purple") if is_speed_max\
					else ColorN("white")


	if not practice_mode:
		### Energy ###

		var energy_old := int(($GateTop/Status/Energy as Label).text)
		if _energy != energy_old:
			var interpolation_speed: float = min(STATUS_TWEEN_SPEED_MAX,
					STATUS_TWEEN_SPEED_BASE * abs(energy_old - _energy))
			# warning-ignore:return_value_discarded
			tween.interpolate_method(self, "_set_energy_label", energy_old,
					_energy, interpolation_speed, Tween.TRANS_LINEAR,
					Tween.EASE_IN_OUT, STATUS_TWEEN_SPEED_BASE)

			var color_start: Color
			if _energy > energy_old:
				color_start = ColorN("limegreen")
			else:
				color_start = ColorN("crimson")

			var energy_icon := $GateTop/Status/EnergyIcon as TextureRect
			# warning-ignore:return_value_discarded
			tween.interpolate_property(energy_icon, "self_modulate",
					energy_icon.self_modulate, color_start,
					STATUS_TWEEN_SPEED_BASE)

			var color_end: Color
			if _energy <= NanogamePlayer.ENERGY_LOSS:
				color_end = ColorN("firebrick")
			elif _energy == NanogamePlayer.ENERGY_MAX:
				color_end = ColorN("gold")
			else:
				color_end = ColorN("white")
			# warning-ignore:return_value_discarded
			tween.interpolate_property(energy_icon, "self_modulate",
					color_start, color_end, STATUS_TWEEN_SPEED_BASE,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT,
					interpolation_speed + STATUS_TWEEN_SPEED_BASE)

			($PauseScreen/VBoxContainer/Status/EnergyIcon as TextureRect).\
					self_modulate = color_end


		### Score ###

		var score_old :=\
				int(($GateBottom/VBoxContainer/ScoreValue as Label).text)
		var score_gain: int = _score - score_old
		if score_gain > 0:
			# warning-ignore:return_value_discarded
			tween.interpolate_method(self, "_set_score_label", score_old,
					_score, STATUS_TWEEN_SPEED_MAX, Tween.TRANS_LINEAR,
					Tween.EASE_IN_OUT, STATUS_TWEEN_SPEED_BASE)

			var score_gain_node := $GateBottom/VBoxContainer/ScoreGain as Label
			score_gain_node.text = "+ " + str(score_gain)
			# warning-ignore:return_value_discarded
			tween.interpolate_property(score_gain_node, "self_modulate:a", 0,
					1, STATUS_TWEEN_SPEED_BASE)
			# warning-ignore:return_value_discarded
			tween.interpolate_property(score_gain_node, "self_modulate:a", 1,
					0, STATUS_TWEEN_SPEED_BASE, Tween.TRANS_LINEAR,
					Tween.EASE_IN_OUT, STATUS_TWEEN_SPEED_MAX +
					STATUS_TWEEN_SPEED_BASE)


	# warning-ignore:return_value_discarded
	tween.start()


func force_clear() -> void:
	# Remove the color modulation if the previous nanogame was nameless.
	if _nanogame != null and _nanogame.get_name().empty():
		($GateBottom/VBoxContainer/Message as Label).self_modulate =\
				ColorN("white")

	_nanogame = null

	($KickoffScreen as ColorRect).modulate.a = 0

	($Timer as PanelContainer).hide()

	($TouchNavigation as Control).hide()
	($TouchAction as Control).hide()

	($Pause as Button).mouse_filter = MOUSE_FILTER_IGNORE
	($Pause as Button).self_modulate.a = 0


func set_practice_mode(is_enabled: bool) -> void:
	practice_mode = is_enabled

	($GateTop/Status/EnergyIcon as TextureRect).visible = not is_enabled
	($GateTop/Status/Energy as Label).visible = not is_enabled
	($GateBottom/VBoxContainer/ScoreLabel as Label).visible = not is_enabled
	($GateBottom/VBoxContainer/ScoreValue as Label).visible = not is_enabled

	($PauseScreen/VBoxContainer/Status/EnergyIcon as TextureRect).visible =\
			not is_enabled
	($PauseScreen/VBoxContainer/Status/Energy as Label).visible =\
			not is_enabled
	($PauseScreen/VBoxContainer/Score as VBoxContainer).visible =\
			not is_enabled


func set_time(time: float) -> void:
	_time.text = "%1.1f" % time


func set_difficulty(value: int) -> void:
	_difficulty = value
	($PauseScreen/VBoxContainer/Status/Difficulty as Label).text = str(value)


func set_speed(value: int) -> void:
	_speed = value
	($PauseScreen/VBoxContainer/Status/Speed as Label).text = str(value)


func set_energy(value: int) -> void:
	_energy = value
	($PauseScreen/VBoxContainer/Status/Energy as Label).text = str(value)


func set_score(value: int) -> void:
	_score = value
	($PauseScreen/VBoxContainer/Score/Value as Label).text = "%06d" % value


func set_joycursor_position(position: Vector2) -> void:
	if not _has_joycursor_moved:
		_has_joycursor_moved = true

		($JoycursorBlink as AnimationPlayer).play("stop")

	_joycursor.position = position


func _update_input_elements() -> void:
	var control_type: int = GameManager.get_control_type()

	($Pause as Button).visible =\
			control_type != GameManager.ControlTypes.JOYPAD

	if _nanogame == null:
		return

	var touch_navigation := $TouchNavigation as TextureRect
	touch_navigation.hide()
	var touch_action := $TouchAction as Control
	touch_action.hide()

	var nanogame_input: int = _nanogame.get_input()

	_joycursor.visible = nanogame_input == Nanogame.Inputs.DRAG_DROP and\
			control_type == GameManager.ControlTypes.JOYPAD
	if _joycursor.visible:
		_has_joycursor_moved = false

		($JoycursorBlink as AnimationPlayer).play("blink")
	else:
		($JoycursorBlink as AnimationPlayer).stop()

	if nanogame_input == Nanogame.Inputs.DRAG_DROP or\
			control_type != GameManager.ControlTypes.TOUCH:
		return

	if ProjectSettings.get_setting("game_settings/switch_touch_controls"):
		touch_navigation.anchor_left = ANCHOR_END
		touch_navigation.margin_left =\
				-TOUCH_CONTROLS_MARGIN - touch_navigation.texture.get_width()

		touch_action.anchor_right = ANCHOR_BEGIN
		touch_action.margin_left = TOUCH_CONTROLS_MARGIN
	else:
		touch_navigation.anchor_right = ANCHOR_BEGIN
		touch_navigation.margin_left = TOUCH_CONTROLS_MARGIN

		touch_action.anchor_left = ANCHOR_END
		touch_action.margin_left = -TOUCH_CONTROLS_MARGIN -\
				($TouchAction/Action as TouchScreenButton).normal.get_width()

	match nanogame_input:
		Nanogame.Inputs.NAVIGATION:
			touch_navigation.show()
		Nanogame.Inputs.ACTION:
			touch_action.show()
		Nanogame.Inputs.NAVIGATION_ACTION:
			touch_navigation.show()
			touch_action.show()

	if nanogame_input == Nanogame.Inputs.NAVIGATION or\
			nanogame_input == Nanogame.Inputs.NAVIGATION_ACTION:
		match _nanogame.get_input_modifier():
			Nanogame.InputModifiers.NONE:
				touch_navigation.texture =\
						preload("_assets/input_elements/navigation_full.svg")
			Nanogame.InputModifiers.HORIZONTAL:
				touch_navigation.texture = preload(\
						"_assets/input_elements/navigation_horizontal.svg")
			Nanogame.InputModifiers.VERTICAL:
				touch_navigation.texture = preload(\
						"_assets/input_elements/navigation_vertical.svg")


func _prepare_nanogame_start() -> void:
	_update_input_elements()

	### Main Information ###

	var nanogame_icon: StreamTexture = _nanogame.get_icon()
	($GateTop/Icon as TextureRect).texture =\
			nanogame_icon if nanogame_icon != null\
			else preload("res://places/arcade_machine/_assets/unknown.svg")

	# translation-extract:"Up Next:"
	($GateBottom/VBoxContainer/State as Label).text = "Up Next:"

	# translation-extract:"[No Name]"
	($GateBottom/VBoxContainer/Message as Label).text = _nanogame.get_name()\
			if not _nanogame.get_name().empty() else "[No Name]"
	if _nanogame.get_name().empty():
		($GateBottom/VBoxContainer/Message as Label).self_modulate =\
				ColorN("silver")


	### Kickoff ###

	var input_icon: StreamTexture
	match _nanogame.get_input():
		Nanogame.Inputs.NAVIGATION:
			input_icon = preload("_assets/input_types_big/navigation.svg")
		Nanogame.Inputs.ACTION:
			input_icon = preload("_assets/input_types_big/action.svg")
		Nanogame.Inputs.NAVIGATION_ACTION:
			input_icon =\
					preload("_assets/input_types_big/navigation_action.svg")
		Nanogame.Inputs.DRAG_DROP:
			input_icon = preload("_assets/input_types_big/drag_drop.svg")
	($KickoffScreen/VBoxContainer/Input as TextureRect).texture = input_icon

	# translation-extract:"[No Kickoff]"
	($KickoffScreen/VBoxContainer/Kickoff as Label).text =\
			_nanogame.get_kickoff() if not _nanogame.get_kickoff().empty()\
			else "[No Kickoff]"
	($KickoffScreen/VBoxContainer/Kickoff as Label).self_modulate = ColorN(
			"white" if not _nanogame.get_kickoff().empty() else "silver")


	### Timer Icon ###

	var timer_icon: StreamTexture
	match _nanogame.get_timer():
		Nanogame.Timers.OBJECTIVE:
			timer_icon = preload(
					"res://places/arcade_machine/_assets/timer_objective.svg")
		Nanogame.Timers.SURVIVAL:
			timer_icon = preload(
					"res://places/arcade_machine/_assets/timer_survival.svg")

	($Timer/HBoxContainer/Type as TextureRect).texture = timer_icon
	# translation-extract:"Timer:"
	($Timer/HBoxContainer/Type as TextureRect).hint_tooltip =\
			tr("Timer:") + " " + Nanogame.get_timer_name(_nanogame.get_timer())


	### Music ###

	match _difficulty:
		1:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_start_1.ogg")
		2:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_start_2.ogg")
		3:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_start_3.ogg")
	($Music as AudioStreamPlayer).play()


func _prepare_player_stop() -> void:
	# Remove the color modulation if the previous nanogame was nameless.
	if _nanogame != null and _nanogame.get_name().empty():
		($GateBottom/VBoxContainer/Message as Label).self_modulate =\
				ColorN("white")

	_nanogame = null

	($GateTop/Icon as TextureRect).texture = preload("_assets/stopping.svg")

	# translation-extract:"Game Over"
	($GateBottom/VBoxContainer/State as Label).text = "Game Over"
	($GateBottom/VBoxContainer/Message as Label).text =\
			_messages["stop"][randi() % _messages["stop"].size()]

	match _difficulty:
		1:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/player_stop_1.ogg")
		2:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/player_stop_2.ogg")
		3:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/player_stop_3.ogg")
	($Music as AudioStreamPlayer).play()


func _set_speed_label(value: int) -> void:
	($GateTop/Status/Speed as Label).text = str(value)


func _set_difficulty_label(value: int) -> void:
	($GateTop/Status/Difficulty as Label).text = str(value)


func _set_energy_label(value: int) -> void:
	($GateTop/Status/Energy as Label).text = str(value)


func _set_score_label(value: int) -> void:
	($GateBottom/VBoxContainer/ScoreValue as Label).text = "%06d" % value


func _on_pause_changed(is_paused: bool) -> void:
	get_tree().paused = is_paused


func _on_Stop_pressed() -> void:
	get_tree().paused = false

	($KickoffScreen as ColorRect).modulate.a = 0

	($HUDAnimations as AnimationPlayer).play("player_stop")
	($HUDAnimations as AnimationPlayer).queue("open_gates")

	emit_signal("stop_requested")


func _on_HUDAnimations_animation_finished(_anim_name: String) -> void:
	emit_signal("animation_finished")
