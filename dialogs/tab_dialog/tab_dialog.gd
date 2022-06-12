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

class_name TabDialog
extends PopupDialog


signal tab_changed(tab)

var _is_ignoring_theme_notification := false


func _ready() -> void:
	set_process_input(false)

	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_POST_POPUP:
			set_process_input(true)

			GameManager.dim = true
		NOTIFICATION_POPUP_HIDE:
			# Prevent switching tabs while hidden when using a joypad.
			set_process_input(false)

			if not get_viewport().gui_has_modal_stack():
				GameManager.dim = false
		NOTIFICATION_THEME_CHANGED:
			if not _is_ignoring_theme_notification:
				_is_ignoring_theme_notification = true

				add_stylebox_override(
						"panel", get_stylebox("panel", "TabDialog"))

				_is_ignoring_theme_notification = false


func _input(event: InputEvent) -> void:
	var tab_direction := 0
	if event.is_action_pressed("menu_tab_left"):
		tab_direction -= 1
	elif event.is_action_pressed("menu_tab_right"):
		tab_direction += 1

	if tab_direction == 0 or get_viewport().get_modal_stack_top() != self:
		return

	var tab_container := $VBoxContainer/TabContainer as TabContainer
	tab_container.current_tab = wrapi(tab_container.current_tab +
			tab_direction, 0, tab_container.get_tab_count())


func add_tab(tab_name: String, control: Control) -> void:
	var tab_container := $VBoxContainer/TabContainer as TabContainer
	tab_container.add_child(control)
	tab_container.set_tab_title(tab_container.get_child_count() - 1, tab_name)


func reset() -> void:
	($VBoxContainer/TabContainer as TabContainer).current_tab = 0


func _on_TabContainer_tab_changed(tab: int) -> void:
	if visible and ($VBoxContainer/Close as Button).is_inside_tree():
		($VBoxContainer/Close as Button).grab_focus()

	emit_signal("tab_changed", tab)


func _on_viewport_size_changed() -> void:
	if visible:
		# Keep the dialog centered on the screen.
		rect_position = (get_viewport_rect().size - rect_size) / 2
