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

tool
extends EditorScript


const _TRANSLATE_EXTRA =\
		["Cut", "Copy", "Paste", "Select All", "Clear", "Undo", "Redo"]

const _KEY_WORDS_TSCN =\
		["bbcode_text", "hint_tooltip", "placeholder_text", "text"]
const _KEY_WORDS_NANOGAME = ["name", "kickoff", "description", "tags"]

const _BLACKLISTED_STRINGS = ["0", "0 / 0", "-", "..."]
const _BLACKLISTED_DIRECTORIES = ["tools"]

var _is_extraction_aborting := false

var _translatable_strings := {}

var _quote_end := ""


func _run() -> void:
	_extract_strings_from()

	if _is_extraction_aborting:
		_is_extraction_aborting = false

		return

	_translatable_strings[""] = [_TRANSLATE_EXTRA, []]

	_format_translation_pot()


# Extracts strings from translation requests written as such:
# # translation-extract: "Lorem ipsum dolor sit amet, consectetur adipiscing
# # elit. Pellentesque consequat vestibulum suscipit."
func _extract_strings_from(path := "") -> void:
	var directory := Directory.new()
	if not path.empty():
		# warning-ignore:return_value_discarded
		directory.open(path)

	# warning-ignore:return_value_discarded
	directory.list_dir_begin(true, true)
	var file_name: String = directory.get_next()
	var subdirectory_list := []
	var file := File.new()
	while not file_name.empty():
		if directory.current_is_dir():
			if not _BLACKLISTED_DIRECTORIES.has(path + file_name):
				# Insert it into the list alphabeticaly.
				var is_inserted := false
				for i in subdirectory_list.size():
					if file_name < subdirectory_list[i]:
						subdirectory_list.insert(i, file_name)

						is_inserted = true

				if not is_inserted:
					subdirectory_list.append(file_name)

			file_name = directory.get_next()

			continue

		var file_extension: String = file_name.get_extension()
		if file_extension != "gd" and file_extension != "tscn" and\
				file_extension != "json":
			file_name = directory.get_next()

			continue

		var error_code: int = file.open(path + file_name, File.READ)
		if error_code != OK:
			file_name = directory.get_next()

			_is_extraction_aborting = true

			directory.list_dir_end()

			push_error('Unable to load path "' + path + file_name +
					'". Translation extraction aborted. Error code: ' +
					str(error_code))

			return

		var is_extracting := false
		var has_extraction_began := false
		var line: String = file.get_line().strip_edges()
		var strings := []
		var string_current := ""
		var rows := []
		var row_current := 1
		while not file.eof_reached():
			var string_group_size := 1
			if not is_extracting:
				match file_extension:
					"gd":
						if line.begins_with('# translation-extract:"'):
							is_extracting = true
							has_extraction_began = true

							line = line.trim_prefix('# translation-extract:"')

							_quote_end = '"'
						elif line.begins_with("# translation-extract:'"):
							is_extracting = true
							has_extraction_began = true

							line = line.trim_prefix("# translation-extract:'")

							_quote_end = "'"
					"tscn":
						for i in _KEY_WORDS_TSCN:
							if line.begins_with(i + ' = "'):
								is_extracting = true
								has_extraction_began = true

								line = line.trim_prefix(i + ' = "')

								_quote_end = '"'

								break
					"json":
						if file_name == "nanogame.json":
							for i in _KEY_WORDS_NANOGAME:
								if line.begins_with('"' + i + '": "'):
									is_extracting = true
									has_extraction_began = true

									line = line.trim_prefix(
											'"' + i + '": "')

									if i == "tags":
										string_group_size =\
												line.split(",", false).size()

									break
						elif line.begins_with('"') and\
								(line.find('"', 1) >= line.length() - 2 or\
								line.find('",', 1) == line.length() - 1):
							is_extracting = true
							has_extraction_began = true

							line = line.trim_prefix('"')

						_quote_end = '"'

			if is_extracting:
				if has_extraction_began:
					for i in string_group_size:
						rows.append(row_current)
				elif file_extension == "gd":
					if line.begins_with("#"):
						line = line.trim_prefix("#")
					else:
						is_extracting = false
						_is_extraction_aborting = true

						strings.clear()
						rows.clear()

						directory.list_dir_end()

						push_error("Incorrectly formated translation " +
								'request in path "' + path + file_name +
								'" at line ' + str(row_current) +
								". Translation extraction aborted.")

						return

				has_extraction_began = false

				string_current += line

				if file_extension == "json" or line.ends_with(_quote_end):
					if file_extension == "json" or\
							line[line.length() - 2] != _quote_end:
						string_current = string_current.trim_suffix(_quote_end
								if line.ends_with(_quote_end) else '",')

						is_extracting = false

						if not _BLACKLISTED_STRINGS.has(string_current):
							if file_extension == "tscn":
								# Escape "new line" characters.
								string_current =\
										string_current.replace("\n", "\\n")

							if string_group_size > 1:
								strings +=\
										Array(string_current.split(",", false))
							else:
								strings.append(string_current)

							# Break earlier on nanogame files so third-party
							# strings aren't extracted.
							if file_name == "nanogame.json" and\
									strings.size() - string_group_size + 1 ==\
											_KEY_WORDS_NANOGAME.size():
								break
						else:
							rows.resize(rows.size() - 1)

						string_current = ""
				elif file_extension == "tscn":
					string_current += "\n"

			line = file.get_line().strip_edges()
			row_current += 1

		file.close()

		if not strings.empty():
			_translatable_strings[path + file_name] =\
					[strings.duplicate(), rows.duplicate()]

			strings.clear()
			rows.clear()

		file_name = directory.get_next()

	directory.list_dir_end()

	for i in subdirectory_list:
		if _is_extraction_aborting:
			return

		_extract_strings_from(path + i + "/")


func _format_translation_pot() -> void:
	var file := File.new()
	# warning-ignore:return_value_discarded
	file.open("res://translations/translation.pot", File.WRITE)
	file.store_string('msgid ""\nmsgstr ""\n' +
			'"Project-Id-Version: Librerama\\n"\n' +
			'"MIME-Version: 1.0\\n"\n' +
			'"Content-Type: text/plain; charset=UTF-8\\n"\n'+
			'"Content-Transfer-Encoding: 8bit\\n"\n')

	var files: Array = _translatable_strings.keys()
	var file_index := 0
	for i in files:
		var row_index := 0
		for j in _translatable_strings[i][0]:
			if j == null:
				continue

			if j.empty():
				if not i.empty():
					push_warning('Empty translation string found in path "' +
							i + '" at line ' +
							str(_translatable_strings[i][1][row_index]) +\
							". String discarded.")
				else:
					push_warning("Empty translation string defined in the " +
							"array for extra translations. String discarded.")

				continue

			if not i.empty():
				file.store_string("\n#:")

				# Insert the location comments, while also searching and
				# nullifying repeats so they can be skipped.
				var comment_length := 0
				for k in files.size():
					if k < file_index:
						continue

					var file_path: String = files[k]
					var lines: Array = _translatable_strings[file_path][0]
					var rows: Array = _translatable_strings[file_path][1]
					var line_index := 0
					while true:
						line_index = lines.find(j, line_index)
						if line_index == -1:
							break

						var comment: String = " ../" + file_path + ":" +\
								str(rows[line_index])
						if comment_length > 0 and\
								comment_length + comment.length() > 80:
							comment = "\n#:" + comment
							comment_length = 0
						elif comment_length == 0:
							comment_length += 3 # "\n#:" length.

						comment_length += comment.length()

						file.store_string(comment)

						lines[line_index] = null

			file.store_string("\nmsgid ")

			# Separate strings at new lines.
			var strings := []
			var index_next := 0
			var index_last := 0
			while true:
				index_next = j.find("\\n", index_last)
				strings.append(j.substr(index_last,
						index_next - index_last + 2
						if index_next != -1 else index_next))

				if index_next == -1:
					break

				index_last = index_next + 2

			# Wrap strings that go past the guideline.
			var strings_index := 0
			while true:
				var string: String = strings[strings_index]
				if string.length() + 2 <= 80:
					strings_index += 1
					if strings_index > strings.size() - 1:
						break

					continue

				var string_wrapped: String = string
				var space_index := string_wrapped.length()
				while space_index + 4 > 80:
					space_index = string_wrapped.find_last(" ")
					if space_index == -1:
						break

					string_wrapped = string_wrapped.substr(0, space_index)

				if space_index != -1:
					strings.insert(
							strings_index + 1, string.substr(space_index + 1))
					strings[strings_index] = string_wrapped + " "

				strings_index += 1
				if strings_index > strings.size() - 1:
					break

			# Make the first string in "msgid" empty when there's multiple
			# lines, or the single line goes past the guideline.
			if strings.size() > 1 or strings.front().length() + 9 > 80:
				file.store_string('""\n')

			for k in strings:
				file.store_string('"' + k + '"\n')

			file.store_string('msgstr ""\n')

			row_index += 1

		file_index += 1

	file.close()
