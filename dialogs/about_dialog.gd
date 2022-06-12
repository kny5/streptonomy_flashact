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


const LIBRERAMA_LINK = "https://librerama.codeberg.page/"
const PERSONAL_WEBSITE_LINK = "https://yeldham.codeberg.page/"

const DONATE_LINK = "https://liberapay.com/Yeldham/donate"
const FREE_SOFTWARE_LINK = "https://www.gnu.org/philosophy/free-sw.html"

const GODOT_SOURCE_LINK = "https://github.com/godotengine/godot"
const FREETYPE_LICENSE_LINK = "https://git.savannah.gnu.org/cgit/" +\
		"freetype/freetype2.git/tree/docs/FTL.TXT"
const FREETYPE_SOURCE_LINK =\
		"https://git.savannah.gnu.org/cgit/freetype/freetype2.git/"
const NOTO_SOURCE_LINK = "https://github.com/googlefonts/noto-fonts"

var _about := RichTextLabel.new()
var _donate := RichTextLabel.new()
var _contributors := RichTextLabel.new()
var _thirdparty := RichTextLabel.new()


func _ready() -> void:
	### Tab Creation ###

	_about.bbcode_enabled = true
	_about.focus_mode = Control.FOCUS_ALL
	# translation-extract:"About"
	add_tab("About", _about)
	# warning-ignore:return_value_discarded
	_about.connect("meta_clicked", self, "_on_rich_text_label_meta_clicked")

	_donate.bbcode_enabled = true
	_donate.focus_mode = Control.FOCUS_ALL
	# translation-extract:"Donate"
	add_tab("Donate", _donate)
	# warning-ignore:return_value_discarded
	_donate.connect("meta_clicked", self, "_on_rich_text_label_meta_clicked")

	_contributors.bbcode_enabled = true
	_contributors.focus_mode = Control.FOCUS_ALL
	# translation-extract:"Contributors"
	add_tab("Contributors", _contributors)
	# warning-ignore:return_value_discarded
	_contributors.connect(
			"meta_clicked", self, "_on_rich_text_label_meta_clicked")

	_thirdparty.bbcode_enabled = true
	_thirdparty.focus_mode = Control.FOCUS_ALL
	# translation-extract:"Third-party"
	add_tab("Third-party", _thirdparty)
	# warning-ignore:return_value_discarded
	_thirdparty.connect(
			"meta_clicked", self, "_on_rich_text_label_meta_clicked")


	_update_texts()

	# warning-ignore:return_value_discarded
	connect("tab_changed", self, "_on_tab_changed")


func _notification(what: int) -> void:
	# Check if an tab is ready first, as this can trigger before it.
	if what == NOTIFICATION_TRANSLATION_CHANGED and _about != null:
		_update_texts()


func _update_texts() -> void:
	### About ###

	_about.clear()

	_about.push_align(RichTextLabel.ALIGN_CENTER)

	_about.push_bold()
	# warning-ignore:return_value_discarded
	_about.append_bbcode("[url=%s]Librerama[/url]" % LIBRERAMA_LINK)
	_about.pop()
	_about.add_text(" v" + GameManager.VERSION)
	_about.newline()

	_about.add_text("Copyright © 2022")
	_about.push_bold()
	# warning-ignore:return_value_discarded
	_about.append_bbcode(
			" [url=%s]Michael Alexsander[/url]" % PERSONAL_WEBSITE_LINK)
	_about.pop()
	_about.newline()

	_about.newline()

	_about.push_italics()
	# translation-extract:"
	#A free/libre fast-paced arcade collection of mini-games."
	_about.add_text(tr(
			"A free/libre fast-paced arcade collection of mini-games."))
	_about.pop()
	_about.newline()

	_about.pop()
	_about.newline()

	# translation-extract:"This program is [url=%s]free software[/url]:
	# you can redistribute it and/or modify it under the terms of
	# the [url=%s]GNU General Public License[/url] as published by
	# the Free Software Foundation, either version 3 of the License,
	# or (at your option) any later version."

	# warning-ignore:return_value_discarded
	_about.append_bbcode(tr("This program is [url=%s]free software[/url]: " +
			"you can redistribute it and/or modify it under the terms of " +
			"the [url=%s]GNU General Public License[/url] as published by " +
			"the Free Software Foundation, either version 3 of the License, " +
			"or (at your option) any later version.") % [
					FREE_SOFTWARE_LINK, Nanogame.get_license_link(
							Nanogame.Licenses.GPL_3_LATER)])
	_about.newline()

	_about.newline()

	# translation-extract:"
	#The source code and assets can be found in its [url=%s]
	#repository[/url]."

	# warning-ignore:return_value_discarded
	_about.append_bbcode(tr(
			"The source code and assets can be found in its [url=%s]" +
			"repository[/url].") % GameManager.REPOSITORY_LINK)


	### Donate ###

	_donate.clear()

	# translation-extract:"Librerama is not just free as in
	# [i]freedom[/i], but also free as in [i]free of charge[/i],
	# so donations are very much welcomed!"

	# warning-ignore:return_value_discarded
	_donate.append_bbcode(tr("Librerama is not just free as in " +
			"[i]freedom[/i], but also free as in [i]free of charge[/i], " +
			"so donations are very much welcomed!"))
	_donate.newline()

	_donate.newline()

	# translation-extract:"
	#You can donate to me via [url=%s]Liberapay[/url]. The money
	# will be used to help me put more work not just into this game,
	# but also my general work in free/libre gaming."

	# warning-ignore:return_value_discarded
	_donate.append_bbcode(tr(
			"You can donate to me via [url=%s]Liberapay[/url]. The money " +
			"will be used to help me put more work not just into this game, " +
			"but also my general work in free/libre gaming.") % DONATE_LINK)


	### Contributors ###

	_contributors.clear()

	# translation-extract:"
	#The wonderful people listed below offered sizable
	# contributions to the game. Make sure to check them out."
	_contributors.add_text(tr(
			"The wonderful people listed below offered sizable " +
			"contributions to the game. Make sure to check them out."))
	_contributors.newline()

	_contributors.newline()

	_contributors.push_align(RichTextLabel.ALIGN_CENTER)
	_contributors.push_bold()
	# translation-extract:"Music"
	_contributors.add_text(tr("Music"))
	_contributors.pop()
	_contributors.pop()
	_contributors.newline()

	# TODO: Implement checking of right-to-left languages.
	var bullet_point_colon := "• %s: "

	_contributors.push_bold()
	# warning-ignore:return_value_discarded
	_contributors.append_bbcode(bullet_point_colon %\
			"[url=https://www.francescorrado.com]Francesco Corrado[/url]")
	_contributors.pop()

	# translation-extract:"Arcade Menu Theme and Jingles"
	_contributors.add_text(tr("Arcade Menu Theme and Jingles"))
	_contributors.newline()

	_contributors.newline()

	_contributors.push_align(RichTextLabel.ALIGN_CENTER)
	_contributors.push_bold()
	# translation-extract:"Translation"
	_contributors.add_text(tr("Translation"))
	_contributors.pop()
	_contributors.pop()
	_contributors.newline()

	_contributors.push_bold()
	# warning-ignore:return_value_discarded
	_contributors.append_bbcode(bullet_point_colon %\
			("[url=https://github.com/HaSa1002]HaSa[/url], " + "Wuzzy"))
	_contributors.pop()

	# translation-extract:"German"
	_contributors.add_text(tr("German"))


	### Third-party ###

	_thirdparty.clear()

	# TODO: Implement checking of right-to-left languages.
	var bullet_point := "• %s"

	_thirdparty.push_bold()
	var engine_version: Dictionary = Engine.get_version_info()
	_thirdparty.add_text(bullet_point % "Godot Engine")
	_thirdparty.pop()
	_thirdparty.add_text(" v" + engine_version["string"])
	_thirdparty.newline()

	_thirdparty.push_indent(2)

	# translation-extract:"By %s"
	_thirdparty.add_text(tr("By %s") %
			"Juan Linietsky, Ariel Manzur, and Godot contributors")
	_thirdparty.newline()
	_thirdparty.push_meta(Nanogame.get_license_link(Nanogame.Licenses.MIT))
	_thirdparty.add_text(Nanogame.get_license_name(Nanogame.Licenses.MIT))
	_thirdparty.pop()
	_thirdparty.newline()
	_thirdparty.push_meta(GODOT_SOURCE_LINK)
	# translation-extract:"Source"
	_thirdparty.add_text(tr("Source"))
	_thirdparty.pop()
	_thirdparty.newline()

	_thirdparty.pop()
	_thirdparty.newline()

	_thirdparty.push_bold()
	# warning-ignore:return_value_discarded
	_thirdparty.add_text(bullet_point % "FreeType")
	_thirdparty.pop()
	_thirdparty.newline()

	_thirdparty.push_indent(2)

	# translation-extract:"By %s"
	_thirdparty.add_text(tr("By %s") % "FreeType Project")
	_thirdparty.newline()
	_thirdparty.push_meta(FREETYPE_LICENSE_LINK)
	_thirdparty.add_text("FTL")
	_thirdparty.pop()
	_thirdparty.newline()
	_thirdparty.push_meta(FREETYPE_SOURCE_LINK)
	# translation-extract:"Source"
	_thirdparty.add_text(tr("Source"))
	_thirdparty.pop()
	_thirdparty.newline()

	_thirdparty.pop()
	_thirdparty.newline()

	_thirdparty.push_bold()
	_thirdparty.add_text(bullet_point % "Noto Fonts")
	_thirdparty.pop()
	_thirdparty.newline()

	_thirdparty.push_indent(2)

	# translation-extract:"By %s"
	_thirdparty.add_text(tr("By %s") % "Google")
	_thirdparty.newline()
	_thirdparty.push_meta(Nanogame.get_license_link(Nanogame.Licenses.OFL))
	_thirdparty.add_text(Nanogame.get_license_name(Nanogame.Licenses.OFL))
	_thirdparty.pop()
	_thirdparty.newline()
	_thirdparty.push_meta(NOTO_SOURCE_LINK)
	# translation-extract:"Source"
	_thirdparty.add_text(tr("Source"))
	_thirdparty.pop()
	_thirdparty.newline()

	_thirdparty.pop()
	_thirdparty.newline()

	# translation-extract:'
	#For the licenses of the third-party
	# components used by the nanogames themselves, check their
	# respective "About" information.'
	_thirdparty.add_text(tr("For the licenses of the third-party " +\
			"components used by the nanogames themselves, check their " +\
			'respective "About" information.'))


func _on_tab_changed(tab: int) -> void:
	match tab:
		0:
			_about.grab_focus()
		1:
			_donate.grab_focus()
		2:
			_contributors.grab_focus()
		3:
			_thirdparty.grab_focus()


func _on_rich_text_label_meta_clicked(meta: String) -> void:
	# warning-ignore:return_value_discarded
	OS.shell_open(meta)
