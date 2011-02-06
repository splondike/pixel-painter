#!/usr/bin/env lua

as_library = true
dofile("pixel-painter.lua")

difficulty = 3 --Hard
for i=1,10000 do
	dimension = diff_to_dimension(difficulty)
	board = generate_board(dimension, i)
	par = calculate_par(board)
	print(par)
end

--state = {}
--state["selected_colour"] = 1
--state["par"] = par
--state["move_number"] = 0
--state["difficulty"] = difficulty
--state["board"] = board
--save_game(state, "board.save")
