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

class_name NanogamePlayer
extends ViewportContainer


signal stopped

signal kickoff_started
signal kickoff_ended

signal timer_stopped

signal nanogame_won
signal nanogame_lost

signal next_nanogame_yielded
signal free_nanogame_yielded

signal error_occured

const DIFFICULTY_MAX = 3
const DIFFICULTY_MIN = 1

const SPEED_MAX = 10
const SPEED_MIN = 1
const SPEED_LOSS = 2
const SPEED_INCREMENT = 0.075

const ENERGY_MAX = 16
const ENERGY_MIN = 0
const ENERGY_LOSS = 4

const VIEW_SIZE = Vector2(960, 720)

const JOYSTICK_DEADZONE = 0.1
const JOYMOUSE_SPEED = 750

const AUDIO_SCALE_DIVISOR = 1.7

var difficulty: int = DIFFICULTY_MIN setget set_difficulty
var speed: int = SPEED_MIN setget set_speed
var energy: int = ENERGY_MAX setget set_energy

var difficulty_lock := false
var speed_lock := false
var energy_lock := false

var timer_lock := false setget set_timer_lock

var joycursor_enabled := false setget set_joycursor_enabled

var debug_code := 0

var _is_playing := false

var _nanogames := []

var _nanogame_current: Nanogame
var _nanogame_scene: Node
var _nanogame_timer: int
var _nanogame_translation: Translation

var _joycursor_position := Vector2()
var _joystick_direction := Vector2()

var _intersected_objects_2d := []

var _yield: GDScriptFunctionState

export var reset_status_on_stop := true

export var yield_nanogame_swapping := false setget set_yield_nanogame_swapping

onready var _nanogame_viewport := $NanogameViewport as Viewport

# Stored, as `get_time()` can be called multiple times in a row of frames by
# the interfaces.
onready var _goal_timer := $Goal as Timer

onready var _direct_space_state_2d: Physics2DDirectSpaceState =\
		_nanogame_viewport.world_2d.direct_space_state


func _ready() -> void:
	set_process_unhandled_input(false)
	set_physics_process(false)

	_nanogame_viewport.msaa = get_tree().root.msaa
	_nanogame_viewport.usage = get_tree().root.usage
	_nanogame_viewport.shadow_atlas_size = get_tree().root.shadow_atlas_size

	# warning-ignore:return_value_discarded
	GameManager.connect("control_type_changed", self,
			"_on_GameManager_control_type_changed")

	# warning-ignore:return_value_discarded
	get_tree().connect("screen_resized", self, "_on_SceneTree_screen_resized")
	# Delay first resize update, so the rect size isn't zero.
	# warning-ignore:return_value_discarded
	get_tree().create_timer(0.01).connect(
			"timeout", self, "_on_SceneTree_screen_resized")


func _notification(what: int) -> void:
	if not _is_playing:
		return

	match what:
		NOTIFICATION_PAUSED:
			_joystick_direction = Vector2.ZERO

			Engine.time_scale = 1
			Engine.iterations_per_second =\
					ProjectSettings.get_setting("physics/common/physics_fps")
			AudioServer.global_rate_scale = 1
		NOTIFICATION_UNPAUSED:
			set_speed(speed)
		NOTIFICATION_TRANSLATION_CHANGED:
			if _nanogame_translation != null:
				TranslationServer.remove_translation(_nanogame_translation)

			_nanogame_translation = _nanogame_current.get_current_translation()
			if _nanogame_translation != null:
				TranslationServer.add_translation(_nanogame_translation)
		NOTIFICATION_WM_QUIT_REQUEST:
			# Avoid getting an error in case the nanogame has something that
			# triggers the signal when offscreen (e.g.
			# `VisibilityNotifier2D/3D`).
			if is_instance_valid(_nanogame_scene) and _nanogame_scene.\
					is_connected("ended", self, "_end_nanogame"):
				_nanogame_scene.disconnect("ended", self, "_end_nanogame")



func _unhandled_input(event: InputEvent) -> void:
	match _nanogame_current.get_input():
		Nanogame.Inputs.NAVIGATION:
			match _nanogame_current.get_input_modifier():
				Nanogame.InputModifiers.NONE:
					if not event.is_action("nanogame_left") and\
							not event.is_action("nanogame_right") and\
							not event.is_action("nanogame_up") and\
							not event.is_action("nanogame_down"):
						return
				Nanogame.InputModifiers.HORIZONTAL:
					if not event.is_action("nanogame_left") and\
							not event.is_action("nanogame_right"):
						return
				Nanogame.InputModifiers.VERTICAL:
					if not event.is_action("nanogame_up") and\
							not event.is_action("nanogame_down"):
						return
		Nanogame.Inputs.ACTION:
			if not event.is_action("nanogame_action"):
				return
		Nanogame.Inputs.NAVIGATION_ACTION:
			match _nanogame_current.get_input_modifier():
				Nanogame.InputModifiers.NONE:
					if not event.is_action("nanogame_left") and\
							not event.is_action("nanogame_right") and\
							not event.is_action("nanogame_up") and\
							not event.is_action("nanogame_down") and\
							not event.is_action("nanogame_action"):
						return
				Nanogame.InputModifiers.HORIZONTAL:
					if not event.is_action("nanogame_left") and\
							not event.is_action("nanogame_right") and\
							not event.is_action("nanogame_action"):
						return
				Nanogame.InputModifiers.VERTICAL:
					if not event.is_action("nanogame_up") and\
							not event.is_action("nanogame_down") and\
							not event.is_action("nanogame_action"):
						return
		Nanogame.Inputs.DRAG_DROP:
			if not joycursor_enabled:
				if not event is InputEventMouse:
					return
			else:
				if not event is InputEventJoypadMotion and\
						not (event is InputEventJoypadButton and
								event.is_action("nanogame_action")):
					return

				# Transform the joypad event into a mouse event.
				if event is InputEventJoypadButton:
					var is_pressed = event.pressed
					event = InputEventMouseButton.new()
					if is_pressed:
						event.button_mask = BUTTON_LEFT
					event.pressed = is_pressed
					event.position = _joycursor_position
					event.global_position = _joycursor_position
				elif event is InputEventJoypadMotion:
					match event.axis:
						JOY_AXIS_0: # Horizontal.
							_joystick_direction.x = event.axis_value *\
									JOYMOUSE_SPEED if abs(event.axis_value) >\
									JOYSTICK_DEADZONE else 0
						JOY_AXIS_1: # Vertical.
							_joystick_direction.y = event.axis_value *\
									JOYMOUSE_SPEED if abs(event.axis_value) >\
									JOYSTICK_DEADZONE else 0

					if _joystick_direction != Vector2.ZERO:
						set_physics_process(true)
					else:
						# Turn the processing off deferred, so it can process
						# the last "(0, 0)" value.
						call_deferred("set_physics_process", false)

					return

	_nanogame_viewport.unhandled_input(event)


func _physics_process(delta: float) -> void:
	_joycursor_position += _joystick_direction * delta

	# Keep the joycursor inside the screen.
	_joycursor_position.x = clamp(_joycursor_position.x, 0, rect_size.x)
	_joycursor_position.y = clamp(_joycursor_position.y, 0, VIEW_SIZE.y)

	var event := InputEventMouseMotion.new()
	if Input.is_action_pressed("nanogame_action"):
		event.button_mask = BUTTON_LEFT

	event.position = _joycursor_position
	event.global_position = _joycursor_position
	_nanogame_viewport.unhandled_input(event)


func start() -> void:
	if _is_playing:
		return

	if _nanogames.empty():
		push_warning("Nanogame player can't be started if it doesn't have " +
				"any nanogames to play.")

		return

	_is_playing = true

	if speed > SPEED_MIN:
		set_speed(speed)

	_nanogames.shuffle()

	_next_nanogame()


func stop() -> void:
	if not _is_playing:
		return

	_is_playing = false

	if _nanogame_current != null:
		set_process_unhandled_input(false)
		set_physics_process(false)

		# Avoid crashing in case the nanogame has something that triggers the
		# signal when offscreen (e.g. `VisibilityNotifier2D/3D`).
		if is_instance_valid(_nanogame_scene) and\
				_nanogame_scene.is_connected("ended", self, "_end_nanogame"):
			_nanogame_scene.disconnect("ended", self, "_end_nanogame")

		_goal_timer.stop()

		($Kickoff as Timer).stop()
		($Victory as Timer).stop()
		($Failure as Timer).stop()

		if _yield != null and _yield.is_valid():
			_yield.resume()

		_free_nanogame()

	if reset_status_on_stop:
		difficulty = DIFFICULTY_MIN
		speed = SPEED_MIN
		energy = ENERGY_MAX

	Engine.time_scale = 1
	Engine.iterations_per_second =\
			ProjectSettings.get_setting("physics/common/physics_fps")
	AudioServer.global_rate_scale = 1

	emit_signal("stopped")


func add_nanogames(nanogames: Array) -> void:
	if _is_playing:
		push_error("Unable to add nanogames while nanogame player is " +
				"playing. It must be stopped first.")

		return

	if nanogames.empty():
		return

	var nanogames_valid := []
	for i in nanogames:
		if not i is Nanogame:
			push_error('Object "' + str(i) +
					"\" can't be added to the nanogame player. " +
					"Only nanogames are allowed.")

			continue

		if not i.has_data():
			push_error('Unable to add nanogame "' + i.get_name() +
					"\" to nanogame player. It doesn't contain valid data.")

			continue

		if _nanogames.has(i) or nanogames_valid.has(i):
			push_warning('Nanogame "' + i.get_name() + '" is already ' +
					"present in the nanogame player or in the given list. " +
					"Skipped.")

			continue

		nanogames_valid.append(i)

	_nanogames += nanogames_valid


func clear_nanogames() -> void:
	if _is_playing:
		push_error(
				"Unable to clear nanogames while nanogame player is playing.")

		return

	_nanogames.clear()


func resume_yield() -> void:
	if yield_nanogame_swapping and _yield != null:
		_yield.resume()


func set_timer_lock(is_locked: bool) -> void:
	timer_lock = is_locked

	_goal_timer.paused = is_locked

	if _is_playing and _goal_timer.is_stopped():
		_goal_timer.start()


func set_difficulty(value: int) -> void:
	if value < DIFFICULTY_MIN or value > DIFFICULTY_MAX:
		push_error("Nanogame player's `difficulty` value must be above or " +
				'equal to "' + str(DIFFICULTY_MIN) + '", or below or equal ' +
				'to "' + str(DIFFICULTY_MAX) + '".')

		return

	difficulty = value


func set_speed(value: int) -> void:
	if value < SPEED_MIN or value > SPEED_MAX:
		push_error("Nanogame player's `speed` value must be above or equal " +
				'to "' + str(SPEED_MIN) + '", or below or equal to "' +
				str(SPEED_MAX) + '".')

		return

	speed = value

	if not _is_playing:
		return

	var speed_adjusted: float = (value - 1) * SPEED_INCREMENT
	Engine.time_scale = 1 + speed_adjusted
	Engine.iterations_per_second = ProjectSettings.get_setting(
			"physics/common/physics_fps") * Engine.time_scale
	AudioServer.global_rate_scale = 1 - speed_adjusted / AUDIO_SCALE_DIVISOR


func set_energy(value: int) -> void:
	if value < ENERGY_MIN or value > ENERGY_MAX:
		push_error("Nanogame player's `energy` value must be above or equal " +
				'to "' + str(ENERGY_MIN) + '", or below or equal to "' +
				str(ENERGY_MAX) + '".')

		return

	energy = value


func set_joycursor_enabled(is_enabled: bool) -> void:
	if joycursor_enabled == is_enabled:
		return

	joycursor_enabled = is_enabled
	if joycursor_enabled:
		# Place the "Joycursor" in the center of the screen.
		_joycursor_position = rect_size / 2

	set_physics_process(is_processing_unhandled_input())


func set_yield_nanogame_swapping(is_enabled: bool) -> void:
	resume_yield()

	yield_nanogame_swapping = is_enabled


func is_playing() -> bool:
	return _is_playing


func get_time() -> float:
	return _goal_timer.time_left if not _goal_timer.is_stopped()\
			else _goal_timer.wait_time


func get_nanogames() -> Array:
	return _nanogames.duplicate()


func get_current_nanogame() -> Nanogame:
	if not _is_playing:
		return null

	return _nanogame_current


func get_next_nanogame() -> Nanogame:
	if not _is_playing:
		return null

	return _nanogames.front()


func get_joycursor_position() -> Vector2:
	return _joycursor_position


func _next_nanogame() -> void:
	_nanogame_current = _nanogames.front()
	_nanogames.append(_nanogames.pop_front())

	_nanogame_timer = _nanogame_current.get_timer()

	_nanogame_translation = _nanogame_current.get_current_translation()
	if _nanogame_translation != null:
		TranslationServer.add_translation(_nanogame_translation)

	# Place the "Joycursor" in the center of the screen.
	_joycursor_position = rect_size / 2

	if yield_nanogame_swapping:
		# warning-ignore:function_may_yield
		_yield = _yield_state()

		emit_signal("next_nanogame_yielded")

		if _yield != null and _yield.is_valid():
			yield(_yield, "completed")
		if not _is_playing:
			return

	_nanogame_scene = _nanogame_current.get_scene().instance() as Node

	if not _nanogame_scene.has_method("nanogame_prepare"):
		push_error('The nanogame "' + _nanogame_current.get_name() +
				'" at path "' + _nanogame_current.get_directory_path() +
				'" lacks the `nanogame_prepare()` method. ' +
				"The nanogame player has been stopped.")

		emit_signal("error_occured")

		stop()

		return

	if not _nanogame_scene.has_signal("ended"):
		push_error('The nanogame "' + _nanogame_current.get_name() +
				'" at path "' + _nanogame_current.get_directory_path() +
				'" lacks the `ended` signal. ' +
				"The nanogame player has been stopped.")

		emit_signal("error_occured")

		stop()

		return

	_nanogame_viewport.physics_object_picking =\
			_nanogame_current.get_input() == Nanogame.Inputs.DRAG_DROP

	_nanogame_viewport.add_child(_nanogame_scene)
	_nanogame_scene.nanogame_prepare(difficulty, debug_code)

	($Kickoff as Timer).start()
	emit_signal("kickoff_started")


func _free_nanogame() -> void:
	_nanogame_current = null

	if _nanogame_scene != null and is_instance_valid(_nanogame_scene) and\
			_nanogame_scene.is_inside_tree():
		_nanogame_viewport.remove_child(_nanogame_scene)

		_nanogame_scene.queue_free()

	if _nanogame_translation != null:
		TranslationServer.remove_translation(_nanogame_translation)
		_nanogame_translation = null

	_intersected_objects_2d.clear()


func _end_nanogame(has_won: bool) -> void:
	if has_won and not _goal_timer.is_stopped() and\
			_nanogame_timer == Nanogame.Timers.SURVIVAL:
		return

	# Return if there's no connection, as there are some cases where this
	# method can be called multiple times in the same frame.
	if not _nanogame_scene.is_connected("ended", self, "_end_nanogame"):
		return

	set_process_unhandled_input(false)
	set_physics_process(false)

	_nanogame_scene.disconnect("ended", self, "_end_nanogame")

	match _nanogame_timer:
		Nanogame.Timers.OBJECTIVE:
			if has_won:
				($Victory as Timer).start()
			elif not ($Goal as Timer).is_stopped() or ($Goal as Timer).paused:
				($Failure as Timer).start()
			else:
				_lose_nanogame()
		Nanogame.Timers.SURVIVAL:
			if has_won:
				_win_nanogame()
			else:
				($Failure as Timer).start()

	# Emit it earlier, so the timer in the interfaces can stop at the last
	# value, instead of going directly to 0.
	emit_signal("timer_stopped")

	_goal_timer.stop()


func _win_nanogame() -> void:
	emit_signal("nanogame_won")

	if yield_nanogame_swapping:
		# warning-ignore:function_may_yield
		_yield = _yield_state()

		emit_signal("free_nanogame_yielded")

		if _yield != null and _yield.is_valid():
			yield(_yield, "completed")
		if not _is_playing:
			return

		# Give time to the previous `yield()` to disconnect.
		yield(get_tree(), "idle_frame")

	_free_nanogame()

	if energy < ENERGY_MAX and not energy_lock:
		energy += 1

	if speed < SPEED_MAX:
		if not speed_lock:
			speed += 1

			Engine.time_scale += SPEED_INCREMENT
			Engine.iterations_per_second = ProjectSettings.get_setting(
					"physics/common/physics_fps") * Engine.time_scale
			AudioServer.global_rate_scale -=\
					SPEED_INCREMENT / AUDIO_SCALE_DIVISOR
	elif difficulty < DIFFICULTY_MAX and not (difficulty_lock or speed_lock):
		difficulty += 1

		speed = SPEED_MIN

		Engine.time_scale = 1
		Engine.iterations_per_second =\
				ProjectSettings.get_setting("physics/common/physics_fps")
		AudioServer.global_rate_scale = 1

	_next_nanogame()


func _lose_nanogame() -> void:
	emit_signal("nanogame_lost")

	if yield_nanogame_swapping:
		# warning-ignore:function_may_yield
		_yield = _yield_state()

		emit_signal("free_nanogame_yielded")

		if _yield != null and _yield.is_valid():
			yield(_yield, "completed")
		if not _is_playing:
			return

		# Give time to the previous `yield()` to disconnect.
		yield(get_tree(), "idle_frame")

	_free_nanogame()

	if not energy_lock:
		energy -= ENERGY_LOSS
		if energy < ENERGY_MIN:
			energy = ENERGY_MIN

	if not speed_lock:
		speed -= SPEED_LOSS
		if speed < SPEED_MIN:
			speed = SPEED_MIN

		var speed_adjusted: float = (speed - 1) * SPEED_INCREMENT
		Engine.time_scale = 1 + speed_adjusted
		Engine.iterations_per_second = ProjectSettings.get_setting(
				"physics/common/physics_fps") * Engine.time_scale
		AudioServer.global_rate_scale =\
				1 - speed_adjusted / AUDIO_SCALE_DIVISOR

	if energy == ENERGY_MIN:
		stop()
	else:
		_next_nanogame()


# Returns a `GDScriptFunctionState`, necessary to control the yield's state.
func _yield_state() -> void:
	yield()


func _on_Kickoff_timeout() -> void:
	set_process_unhandled_input(true)

	# warning-ignore:return_value_discarded
	_nanogame_scene.connect("ended", self, "_end_nanogame")

	if _nanogame_scene.has_method("nanogame_start"):
		_nanogame_scene.nanogame_start()

	if not timer_lock:
		_goal_timer.start()

	emit_signal("kickoff_ended")


func _on_Goal_timeout() -> void:
	_end_nanogame(_nanogame_timer == Nanogame.Timers.SURVIVAL)


# Adjusts the nanogame viewport to have the same resolution as the game's
# window, while making it obey the fixed height.
func _on_SceneTree_screen_resized() -> void:
	if _nanogame_viewport == null:
		return

	_nanogame_viewport.size = get_viewport().size
	if rect_size.y > 0:
		_nanogame_viewport.set_size_override(true, Vector2(rect_size.x *
				(VIEW_SIZE.y / rect_size.y), VIEW_SIZE.y))
