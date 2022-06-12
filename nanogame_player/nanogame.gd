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

class_name Nanogame
extends Resource


enum Inputs {
	NAVIGATION,
	ACTION,
	NAVIGATION_ACTION,
	DRAG_DROP,
}

enum InputModifiers {
	NONE,
	HORIZONTAL,
	VERTICAL,
}

enum Timers {
	OBJECTIVE,
	SURVIVAL,
}

enum Licenses {
	UNKNOWN,

	MIT,
	BSD_2,
	BSD_3,
	APACHE_2,
	MPL_2,
	MPL_2_NO_DERIVATIVES,
	GPL_2_ONLY,
	GPL_2_LATER,
	GPL_3_ONLY,
	GPL_3_LATER,
	LGPL_2_1_ONLY,
	LGPL_2_1_LATER,
	LGPL_3_ONLY,
	LGPL_3_LATER,
	AGPL_3_ONLY,
	AGPL_3_LATER,

	CC0,
	CC_BY_3,
	CC_BY_SA_3,
	CC_BY_4,
	CC_BY_SA_4,

	OFL,

	PUBLIC_DOMAIN,

	NON_FREE,
}

const ICON_SIZE = Vector2(128, 128)

var _has_data := false

var _is_official := false

var _name := ""
var _kickoff := ""
var _description := ""
var _author := ""
var _input: int = Inputs.NAVIGATION
var _input_modifier: int = InputModifiers.NONE
var _timer: int = Timers.OBJECTIVE
var _tags := ""
var _license_code: int = Licenses.UNKNOWN
var _license_assets: int = Licenses.UNKNOWN
var _source := ""
var _third_party := []
var _path := ""
var _translations := {}
var _directory_path := ""
var _icon: StreamTexture
var _scene: PackedScene


func _init() -> void:
	resource_name = "Nanogame"


func load_data(path: String, is_official:=false) -> int:
	if _has_data:
		resource_name = "Nanogame"

	var file := File.new()
	var error_code: int = file.open(path.plus_file("nanogame.json"), File.READ)
	if error_code != OK:
		push_error('Unable to load nanogame data at path "' + path +
				'". Error code: ' + str(error_code))

		return error_code

	var info_text: String = file.get_as_text()
	file.close()

	### File Validation ###

	if not validate_json(info_text).empty():
		push_error('Unable to load nanogame data at path "' + path +
				"\". Nanogame file doesn't contain valid JSON.")

		return ERR_PARSE_ERROR
	var info_json = parse_json(info_text)
	if not info_json is Dictionary:
		push_error('Unable to load nanogame data at path "' + path +
				"\". JSON contents aren't in a dictionary format.")

		return ERR_INVALID_DATA

	if not file.file_exists(path.plus_file("main.tscn")):
		push_error('Unable to load nanogame data at path "' + path +
				'". Main scene file is missing.')

		return ERR_FILE_NOT_FOUND

	var nanogame_scene = load(path.plus_file("main.tscn"))
	if nanogame_scene == null:
		push_error('Unable to load nanogame data at path "' + path +
				'". Unable to load main scene file.')

		return ERR_FILE_CANT_OPEN
	if not nanogame_scene is PackedScene:
		push_error('Unable to load nanogame data at path "' + path +
				"\". Main scene file doesn't contain a valid scene.")

		return ERR_INVALID_DATA


	_scene = nanogame_scene
	_path = path

	### Information Extraction ###

	var has_icon := false
	var icon: StreamTexture
	if file.file_exists(path.plus_file("icon.png.import")):
		has_icon = true

		icon = load(path.plus_file("icon.png"))
	elif file.file_exists(path.plus_file("icon.svg.import")):
		has_icon = true

		icon = load(path.plus_file("icon.svg"))

	if has_icon:
		if icon == null:
			push_error('Unable to load icon file for nanogame at path "' +
					path + '".')
		else:
			if icon.get_size() != ICON_SIZE:
				_icon = null

				push_error('Unable to load icon file for nanogame at path "' +
					path + '". Image size resolution must be "' +
					str(ICON_SIZE.x) + "x" + str(ICON_SIZE.y) + '".')
			else:
				_icon = icon

	if not _validate_key(info_json, "name", TYPE_STRING) or\
			not _validate_key(info_json, "kickoff", TYPE_STRING) or\
			not _validate_key(info_json, "description", TYPE_STRING) or\
			not _validate_key(info_json, "author", TYPE_STRING) or\
			not _validate_key(info_json, "input", TYPE_STRING, Inputs) or\
			not _validate_key(info_json, "inputModifier", TYPE_STRING,
					InputModifiers) or\
			not _validate_key(info_json, "timer", TYPE_STRING, Timers) or\
			not _validate_key(info_json, "tags", TYPE_STRING) or\
			not _validate_key(
					info_json, "licenseCode", TYPE_STRING, Licenses) or\
			not _validate_key(
					info_json, "licenseAssets", TYPE_STRING, Licenses) or\
			not _validate_key(info_json, "source", TYPE_STRING):
		push_error('Unable to load nanogame data at path "' + path +
				"\". Nanogame file doesn't have all properties necessary, " +
				"or their values are incorrect.")

		return ERR_INVALID_PARAMETER

	_name = info_json["name"]
	_kickoff = info_json["kickoff"]
	_description = info_json["description"]
	_author = info_json["author"]
	_input = Inputs.get(info_json["input"])
	_input_modifier = InputModifiers.get(info_json["inputModifier"])
	_timer = Timers.get(info_json["timer"])
	_tags = info_json["tags"]
	_license_code = Licenses.get(info_json["licenseCode"])
	_license_assets = Licenses.get(info_json["licenseAssets"])
	_source = info_json["source"]


	resource_name += ": " + _name

	_is_official = is_official

	if _has_data:
		# Clear the previous data.
		_third_party.clear()
		_translations.clear()
	else:
		_has_data = true

	### Thirdparty Assets ###

	if info_json.has("thirdParty") and info_json["thirdParty"] is Array:
		for i in info_json["thirdParty"]:
			if not i is Dictionary:
				continue

			if not _validate_key(i, "name", TYPE_STRING) or\
					not _validate_key(i, "author", TYPE_STRING) or\
					not _validate_key(i, "license", TYPE_STRING, Licenses) or\
					not _validate_key(i, "source", TYPE_STRING):
				push_error("Invalid third-party information in nanogame " +
						'file at path "' + path + '". ' +
						"It either doesn't have all properties necessary, " +
						"or their values are incorrect.")

				continue

			_third_party.append({
				"name": i["name"],
				"author": i["author"],
				"license": Licenses.get(i["license"]),
				"source": i["source"],
			})


	### Translations ###

	if not is_official:
		var directory := Directory.new()
		# warning-ignore:return_value_discarded
		directory.open(path.plus_file("translations"))
		# warning-ignore:return_value_discarded
		directory.list_dir_begin(true, true)
		var file_name: String = directory.get_next()
		while not file_name.empty():
			if file_name.get_extension() == "po" or\
					file_name.get_extension() == "translation":
				var translation = load(
						path.plus_file("translations/" + file_name))
				if translation is Translation and not TranslationServer.\
						get_locale_name(translation.get_locale()).empty():
					_translations[translation.locale] = translation
				else:
					push_error('Unable to load translation file "' +
							file_name + '" of nanogame at path "' + path +
							'".')

			file_name = directory.get_next()

		directory.list_dir_end()


	_directory_path = path

	return OK


func has_data() -> bool:
	return _has_data


func is_official() -> bool:
	return _is_official


func get_name(is_translated:=false) -> String:
	if not is_official() and is_translated and\
			get_current_translation() != null:
		var translation: String =\
				get_current_translation().get_message(_name)
		if not translation.empty():
			return translation

	return _name if not is_translated else tr(_name)


func get_kickoff(is_translated:=false) -> String:
	if not is_official() and is_translated and\
			get_current_translation() != null:
		var translation: String =\
				get_current_translation().get_message(_kickoff)
		if not translation.empty():
			return translation

	return _kickoff if not is_translated else tr(_kickoff)


func get_description(is_translated:=false) -> String:
	if not is_official() and is_translated and\
			get_current_translation() != null:
		var translation: String =\
				get_current_translation().get_message(_description)
		if not translation.empty():
			return translation

	return _description if not is_translated else tr(_description)


func get_author() -> String:
	return _author


func get_input() -> int:
	return _input


func get_input_modifier() -> int:
	return _input_modifier


func get_timer() -> int:
	return _timer


func get_tags(is_translated:=false) -> String:
	if not is_translated:
		return _tags

	var tags := Array(_tags.split(","))
	var tags_translated := []

	var is_translation_internal: bool =\
			is_official() or get_current_translation() == null
	var current_translation: Translation
	if not is_translation_internal:
		current_translation = get_current_translation()

	for i in tags:
		var tag: String = tr(i) if is_translation_internal\
				else current_translation.get_message(i)
		# Check for repeats, as different tags can have the same translation
		# depending on the language.
		if not tags_translated.has(tag):
			tags_translated.append(tag)

	tags_translated.sort()

	# translation-extract:"%s, %s"
	var translation: String =\
			str(tags_translated).replace(", ", tr("%s, %s").replace("%s", ""))

	translation.erase(0, 1)
	translation.erase(translation.length() - 1, 1)

	return translation


func get_license_code() -> int:
	return _license_code


func get_license_assets() -> int:
	return _license_assets


func get_source() -> String:
	return _source


func get_thirdparty() -> Array:
	return _third_party.duplicate(true)


func get_path() -> String:
	return _path


func get_scene() -> PackedScene:
	return _scene


func get_icon() -> StreamTexture:
	return _icon


func get_translations() -> Dictionary:
	return _translations.duplicate()


func get_current_translation() -> Translation:
	if _is_official:
		return null

	var locale: String = TranslationServer.get_locale()
	if not _translations.keys().has(locale):
		var locale_bits: PoolStringArray = locale.split("_")
		if not locale_bits.empty() and\
				_translations.keys().has(locale_bits[0]):
			return _translations[locale_bits[0]]

		return null

	return _translations[locale]


func get_directory_path() -> String:
	return _directory_path


static func get_input_name(input: int) -> String:
	match input:
		Inputs.NAVIGATION:
			# translation-extract:"Navigation"
			return "Navigation"
		Inputs.ACTION:
			# translation-extract:"Action"
			return "Action"
		Inputs.NAVIGATION_ACTION:
			# translation-extract:"Navigation and Action"
			return "Navigation and Action"
		Inputs.DRAG_DROP:
			# translation-extract:"Drag and Drop"
			return "Drag and Drop"
		_:
			return ""


static func get_timer_name(timer: int) -> String:
	match timer:
		Timers.OBJECTIVE:
			# translation-extract:"Objective"
			return "Objective"
		Timers.SURVIVAL:
			# translation-extract:"Survival"
			return "Survival"
		_:
			return ""


static func get_license_name(license: int) -> String:
	match license:
		Licenses.UNKNOWN:
			# translation-extract:"Unknown"
			return "Unknown"

		Licenses.MIT:
			return "MIT"
		Licenses.BSD_2:
			return "BSD 2-Clause"
		Licenses.BSD_3:
			return "BSD 3-Clause"
		Licenses.APACHE_2:
			return "Apache 2.0"
		Licenses.MPL_2:
			return "MPL-2.0"
		Licenses.MPL_2_NO_DERIVATIVES:
			return "MPL-2.0 (No Derivatives)"
		Licenses.GPL_2_ONLY:
			return "GPLv2 Only"
		Licenses.GPL_2_LATER:
			return "GPLv2 or Later"
		Licenses.GPL_3_ONLY:
			return "GPLv3 Only"
		Licenses.GPL_3_LATER:
			return "GPLv3 or Later"
		Licenses.LGPL_2_1_ONLY:
			return "LGPLv2.1 Only"
		Licenses.LGPL_2_1_LATER:
			return "LGPLv2.1 or Later"
		Licenses.LGPL_3_ONLY:
			return "LGPLv3 Only"
		Licenses.LGPL_3_LATER:
			return "LGPLv3 or Later"
		Licenses.AGPL_3_ONLY:
			return "AGPLv3 Only"
		Licenses.AGPL_3_LATER:
			return "AGPLv3 or Later"

		Licenses.CC0:
			return "CC0"
		Licenses.CC_BY_3:
			return "CC BY 3.0"
		Licenses.CC_BY_SA_3:
			return "CC BY-SA 3.0"
		Licenses.CC_BY_4:
			return "CC BY 4.0"
		Licenses.CC_BY_SA_4:
			return "CC BY-SA 4.0"

		Licenses.OFL:
			return "OFL"

		# translation-extract:"Public Domain"
		Licenses.PUBLIC_DOMAIN:
			return "Public Domain"

		# translation-extract:"Non-Free"
		Licenses.NON_FREE:
			return "Non-Free"

		_:
			return ""


static func get_license_link(license: int) -> String:
	match license:
		Licenses.MIT:
			return "https://opensource.org/licenses/MIT"
		Licenses.BSD_2:
			return "https://opensource.org/licenses/BSD-2-Clause"
		Licenses.BSD_3:
			return "https://opensource.org/licenses/BSD-3-Clause"
		Licenses.APACHE_2:
			return "https://www.apache.org/licenses/LICENSE-2.0.html"
		Licenses.MPL_2,\
		Licenses.MPL_2_NO_DERIVATIVES:
			return "https://www.mozilla.org/en-US/MPL/2.0/"
		Licenses.GPL_2_ONLY,\
		Licenses.GPL_2_LATER:
			return "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html"
		Licenses.GPL_3_ONLY,\
		Licenses.GPL_3_LATER:
			return "https://www.gnu.org/licenses/gpl-3.0.html"
		Licenses.LGPL_2_1_ONLY,\
		Licenses.LGPL_2_1_LATER:
			return "https://www.gnu.org/licenses/lgpl-2.1.html"
		Licenses.LGPL_3_ONLY,\
		Licenses.LGPL_3_LATER:
			return "https://www.gnu.org/licenses/lgpl-3.0.html"
		Licenses.AGPL_3_ONLY,\
		Licenses.AGPL_3_LATER:
			return "https://www.gnu.org/licenses/agpl-3.0.html"

		Licenses.CC0:
			return "https://creativecommons.org/publicdomain/zero/1.0/"
		Licenses.CC_BY_3:
			return "https://creativecommons.org/licenses/by/3.0/"
		Licenses.CC_BY_SA_3:
			return "https://creativecommons.org/licenses/by-sa/3.0/"
		Licenses.CC_BY_4:
			return "https://creativecommons.org/licenses/by/4.0/"
		Licenses.CC_BY_SA_4:
			return "https://creativecommons.org/licenses/by-sa/4.0/"

		Licenses.OFL:
			return "https://scripts.sil.org/OFL_web"

		_:
			return ""


func _validate_key(source: Dictionary, key: String, type: int,
		internal_source:={}) -> bool:
	return source.has(key) and typeof(source[key]) == type and\
			(internal_source.empty() or internal_source.has(source[key]))
