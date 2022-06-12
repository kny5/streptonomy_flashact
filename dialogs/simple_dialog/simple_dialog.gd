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

class_name SimpleDialog
extends PopupDialog


signal ok_pressed

signal meta_clicked(meta)

export(String, MULTILINE) var bbcode_text setget set_bbcode_text

export var confirmation_mode := false setget set_confirmation_mode
export var ok_enabled := true setget set_ok_enabled

export var update_on_translation_change := true


func _ready() -> void:
	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_POST_POPUP:
			GameManager.dim = true
		NOTIFICATION_POPUP_HIDE:
			if not get_viewport().gui_has_modal_stack():
				GameManager.dim = false
		NOTIFICATION_TRANSLATION_CHANGED:
			if update_on_translation_change:
				($VBoxContainer/RichTextLabel as RichTextLabel).bbcode_text =\
						tr(bbcode_text)


func set_bbcode_text(text: String) -> void:
	bbcode_text = text

	($VBoxContainer/RichTextLabel as RichTextLabel).bbcode_text = text


func set_confirmation_mode(is_enabled: bool) -> void:
	confirmation_mode = is_enabled

	($VBoxContainer/HBoxContainer/Cancel as Button).visible = is_enabled
	($VBoxContainer/HBoxContainer/Space as Control).visible = is_enabled

	# translation-extract:"Close"
	# translation-extract:"OK"
	($VBoxContainer/HBoxContainer/CloseOK as Button).text =\
			"Close" if not is_enabled else "OK"
	($VBoxContainer/HBoxContainer/CloseOK as Button).disabled =\
				not ok_enabled if confirmation_mode else false


func set_ok_enabled(is_enabled: bool) -> void:
	ok_enabled = is_enabled

	if confirmation_mode:
		($VBoxContainer/HBoxContainer/CloseOK as Button).disabled =\
				not is_enabled


func _on_RichTextLabel_meta_clicked(meta) -> void:
	emit_signal("meta_clicked", meta)


func _on_CloseOK_pressed() -> void:
	if confirmation_mode:
		emit_signal("ok_pressed")

	hide()


func _on_viewport_size_changed() -> void:
	if visible:
		# Keep the dialog centered on the screen.
		rect_position = (get_viewport_rect().size - rect_size) / 2
