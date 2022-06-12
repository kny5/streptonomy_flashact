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

extends Node2D


signal ended(has_won)

const SPAWN_WIDTH = 700

const CANDY_COUNTING_TIME = 3.0
const CANDY_FALL_DURATION = 1.0

const CANDY_QUANTITY_BASE = 3
const CANDY_OTHER_QUANTITY_MIN = 2

const CANDIES_TEXTURE = preload("_assets/candies.png")

var _candy_quantity_answer := 0

var answer_hovered := 0


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_candy_quantity_answer = CANDY_QUANTITY_BASE
	if difficulty > 1:
		_candy_quantity_answer *= 2
	_candy_quantity_answer += randi() % CANDY_QUANTITY_BASE + 1

	var candies := []
	if difficulty < 3:
		for i in _candy_quantity_answer:
			candies.append(0)

		($GUI/Fade/CandyCounter/Result/Type as TextureRect).texture =\
				preload("_assets/peppermint.png")
	else:
		var candy_other_quantity := int(max(
				CANDY_OTHER_QUANTITY_MIN, randi() % _candy_quantity_answer))
		for i in candy_other_quantity:
			candies.append(1)

		_candy_quantity_answer -= candy_other_quantity
		for i in _candy_quantity_answer:
			candies.append(0)

		candies.shuffle()

		if randi() % 2 == 0:
			($GUI/Fade/CandyCounter/Result/Type as TextureRect).texture =\
					preload("_assets/peppermint.png")
		else:
			_candy_quantity_answer = candy_other_quantity

			($GUI/Fade/CandyCounter/Result/Type as TextureRect).texture =\
					preload("_assets/chocolate.png")

	### Candy Spawn ###

	var tween := $Tween as Tween
	# warning-ignore:integer_division
	var spawn_width_adjusted: int =\
			SPAWN_WIDTH - CANDIES_TEXTURE.get_width() / 2
	# warning-ignore:integer_division
	var spawn_position := Vector2(($Jar as Sprite).position.x -
			spawn_width_adjusted / 2.0, -CANDIES_TEXTURE.get_height() / 2)
	# warning-ignore:integer_division
	# warning-ignore:narrowing_conversion
	var spawn_end: int =\
			NanogamePlayer.VIEW_SIZE.y + CANDIES_TEXTURE.get_height() / 2
	var spawn_interval: float = CANDY_COUNTING_TIME / candies.size()
	for i in candies.size():
		var candy := Sprite.new()
		candy.texture = CANDIES_TEXTURE
		candy.hframes = 2
		candy.frame = candies[i]

		candy.position = spawn_position
		candy.position.x += randi() % spawn_width_adjusted

		add_child(candy)

		# warning-ignore:return_value_discarded
		tween.interpolate_property(candy, "position:y", candy.position.y,
				spawn_end, CANDY_FALL_DURATION, Tween.TRANS_LINEAR,
				Tween.EASE_IN_OUT, spawn_interval * i)
		# warning-ignore:return_value_discarded
		tween.interpolate_property(candy, "rotation", 0,
				(TAU if randi() % 2 == 0 else -TAU) / 2, CANDY_FALL_DURATION,
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, spawn_interval * i)


	var answers := [_candy_quantity_answer, _candy_quantity_answer,
			_candy_quantity_answer]

	# Offset the first two answers in a way that the correct one's value isn't
	# between them.
	answers[0] += randi() % 2 + 1
	if answers[0] > 0:
		if randi() % 2 == 0:
			answers[1] -= randi() % 2 + 1
		else:
			answers[1] += 1
			if answers[1] == answers[0]:
				answers[1] += 1

	answers.shuffle()

	for i in ($GUI/Fade/CandyCounter/Answers as HBoxContainer).get_children():
		i.text = str(answers.pop_front())

		if debug_code == 1 and int(i.text) == _candy_quantity_answer:
			i.self_modulate = ColorN("cornflower")

	($AnimationPlayer as AnimationPlayer).queue("jar_shake")


func nanogame_start() -> void:
	# warning-ignore:return_value_discarded
	($Tween as Tween).start()

	# Stop the jar shaking animation.
	# warning-ignore:return_value_discarded
	get_tree().create_timer(CANDY_COUNTING_TIME).connect(
			"timeout", $AnimationPlayer as AnimationPlayer, "stop")


func _on_Tween_tween_all_completed() -> void:
	($GUI/Fade as ColorRect).show()

	($AnimationPlayer as AnimationPlayer).play("show_answers")


func _on_Answer_input_event(
		_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton or not event.is_pressed():
		return

	($GUI/Fade/CandyCounter/Result/Quantity as Label).text =\
			"× %02d" % _candy_quantity_answer

	var label := ($GUI/Fade/CandyCounter/Answers as HBoxContainer).get_child(
			answer_hovered) as Label
	if int(label.text) == _candy_quantity_answer:
		label.self_modulate = ColorN("lightgreen")

		($Result as AudioStreamPlayer).stream = preload("_assets/crunch.wav")

		emit_signal("ended", true)
	else:
		label.self_modulate = ColorN("tomato")

		($Result as AudioStreamPlayer).stream = preload("_assets/cough.wav")

		emit_signal("ended", false)

	($Result as AudioStreamPlayer).play()


func _on_Answer_mouse_entered(index: int) -> void:
	answer_hovered = index
