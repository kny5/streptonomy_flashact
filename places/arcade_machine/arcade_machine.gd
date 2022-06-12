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


const START_QUANTITY = 6

const SCORE_BASE = 100

const TWEEN_SPEED_TRANSITION = 0.25
const TWEEN_SPEED_INTERPOLATION = 2

const ICON_PARTICLES_COLUMN_MAX = 16
const ICON_PARTICLES_NANOGAME_MAX = ICON_PARTICLES_COLUMN_MAX * 2
const ICON_PARTICLES_AMOUNT_MAX = 12
const ICON_PARTICLES_AMOUNT_INCREASE =\
		ICON_PARTICLES_NANOGAME_MAX / ICON_PARTICLES_AMOUNT_MAX

const ISSUE_TRACKER_LINK = GameManager.REPOSITORY_LINK + "/issues"

const STYLE_FOCUS = preload("_resources/style_focus.tres")
const STYLE_FOCUS_JOYPAD = preload("_resources/style_focus_joypad.tres")

var _was_nanogame_won := false

var _time_left := 0.0

var _score := 0

var _was_paused := false
var _was_player_error := false

var _is_player_starting := false

var _button_focus_last: Control

var _has_joypad := false
var _joycursor_position_old := Vector2()

onready var _nanogame_player := $NanogamePlayer as NanogamePlayer
onready var _nanogame_hud := $NanogameHUD as Control


func _ready() -> void:
	set_process(false)

	_notification(NOTIFICATION_THEME_CHANGED)

	_set_tickets_label(ArcadeManager.tickets)

	($MainMenu/Main/Play as Button).grab_focus()

	if ArcadeManager.community_mode:
		($CommunityMode as CheckButton).pressed = true

	($SubmenuContext/Submenus/NanogameSelection as Control).set_start_quantity(
			START_QUANTITY)

	($Tickets/Quantity as Label).text = str(ArcadeManager.tickets)

	_update_play_styleboxes()

	if ArcadeManager.is_statistics_highlighted():
		# warning-ignore:return_value_discarded
		($MainMenu/Main/Statistics as Button).connect("pressed", self,
				"_update_statistics_styleboxes", [true], CONNECT_ONESHOT)

	# warning-ignore:return_value_discarded
	GameManager.connect("dim_changed", $MenuNoise as AudioStreamPlayer, "play")

	# warning-ignore:return_value_discarded
	GameManager.connect("control_type_changed", self,
			"_on_GameManager_control_type_changed")
	_on_GameManager_control_type_changed()

	# TODO: Remove/move all of the below once the proper arcade is made.

	AudioServer.set_bus_volume_db(0, linear2db(0))
	GameManager.fade_out()

	if OS.has_feature("web"):
		($MainMenu/Exit as Button).hide()

	if not OS.is_userfs_persistent():
		var cannot_save := $CannotSave as SimpleDialog
		# translation-extract:"The user data directory is non-persistent,
		# this means that [b]saving data will not be possible[/b]."
		cannot_save.bbcode_text = tr(
				"The user data directory is non-persistent, " +\
				"this means that [b]saving data will not be possible[/b].")

		if OS.has_feature("web"):
			# translation-extract:"
			#Make sure that you have third-party cookies enabled
			# and that you're not in privacy mode."
			cannot_save.bbcode_text += "\n\n" + tr(
					"Make sure that you have third-party cookies enabled " +\
					"and that you're not in privacy mode.")

		cannot_save.popup_centered()

	($WIPWarning as SimpleDialog).popup_centered()

	# Prevent first particles abruptly vanishing.
	yield(get_tree().create_timer(0.2), "timeout")
	_update_icon_particles()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED:
			if _nanogame_player.is_playing():
				($MenuNoise as AudioStreamPlayer).play()
		NOTIFICATION_WM_FOCUS_OUT:
			if _nanogame_player.is_playing() and ProjectSettings.get_setting(
					"game_settings/pause_focus_lost"):
				get_tree().paused = true
		NOTIFICATION_THEME_CHANGED:
			if ArcadeManager.has_highlighted_owned_nanogames():
				_update_play_styleboxes()
			if ArcadeManager.is_statistics_highlighted():
				_update_statistics_styleboxes()

			var start := $SubmenuContext/TopBar/Start as Button
			start.add_stylebox_override(
					"normal", get_stylebox("normal", "ButtonPositive"))
			start.add_stylebox_override(
					"hover", get_stylebox("hover", "ButtonPositive"))
			start.add_stylebox_override(
					"pressed", get_stylebox("pressed", "ButtonPositive"))
			start.add_stylebox_override(
					"disabled", get_stylebox("disabled", "ButtonPositive"))

			var exit := $MainMenu/Exit as Button
			exit.add_stylebox_override(
					"normal", get_stylebox("normal", "ButtonNegative"))
			exit.add_stylebox_override(
					"hover", get_stylebox("hover", "ButtonNegative"))
			exit.add_stylebox_override(
					"pressed", get_stylebox("pressed", "ButtonNegative"))


func _input(event: InputEvent) -> void:
	if get_viewport().gui_has_modal_stack():
		return

	if event.is_action_pressed("menu_back") and\
			not _nanogame_player.is_playing():
		_hide_submenu()
	elif event.is_action_pressed("pause") and _nanogame_player.is_playing():
		get_tree().paused = not get_tree().paused


func _process(_delta: float) -> void:
	var time_adjusted: float = stepify(_nanogame_player.get_time(), 0.1)
	if _time_left != time_adjusted:
		_time_left = time_adjusted

		_nanogame_hud.set_time(time_adjusted)

	if not _has_joypad:
		return

	var joycursor_position = _nanogame_player.get_joycursor_position()
	if _joycursor_position_old != joycursor_position:
		_joycursor_position_old = joycursor_position

		_nanogame_hud.set_joycursor_position(joycursor_position)


func _show_submenu(index: int, title: String, is_showing_start: bool) -> void:
	_button_focus_last = get_focus_owner()

	($IconParticles as Control).hide()
	($MainMenu as VBoxContainer).hide()
	($Tickets as HBoxContainer).hide()
	($CommunityMode as CheckButton).hide()

	($SubmenuContext/TopBar/Back as Button).grab_focus()
	($SubmenuContext/TopBar/Title as Label).text = title
	($SubmenuContext/TopBar/Start as Button).self_modulate.a =\
			float(is_showing_start)
	# Make it ignore the mouse so the tooltip doesn't appear on hover.
	($SubmenuContext/TopBar/Start as Button).mouse_filter =\
			MOUSE_FILTER_STOP if is_showing_start else MOUSE_FILTER_IGNORE

	($SubmenuContext/Submenus as TabContainer).current_tab = index

	($SubmenuContext as VBoxContainer).show()

	($MenuNoise as AudioStreamPlayer).play()


func _hide_submenu(is_hiding_main_menu := false) -> void:
	if _is_player_starting or not ($SubmenuContext as VBoxContainer).visible:
		return

	($IconParticles as Control).show()

	($SubmenuContext as VBoxContainer).hide()

	($SubmenuContext/TopBar/Start as Button).disabled = true

	if is_hiding_main_menu:
		return

	($MainMenu as VBoxContainer).show()
	($Tickets as HBoxContainer).show()
	($CommunityMode as CheckButton).show()

	if _button_focus_last != null:
		_button_focus_last.grab_focus()

	($MenuNoise as AudioStreamPlayer).play()


func _update_play_styleboxes() -> void:
	var is_highlighted: bool = not ArcadeManager.community_mode and\
			ArcadeManager.has_highlighted_owned_nanogames()
	var play := $MainMenu/Main/Play as Button
	play.add_stylebox_override(
			"normal", get_stylebox("normal", "ButtonPositive"
			if not is_highlighted else "ButtonHighlight"))
	play.add_stylebox_override("hover", get_stylebox("hover", "ButtonPositive"
			if not is_highlighted else "ButtonHighlight"))
	play.add_stylebox_override(
			"pressed", get_stylebox("pressed", "ButtonPositive"
			if not is_highlighted else "ButtonHighlight"))


func _update_statistics_styleboxes(is_clearing := false) -> void:
	var is_highlighted: bool =\
			ArcadeManager.is_statistics_highlighted() and not is_clearing
	var statistics_button := $MainMenu/Main/Statistics as Button
	statistics_button.add_stylebox_override(
			"normal", get_stylebox("normal", "ButtonHighlight")
			if is_highlighted else null)
	statistics_button.add_stylebox_override(
			"hover", get_stylebox("hover", "ButtonHighlight")
			if is_highlighted else null)
	statistics_button.add_stylebox_override(
			"pressed", get_stylebox("pressed", "ButtonHighlight")
			if is_highlighted else null)


func _update_icon_particles() -> void:
	var particles_left := $IconParticles/Left as Particles2D
	particles_left.hide() # Prevent the particles from flickering.
	particles_left.restart()
	particles_left.show()
	var particles_right := $IconParticles/Anchor/Right as Particles2D
	particles_right.hide() # Same as above.
	particles_right.restart()
	particles_right.show()

	var nanogames: Array = ArcadeManager.get_owned_official_nanogames()\
			if not ArcadeManager.community_mode else\
			ArcadeManager.get_community_nanogames()

	if nanogames.empty():
		particles_left.emitting = false
		particles_right.emitting = false

		return

	var nanogames_size_max :=\
			int(min(nanogames.size(), ICON_PARTICLES_NANOGAME_MAX))
	if nanogames_size_max > 1 and\
			(nanogames_size_max % 2 != 0 or nanogames_size_max % 3 != 0):
		nanogames_size_max -= 1

	var rows: int
	var columns: int
	if nanogames_size_max <= ICON_PARTICLES_COLUMN_MAX:
		rows = 1
		columns = nanogames_size_max
	else:
		rows = 2 if nanogames_size_max % 2 == 0 else 3
		# warning-ignore:integer_division
		columns = nanogames_size_max / rows

	var sheet_texture := ImageTexture.new()
	var sheet_image := Image.new()
	# warning-ignore:narrowing_conversion
	# warning-ignore:narrowing_conversion
	sheet_image.create(Nanogame.ICON_SIZE.x * columns,
			Nanogame.ICON_SIZE.y * rows, false, Image.FORMAT_RGBA8)

	var offset := Vector2()
	var sheet_width_limit :=\
			int(Nanogame.ICON_SIZE.x * columns - Nanogame.ICON_SIZE.x)
	for i in nanogames_size_max:
		var icon: Image = (nanogames[i].get_icon()
				if nanogames[i].get_icon() != null else
				preload("_assets/unknown.svg")).get_data()
		sheet_image.blit_rect(
				icon, Rect2(Vector2(), Nanogame.ICON_SIZE), offset)

		if offset.x < sheet_width_limit:
			offset.x += Nanogame.ICON_SIZE.x
		else:
			offset.x = 0
			offset.y += Nanogame.ICON_SIZE.y

	sheet_texture.create_from_image(sheet_image)

	particles_left.texture = sheet_texture
	particles_left.material.particles_anim_h_frames = columns
	particles_left.material.particles_anim_v_frames = rows
	# warning-ignore:integer_division
	particles_left.amount =\
			int(max(1, nanogames_size_max / ICON_PARTICLES_AMOUNT_INCREASE))
	particles_left.emitting = true
	particles_right.texture = sheet_texture
	particles_right.amount = particles_left.amount
	particles_right.emitting = true


func _set_tickets_label(quantity: int) -> void:
	($Tickets/Quantity as Label).text = str(quantity)


func _on_NanogamePlayer_stopped() -> void:
	_nanogame_player.clear_nanogames()

	if not _was_nanogame_won:
		_nanogame_hud.set_energy(NanogamePlayer.ENERGY_MIN)

	if not _was_player_error:
		yield(_nanogame_hud, "gates_changed")
	($Background as TextureRect).show()
	($IconParticles as Control).show()
	($MainMenu as VBoxContainer).show()
	($Tickets as HBoxContainer).show()
	($CommunityMode as CheckButton).show()

	if _button_focus_last != null:
		_button_focus_last.grab_focus()

	($Music as AudioStreamPlayer).play()

	if _was_player_error:
		_was_player_error = false

		_nanogame_hud.force_clear()

	if _nanogame_hud.practice_mode:
		yield(_nanogame_hud, "animation_finished")

		_nanogame_player.energy_lock = false
		_nanogame_hud.practice_mode = false

		return

	if ArcadeManager.has_highlighted_owned_nanogames():
		($SubmenuContext/Submenus/NanogameSelection as Control).\
				clear_selected_highlight()

		_update_play_styleboxes()

	if not ArcadeManager.community_mode:
		# warning-ignore:integer_division
		ArcadeManager.tickets += _score / SCORE_BASE

	if _score > 0:
		ArcadeManager.claim_best_score(_score)
	ArcadeManager.break_win_streak()

	ArcadeManager.save_data()

	var statistics := $SubmenuContext/Submenus/Statistics as Control
	statistics.update_played_nanogames()

	if ArcadeManager.is_statistics_highlighted() and\
			not ($MainMenu/Main/Statistics as Button).is_connected(
					"pressed", self, "_update_statistics_styleboxes"):
		_update_statistics_styleboxes()

		# warning-ignore:return_value_discarded
		($MainMenu/Main/Statistics as Button).connect("pressed", self,
				"_update_statistics_styleboxes", [true], CONNECT_ONESHOT)

	_score = 0

	if ArcadeManager.community_mode:
		return

	var tickets_old := int(($Tickets/Quantity as Label).text)
	if ArcadeManager.tickets == tickets_old:
		return

	yield(_nanogame_hud, "animation_finished")
	var tween := $Tween as Tween

	# warning-ignore:return_value_discarded
	tween.interpolate_property($Tickets/Icon as TextureRect, "self_modulate",
			ColorN("white"), ColorN("limegreen"), TWEEN_SPEED_TRANSITION)
	# warning-ignore:return_value_discarded
	tween.interpolate_property($Tickets/Icon as TextureRect, "self_modulate",
			ColorN("limegreen"), ColorN("white"), TWEEN_SPEED_TRANSITION,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT,
			TWEEN_SPEED_INTERPOLATION + TWEEN_SPEED_TRANSITION)

	# warning-ignore:return_value_discarded
	tween.interpolate_method(self, "_set_tickets_label", tickets_old,
			ArcadeManager.tickets, TWEEN_SPEED_INTERPOLATION,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, TWEEN_SPEED_TRANSITION)

	var gain := $Tickets/Quantity/Gain as Label
	gain.text = "+ " + str(ArcadeManager.tickets - tickets_old)
	# warning-ignore:return_value_discarded
	tween.interpolate_property(
			gain, "self_modulate:a", 0, 1, TWEEN_SPEED_TRANSITION)
	# warning-ignore:return_value_discarded
	tween.interpolate_property(gain, "self_modulate:a", 1, 0,
			TWEEN_SPEED_TRANSITION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT,
			TWEEN_SPEED_INTERPOLATION + TWEEN_SPEED_TRANSITION)

	# warning-ignore:return_value_discarded
	tween.start()


func _on_NanogamePlayer_nanogame_won() -> void:
	_was_nanogame_won = true

	if not _nanogame_hud.practice_mode:
		ArcadeManager.add_nanogame_win()


func _on_NanogamePlayer_nanogame_lost() -> void:
	_was_nanogame_won = false

	if not _nanogame_hud.practice_mode:
		ArcadeManager.add_nanogame_loss()


func _on_NanogamePlayer_next_nanogame_yielded() -> void:
	_nanogame_hud.set_difficulty(_nanogame_player.difficulty)
	_nanogame_hud.set_speed(_nanogame_player.speed)
	if not _nanogame_hud.practice_mode:
		_nanogame_hud.set_energy(_nanogame_player.energy)
		_nanogame_hud.set_score(_score)

	_joycursor_position_old = _nanogame_player.get_joycursor_position()
	_nanogame_hud.set_joycursor_position(_joycursor_position_old)

	# Avoid clashing with the player starting animation.
	if _is_player_starting:
		return

	yield(_nanogame_hud, "gates_changed")
	# Check if still playing, in case the player is stopped before the gates
	# actually change.
	if _nanogame_player.is_playing():
		_nanogame_hud.set_time(_nanogame_player.get_time())

		_nanogame_player.resume_yield()


func _on_NanogamePlayer_free_nanogame_yielded() -> void:
	if _was_nanogame_won:
		if not _nanogame_hud.practice_mode:
			_score += SCORE_BASE * _nanogame_player.difficulty *\
					_nanogame_player.speed

		_nanogame_hud.animate_nanogame_won(_nanogame_player.get_next_nanogame(),
				_nanogame_player.speed == NanogamePlayer.SPEED_MAX and\
				_nanogame_player.difficulty != NanogamePlayer.DIFFICULTY_MAX)
	else:
		_nanogame_hud.animate_nanogame_lost(_nanogame_player.get_next_nanogame()
				if _nanogame_player.energy - NanogamePlayer.ENERGY_LOSS > 0
				else null)

	yield(_nanogame_hud, "gates_changed")
	# Check if still playing, in case the player is stopped before the gates
	# actually change.
	if _nanogame_player.is_playing():
		_nanogame_player.resume_yield()


func _on_NanogamePlayer_error_occured() -> void:
	_was_player_error = true

	var _nanogame_error := $NanogameError as SimpleDialog
	# translation-extract:'
	#An error occured while atempting to load the nanogame "%s",
	# likely caused by it not being properly configured.'
	_nanogame_error.bbcode_text = tr(
			'An error occured while atempting to load the nanogame "%s", ' +
			"likely caused by it not being properly configured.") %\
			_nanogame_player.get_current_nanogame().get_name(true)

	if not ArcadeManager.community_mode:
		# translation-extract:"\n\nPlease open a bug report in
		# the [url=%s]issue tracker[/url]."
		_nanogame_error.bbcode_text += tr("\n\nPlease open a bug report in " +
				"the [url=%s]issue tracker[/url].") % ISSUE_TRACKER_LINK
	else:
		# translation-extract:'\n\n[b]Do not open a bug report
		# in the issue tracker[/b], this is a community nanogame,
		# so the bug should be reported to its creator(s).
		# Check the nanogame's "About" information.'
		_nanogame_error.bbcode_text += tr("\n\n[b]Do not open a bug report " +
				"in the issue tracker[/b], this is a community nanogame, " +
				"so the bug should be reported to its creator(s). " +
				'Check the nanogame\'s "About" information.')

	_nanogame_error.popup_centered()


func _on_Exit_pressed() -> void:
	GameManager.fade_in()

	yield(GameManager, "faded_in")
	get_tree().quit()


func _on_Start_pressed() -> void:
	_is_player_starting = true

	_nanogame_player.add_nanogames(($SubmenuContext/Submenus as TabContainer).\
			get_current_tab_control().get_nanogames_selected())
	_nanogame_player.start()

	_nanogame_hud.animate_player_start(_nanogame_player.get_current_nanogame())

	yield(_nanogame_hud, "gates_changed")

	_is_player_starting = false

	_hide_submenu(true)

	# Check if still playing at every stage, in case the player is stopped
	# between animation changes.
	if not _nanogame_player.is_playing():
		return

	($Background as TextureRect).hide()
	($IconParticles as Control).hide()
	($Music as AudioStreamPlayer).stop()

	yield(_nanogame_hud, "animation_finished")
	if not _nanogame_player.is_playing():
		return

	_nanogame_hud.animate_nanogame_start(
			_nanogame_player.get_current_nanogame())

	yield(_nanogame_hud, "gates_changed")
	if _nanogame_player.is_playing():
		_nanogame_hud.set_time(_nanogame_player.get_time())

		_nanogame_player.resume_yield()


func _on_NanogameSelection_practice_mode_started(
		nanogame: Nanogame, difficulty: int) -> void:
	_is_player_starting = true

	_nanogame_player.difficulty = difficulty
	_nanogame_player.energy_lock = true
	_nanogame_player.add_nanogames([nanogame])
	_nanogame_player.start()

	_nanogame_hud.practice_mode = true
	_nanogame_hud.animate_player_start(nanogame)

	yield(_nanogame_hud, "gates_changed")

	_nanogame_hud.update_status_labels()

	_is_player_starting = false

	_hide_submenu(true)

	# Check if still playing at every stage, in case the player is stopped
	# between animation changes.
	if not _nanogame_player.is_playing():
		return

	($Background as TextureRect).hide()
	($IconParticles as Control).hide()
	($Music as AudioStreamPlayer).stop()

	yield(_nanogame_hud, "animation_finished")
	if not _nanogame_player.is_playing():
		return

	_nanogame_hud.animate_nanogame_start(nanogame)

	yield(_nanogame_hud, "gates_changed")
	if _nanogame_player.is_playing():
		_nanogame_hud.set_time(_nanogame_player.get_time())

		_nanogame_player.resume_yield()


func _on_CommunityMode_toggled(is_enabled: bool) -> void:
	if is_enabled and ProjectSettings.get_setting(
			"game_settings/show_community_warning"):
		($CommunityWarning as SimpleDialog).popup_centered()

	ArcadeManager.community_mode = is_enabled
	ArcadeManager.save_data()

	if ArcadeManager.has_highlighted_owned_nanogames():
		_update_play_styleboxes()

	### Icon Particles Switch Fade ###

	var tween := $Tween as Tween
	# warning-ignore:return_value_discarded
	tween.stop_all()
	# warning-ignore:return_value_discarded
	tween.interpolate_property($IconParticles as Control, "modulate:a",
			($IconParticles as Control).modulate.a, 0, TWEEN_SPEED_TRANSITION)
	# warning-ignore:return_value_discarded
	tween.interpolate_callback(
			self, TWEEN_SPEED_TRANSITION, "_update_icon_particles")
	# warning-ignore:return_value_discarded
	tween.interpolate_callback($IconParticles as Control,
			TWEEN_SPEED_TRANSITION, "set_modulate", ColorN("white"))
	# warning-ignore:return_value_discarded
	tween.start()


func _on_NanogameError_meta_clicked(meta: String) -> void:
	# warning-ignore:return_value_discarded
	OS.shell_open(meta)


func _on_GameManager_control_type_changed() -> void:
	if GameManager.is_using_joypad():
		theme.set_stylebox("focus", "Button", STYLE_FOCUS_JOYPAD)
		theme.set_stylebox("focus", "LineEdit", STYLE_FOCUS_JOYPAD)
		theme.set_stylebox("focus", "RichTextLabel", STYLE_FOCUS_JOYPAD)
	else:
		var style_empty := StyleBoxEmpty.new()

		if not OS.has_feature("mobile"):
			theme.set_stylebox("focus", "Button", STYLE_FOCUS)
		else:
			theme.set_stylebox("focus", "Button", style_empty)

		# Use the empty style, as the blinking caret is enough to indicate that
		# it's focused.
		theme.set_stylebox("focus", "LineEdit", style_empty)

		theme.set_stylebox("focus", "RichTextLabel", style_empty)

	# Enable the joycursor only if the control type is joypad-only (without a
	# touchscreen available).
	_nanogame_player.joycursor_enabled =\
			GameManager.get_control_type() == GameManager.ControlTypes.JOYPAD
