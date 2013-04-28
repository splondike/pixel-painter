--[[
             __________               __   ___.
   Open      \______   \ ____   ____ |  | _\_ |__   _______  ___
   Source     |       _//  _ \_/ ___\|  |/ /| __ \ /  _ \  \/  /
   Jukebox    |    |   (  <_> )  \___|    < | \_\ (  <_> > <  <
   Firmware   |____|_  /\____/ \___  >__|_ \|___  /\____/__/\_ \
                     \/            \/     \/    \/            \/
 $Id$

 Port and extension of Pixel Painter by Pavel Bakhilau
 (http://js1k.com/2010-first/demo/453) to Rockbox Lua.

 Copyright (C) 2011 by Stefan Schneider-Kennedy

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
 KIND, either express or implied.

]]--

--Number of colours used in the game
--Hard coded here, and in the COLOURS and PIP_COLOURS definitions
NUM_COLOURS = 6

-- Utility function
-- Don't know how to do this in Lua without internet, hence this
function len_map(map)
  local count = 0
  for _ in pairs(map) do
    count = count + 1
  end
  return count
end

-- Turns a board's 2d matrix representation
-- into a node collection
function board_to_nodes(board)
  local board_dim = table.getn(board)
  local function xy_to_flat(x, y)
    return (y - 1) * board_dim + x
  end

  local node_colors = {}
  local connections_map = {}
  for i = 1,board_dim*board_dim do
    connections_map[i] = {}
  end

  -- Add in all the nodes and color information
  for y = 1,board_dim do
    for x = 1,board_dim do
      local curr_node_id = xy_to_flat(x, y)
      node_colors[curr_node_id] = board[y][x]

      if x < board_dim then
        local other_node_id = xy_to_flat(x + 1, y)
        connections_map[curr_node_id][other_node_id] = true
        connections_map[other_node_id][curr_node_id] = true
        node_colors[other_node_id] = board[y][x + 1]
      end
      if y < board_dim then
        local other_node_id = xy_to_flat(x, y + 1)
        connections_map[curr_node_id][other_node_id] = true
        connections_map[other_node_id][curr_node_id] = true
        node_colors[other_node_id] = board[y + 1][x]
      end
    end
  end

  return {connections = connections_map, colors = node_colors}
end

-- For the given graph, combine node1 and node2 into
-- one (taking the smaller of the two nodes as the new number)
function combine_nodes(graph, node1, node2)
  assert (node1 ~= node2)
  local small, large = math.min(node1, node2), math.max(node1, node2)

  for other_node in pairs(graph.connections[large]) do
    if other_node ~= small then
      -- Point the larger nodes connections to the smaller node
      graph.connections[other_node][large] = nil
      graph.connections[other_node][small] = true

      -- Combine the sets of connections into the smaller node
      graph.connections[small][other_node] = true
    end
  end
  -- Remove the reference to the larger node from the small
  graph.connections[small][large] = nil
  -- Delete the larger node's info
  graph.colors[large] = nil
  graph.connections[large] = nil
end

-- Simplifies a node collection by combining adjacent nodes of the same
-- color
-- NOTE: Mutates the passed in table (saves memory)
--
-- @return the number of nodes simplified
function simplify_nodes(graph)
  local key_group_number, con_group_number = nil, nil
  local function iter()
    if con_group_number == nil then
      key_group_number = next(graph.connections, key_group_number)
      if key_group_number == nil then
        return nil
      end
    end

    -- If we've been merged
    if graph.connections[key_group_number] == nil then
      con_group_number = nil
      return iter()
    end

    con_group_number = next(graph.connections[key_group_number], con_group_number)

    return key_group_number, con_group_number
  end

  local combined_nodes_count = 0
  for node1, node2 in iter do
    if graph.colors[node1] == graph.colors[node2] then
      combine_nodes(graph, node1, node2)
      combined_nodes_count = combined_nodes_count + 1
    end
  end

  return combined_nodes_count
end

-- Returns a graph object representation of the given board
function board_to_graph(board)
  local graph = board_to_nodes(board)
  local fully_simplified = false
  while not fully_simplified do
    local num_simplified = simplify_nodes(graph)
    fully_simplified = num_simplified == 0
  end

  return graph
end

-- Returns a solution to the given graph
function solve_graph(graph)
  local moves = {}
  while len_map(graph.connections[1]) > 0 do
    -- Group the connections
    local color_groups = {}
    for group in pairs(graph.connections[1]) do
      local color = graph.colors[group]

      if color_groups[color] == nil then
        color_groups[color] = {}
      end
      table.insert(color_groups[color], group)
    end

    local best_color = nil
    local largest_group = 0
    for color,groups in pairs(color_groups) do
      local new_connections = {}
      for _,group in pairs(groups) do
        for con in pairs(graph.connections[group]) do
          new_connections[con] = true
        end
      end

      if len_map(new_connections) > largest_group then
        best_color = color
        largest_group = len_map(new_connections)
      end
    end

    table.insert(moves, best_color)
    for _,group in pairs(color_groups[best_color]) do
      combine_nodes(graph, 1, group)
    end
  end
  return moves
end

-- Returns the number of moves the computer took to solve the board
function calculate_par(board)
  local graph = board_to_graph(board)
  local solution = solve_graph(graph)
  return table.getn(solution)
end

--Returns a randomly coloured board of the indicated dimensions
function generate_board(board_dimension, seed)
	math.randomseed(seed)

	local board = {}
	for x=1,board_dimension do
		board[x] = {}
		for y=1,board_dimension do
			board[x][y] = math.random(1,NUM_COLOURS)
		end
	end

	return board
end

--Flood fills the board from the top left using selected_colour
--Returns the number of boxes filled
function fill_board(board, fill_colour, x, y, original_colour, non_matching)
	local board_dimension = table.getn(board)
	if x > 0 and y > 0 and x <= board_dimension and y <= board_dimension then
		if board[x][y] == original_colour then
			board[x][y] = fill_colour
			return fill_board(board, fill_colour, x - 1, y, original_colour, non_matching) + 
				   fill_board(board, fill_colour, x, y - 1, original_colour, non_matching) +
				   fill_board(board, fill_colour, x + 1, y, original_colour, non_matching) +
				   fill_board(board, fill_colour, x, y + 1, original_colour, non_matching) + 1
		elseif(non_matching ~= nil and board[x][y] ~= fill_colour) then
			table.insert(non_matching, {x,y})
		end
	end

	return 0
end

--Checks whether the given board is a single colour
function check_win(board)
	for x,col in pairs(board) do
		for y,value in pairs(col) do
			if value ~= board[1][1] then
				return false
			end
		end
	end

	return true
end

--Attempt to load the game variables stored in the indicated save file.
--Returns a table containing game variables if the file can be opened, 
--false otherwise.
--Table keys are: difficulty, par, move_number, selected_colour, board
function load_game(filename)
	local f = io.open(filename, "r")
	if f ~= nil then
		local rtn = {}
		rtn["difficulty"] = tonumber(f:read())
		rtn["par"] = tonumber(f:read())
		rtn["move_number"] = tonumber(f:read())
		rtn["selected_colour"] = tonumber(f:read())

		local board={}
		local dimension = diff_to_dimension(rtn["difficulty"])
		for x=1,dimension do
			board[x] = {}
			local line = f:read()
			local bits = {line:match(("([^ ]*) "):rep(dimension))}
			for y=1,dimension do
				board[x][y] = tonumber(bits[y])
			end
		end
		rtn["board"] = board

		f:close()
		return rtn
	else
		return false
	end
end

--Saves the game state to file
function save_game(state, filename)
	local f = io.open(filename, "w")
	if f ~= nil then
		f:write(state["difficulty"],"\n")
		f:write(state["par"],"\n")
		f:write(state["move_number"],"\n")
		f:write(state["selected_colour"],"\n")
		local board = state["board"]
		local dimension = diff_to_dimension(state["difficulty"])
		for x=1,dimension do
			for y=1,dimension do
				f:write(board[x][y]," ")
			end
			f:write("\n")
		end
		f:close()
		return true
	else
		return false
	end
end

--Loads the high scores from file
--Returns true on success, false otherwise
function load_scores(filename)
	local f = io.open(filename, "r")
	if f ~= nil then
		local highscores = {}
		for i=1,3 do
			local line = f:read()
			local value = false
			if line ~= nil then
				value = tonumber(line)
			end

			highscores[i] = value
		end
		f:close()
		return highscores
	else
		return false
	end
end

--Saves the high scores to file
function save_scores(highscores, filename)
	local f = io.open(filename, "w")
	if f ~= nil then
		for i=1,3 do
			local value = highscores[i]
			if value == false then
				value = ""
			end
			f:write(value,"\n")
		end
		f:close()
		return true
	else
		return false
	end
end

function diff_to_dimension(difficulty)
	if difficulty == 1 then
		return 8
	elseif difficulty == 2 then
		return 16
	else
		return 22
	end
end

--Don't run the RB stuff if we're not running under RB
if rb ~= nil then

	if rb.lcd_rgbpack == nil then
		rb.splash(2*rb.HZ, "Non RGB targets not currently supported")
		os.exit()
	end

	---------------------
	--RB Game variables--
	---------------------

	--The colours used by the game
	COLOURS = {
		rb.lcd_rgbpack(255, 119, 34),
		rb.lcd_rgbpack(255, 255, 102),
		rb.lcd_rgbpack(119, 204, 51),
		rb.lcd_rgbpack(102, 170, 255),
		rb.lcd_rgbpack(51, 68, 255),
		rb.lcd_rgbpack(51, 51, 51),
	}
	--The colour of the selection pip
	PIP_COLOURS = {
		rb.lcd_rgbpack(0, 0, 0),
		rb.lcd_rgbpack(0, 0, 0),
		rb.lcd_rgbpack(0, 0, 0),
		rb.lcd_rgbpack(0, 0, 0),
		rb.lcd_rgbpack(0, 0, 0),
		rb.lcd_rgbpack(255, 255, 255),
	}
	DEFAULT_DIFFICULTY = 2 --1: Easy, 2: Normal, 3: Hard

	FILES_ROOT = "/.rockbox/rocks/games/"
	SCORES_FILE = FILES_ROOT.."pixel-painter.score"
	SAVE_FILE = FILES_ROOT.."pixel-painter.save"
	r,w,TEXT_LINE_HEIGHT = rb.font_getstringsize(" ", 1) --Get font height
	--Determine which layout to use by considering the screen dimensions
	--the +9 is so we have space for the chooser
	if rb.LCD_WIDTH > (rb.LCD_HEIGHT + 9) then
		LAYOUT = 1 --Wider than high, status and chooser on right
	elseif rb.LCD_HEIGHT > (rb.LCD_WIDTH + 9) then
		LAYOUT = 2 --Higher than wide, status and chooser below
	else
		LAYOUT = 3 --Treat like a square screen, chooser on right, status below
	end

	--Display variables
	chooser_pip_dimension = 6 --pixel dimension of the selected colour pip
	block_width = 0 --pixel dimension of each game square
	chooser_start_pos = 0 --x or y position of the first block (depending on LAYOUT)

	--Populated by load_scores()
	highscores = {false, false, false}

	--A table containing the game state, initialised by init_game() or
	--load_game(), see
	game_state = {}

	-----------------------------------
	--Display and interface functions--
	-----------------------------------

	--Sets up a new game and display variables for the indicated
	--difficulty
	function init_game(difficulty)
		init_display_variables(difficulty)
		local state = {}
		local board_dimension = diff_to_dimension(difficulty)
		state["selected_colour"] = 1
		state["move_number"] = 0
		state["difficulty"] = difficulty
		state["board"] = generate_board(board_dimension, rb.current_tick()+os.time())
		rb.splash(1, "Calculating par...") --Will stay on screen until it's done
		state["par"] = calculate_par(state["board"])

		return state
	end

	--Initialises the display variables for the screen LAYOUT
	function init_display_variables(difficulty)
		local board_dimension = diff_to_dimension(difficulty)

		if LAYOUT == 1 then
			block_width = rb.LCD_HEIGHT / board_dimension 
			chooser_start_pos = (board_dimension)*block_width + 2
			chooser_width = rb.LCD_WIDTH - chooser_start_pos
			chooser_height = (rb.LCD_HEIGHT - 3*TEXT_LINE_HEIGHT) / NUM_COLOURS
		elseif LAYOUT == 2 then
			block_width = rb.LCD_WIDTH / board_dimension 
			chooser_start_pos = board_dimension*block_width + 2 + TEXT_LINE_HEIGHT
			chooser_width = rb.LCD_WIDTH / NUM_COLOURS
			chooser_height = rb.LCD_HEIGHT - chooser_start_pos
		else
			if TEXT_LINE_HEIGHT > 9 then
				block_width = (rb.LCD_HEIGHT - TEXT_LINE_HEIGHT) / board_dimension
			else
				block_width = (rb.LCD_HEIGHT - 9) / board_dimension
			end
			chooser_start_pos = (board_dimension)*block_width + 1
			chooser_width = rb.LCD_WIDTH - chooser_start_pos
			chooser_height = (rb.LCD_HEIGHT - TEXT_LINE_HEIGHT) / NUM_COLOURS
		end
	end

	--Draws the game board to screen
	function draw_board(board)
		for x,col in pairs(board) do
			for y,value in pairs(col) do
				rb.lcd_set_foreground(COLOURS[value])
				rb.lcd_fillrect((x-1)*block_width, (y-1)*block_width, block_width, block_width)
			end
		end
	end

	--Draw the colour chooser along with selected pip at the appropriate
	--position
	function draw_chooser(selected_colour)
		for i=1,NUM_COLOURS do
			rb.lcd_set_foreground(COLOURS[i])
			if LAYOUT == 1 or LAYOUT == 3 then
				rb.lcd_fillrect(chooser_start_pos, (i - 1)*(chooser_height), chooser_width, chooser_height)
			elseif LAYOUT == 2 then
				rb.lcd_fillrect((i - 1)*(chooser_width), chooser_start_pos, chooser_width, chooser_height)
			end
		end

		rb.lcd_set_foreground(PIP_COLOURS[selected_colour])
		local xpos = 0
		local ypos = 0
		if LAYOUT == 1 or LAYOUT == 3 then
			xpos = chooser_start_pos + (chooser_width - chooser_pip_dimension)/2
			ypos = (selected_colour-1)*(chooser_height) + (chooser_height - chooser_pip_dimension)/2
		elseif LAYOUT == 2 then
			xpos = (selected_colour-1)*(chooser_width) + (chooser_width - chooser_pip_dimension)/2
			ypos = chooser_start_pos + (chooser_height - chooser_pip_dimension)/2
		end
		rb.lcd_fillrect(xpos, ypos, chooser_pip_dimension, chooser_pip_dimension)
	end

	--Draws the current moves, par and high score
	function draw_status(move_number, par, highscore)
		local strings = {"Move", move_number, "Par", par}
		if highscore then
			table.insert(strings, "Best")
			table.insert(strings, highscore)
		end

		if LAYOUT == 1 then
			local function calc_string(var_len_str, static_str)
				local avail_width = chooser_width - rb.font_getstringsize(static_str, 1)
				local rtn_str = ""

				for i=1,string.len(var_len_str) do
					local c = string.sub(var_len_str, i, i)
					local curr_width = rb.font_getstringsize(rtn_str, 1)
					local width = rb.font_getstringsize(c, 1)

					if curr_width + width <= avail_width then
						rtn_str = rtn_str .. c
					else
						break
					end
				end
				
				return rtn_str, rb.font_getstringsize(rtn_str, 1)
			end

			local height = NUM_COLOURS*chooser_height
			colon_width = rb.font_getstringsize(": ", 1)
			for i = 1,table.getn(strings),2 do
				local label, label_width = calc_string(strings[i], ": "..strings[i+1])

				rb.lcd_set_foreground(rb.lcd_rgbpack(255,0,0))
				rb.lcd_putsxy(chooser_start_pos, height, label..": ")
				rb.lcd_set_foreground(rb.lcd_rgbpack(255,255,255))
				rb.lcd_putsxy(chooser_start_pos + label_width + colon_width, height, strings[i+1])
				height = height + TEXT_LINE_HEIGHT
			end
		else
			local text_ypos = 0
			if LAYOUT == 2 then
				text_ypos = chooser_start_pos - TEXT_LINE_HEIGHT - 1
			else
				text_ypos = rb.LCD_HEIGHT - TEXT_LINE_HEIGHT
			end 
			space_width = rb.font_getstringsize(" ", 1)
			local xpos = 0
			for i = 1,table.getn(strings),2 do
				rb.lcd_set_foreground(rb.lcd_rgbpack(255,0,0))
				rb.lcd_putsxy(xpos, text_ypos, strings[i]..": ")
				xpos = xpos + rb.font_getstringsize(strings[i]..": ", 1)
				rb.lcd_set_foreground(rb.lcd_rgbpack(255,255,255))
				rb.lcd_putsxy(xpos, text_ypos, strings[i+1])
				xpos = xpos + rb.font_getstringsize(strings[i+1], 1) + space_width
			end
		end
	end

	--Convenience function to redraw the whole board to screen
	function redraw_game(game_state, highscores)
		rb.lcd_clear_display()
		draw_board(game_state["board"])
		draw_chooser(game_state["selected_colour"])
		draw_status(game_state["move_number"], game_state["par"], 
			highscores[game_state["difficulty"]])
		rb.lcd_update()
	end


	--Draws help to screen, waits for a keypress to exit
	function app_help()
		rb.lcd_clear_display()

		local title = "Pixel painter help"
		local rtn, title_width, h = rb.font_getstringsize(title, 1)
		local title_xpos = (rb.LCD_WIDTH - title_width) / 2
		local space_width = rb.font_getstringsize(" ", 1)

		--Draw title
		function draw_text(y_offset)
			rb.lcd_set_foreground(rb.lcd_rgbpack(255,0,0))
			rb.lcd_putsxy(title_xpos, y_offset, title)
			rb.lcd_hline(title_xpos, title_xpos + title_width, TEXT_LINE_HEIGHT + y_offset)
			rb.lcd_set_foreground(rb.lcd_rgbpack(255,255,255))

			local body_text = [[
The aim is to fill the screen with a single colour. Each move you select a new colour which is then filled in from the top left corner.

The bottom right displays the number of moves taken, the number of moves used by the computer and your best score relative to the computer's.
		]]
			local body_len = string.len(body_text)

			--Draw body text
			local word_buffer = ""
			local xpos = 0
			local ypos = TEXT_LINE_HEIGHT * 2 
			for i=1,body_len do
				local c = string.sub(body_text, i, i)
				if c == " " or c == "\n" then
					local word_length = rb.font_getstringsize(word_buffer, 1)
					if (xpos + word_length) > rb.LCD_WIDTH then
						xpos = 0
						ypos = ypos + TEXT_LINE_HEIGHT
					end
					rb.lcd_putsxy(xpos, ypos + y_offset, word_buffer)

					word_buffer = ""
					if c == "\n" then
						xpos = 0
						ypos = ypos + TEXT_LINE_HEIGHT
					else
						xpos = xpos + word_length + space_width
					end
				else
					word_buffer = word_buffer .. c
				end
			end

			rb.lcd_update()

			return ypos
		end

		--Deal with scrolling the help
		local y_offset = 0
		local max_y_offset = math.max(draw_text(y_offset) - rb.LCD_HEIGHT, 0)
		local exit = false
		repeat
			local action = rb.get_action(rb.contexts.CONTEXT_KEYBOARD, -1)
			if action == rb.actions.ACTION_KBD_DOWN then
				y_offset = math.max(-max_y_offset, y_offset - TEXT_LINE_HEIGHT)
			elseif action == rb.actions.ACTION_KBD_UP then
				y_offset = math.min(0, y_offset + TEXT_LINE_HEIGHT)
			elseif action == rb.actions.ACTION_KBD_LEFT or 
				action == rb.actions.ACTION_KBD_RIGHT or 
				action == rb.actions.ACTION_KBD_SELECT or 
				action == rb.actions.ACTION_KBD_ABORT then
				--This explicit enumeration is needed for targets like
				--the iriver which send more than one action when
				--scrolling

				exit = true
			end
			rb.lcd_clear_display()
			draw_text(y_offset)
		until exit == true
	end

	--Draws the application menu and handles its logic
	function app_menu()
		local options = {"Resume game", "Start new game", "Change difficulty", 
			"Help", "Quit without saving", "Quit"}
		local item = rb.do_menu("Pixel painter menu", options, nil, false)

		if item == 0 then --Resume game
			redraw_game(game_state, highscores)
		elseif item == 1 then --Start new game
			os.remove(SAVE_FILE)
			game_state = init_game(game_state["difficulty"])
			redraw_game(game_state, highscores)
		elseif item == 2 then --Change difficulty
			local diff = rb.do_menu("Difficulty", {"Easy", "Medium", "Hard"}, game_state["difficulty"] - 1, false)
			if diff < 0 then
				app_menu()
			else
				local difficulty = diff + 1 --lua is 1 indexed
				os.remove(SAVE_FILE)
				game_state = init_game(difficulty)
				redraw_game(game_state, highscores)
			end
		elseif item == 3 then --Help
			app_help()
			redraw_game(game_state, highscores)
		elseif item == 4 then --Quit without saving
			os.remove(SAVE_FILE)
			os.exit()		
		elseif item == 5 then --Quit
			rb.splash(1, "Saving game...") --Will stay on screen till the app exits
			save_game(game_state,SAVE_FILE)
			os.exit()
		end
	end

	--Determine what victory text to show depending on the relation of the
	--score to the calculated par value
	function win_text(delta)
		if delta < 0 then
			return "You were "..(-1*delta).." under par"
		elseif delta > 0 then
			return "You were "..delta.." over par"
		else
			return "You attained par"
		end
	end

	------------------
	--Game main loop--
	------------------

	--Gives the option of testing things without running the game, use:
	--as_library=true
	--dofile('pixel-painter.lua')
	if not as_library then
		game_state = load_game(SAVE_FILE)
		if game_state then
			init_display_variables(game_state["difficulty"])
		else
			game_state = init_game(DEFAULT_DIFFICULTY)
		end
		loaded_scores = load_scores(SCORES_FILE)
		if loaded_scores then
			highscores = loaded_scores
		end
		redraw_game(game_state, highscores)

		require("actions")
		--Set the keys to use for scrolling the chooser
		prev_action = rb.actions.ACTION_KBD_UP
		next_action = rb.actions.ACTION_KBD_DOWN
		safe_exit_action = rb.actions.ACTION_KBD_LEFT

		repeat
			local action = rb.get_action(rb.contexts.CONTEXT_KEYBOARD, -1)

			if action == rb.actions.ACTION_KBD_SELECT then
				--Ensure the user has changed the colour before allowing move
				--TODO: Check that the move would change the board

				if game_state["selected_colour"] ~= game_state["board"][1][1] then
					fill_board(game_state["board"], game_state["selected_colour"], 
						1, 1, game_state["board"][1][1])
					game_state["move_number"] = game_state["move_number"] + 1
					redraw_game(game_state, highscores)

					if check_win(game_state["board"]) then
						local par_diff = game_state["move_number"] - game_state["par"]
						if not highscores[game_state["difficulty"]] or 
							par_diff < highscores[game_state["difficulty"]] then
							--
							rb.splash(3*rb.HZ, win_text(par_diff)..", a new high score!")
							highscores[game_state["difficulty"]] = par_diff
							save_scores(highscores, SCORES_FILE)
						else
							rb.splash(3*rb.HZ, win_text(par_diff)..".")
						end
						os.remove(SAVE_FILE)
						os.exit()
					end
				else
					--Will stay on screen until they move
					rb.splash(1, "Invalid move (wouldn't change board). Change colour to continue.")
				end
			elseif action == next_action then
				if game_state["selected_colour"] < NUM_COLOURS then
					game_state["selected_colour"] = game_state["selected_colour"] + 1
					redraw_game(game_state, highscores)
				end
			elseif action == prev_action then
				if game_state["selected_colour"] > 1 then
					game_state["selected_colour"] = game_state["selected_colour"] - 1
					redraw_game(game_state, highscores)
				end
			elseif action == rb.actions.ACTION_KBD_ABORT then 
				app_menu()
			end
		until action == safe_exit_action

		--This is executed if the user presses safe_exit_action
		rb.splash(1, "Saving game...") --Will stay on screen till the app exits
		save_game(game_state,SAVE_FILE)
	end
end
