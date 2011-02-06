--Utility function makes a copy of the passed table
function deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

--Returns the maximum value of the passed table and its index 
function table_maximum(a)
	local mi = 1
	local m = a[mi]
	for i, val in ipairs(a) do
		if val > m then
			mi = i
			m = val
		end
	end
	return m, mi
end

--Solves the board using a simple algorithm and returns the number of
--moves required. Each turn, the function picks the move which fills in
--the greatest area of board. The number of moves required to complete
--it is returned.
function calculate_par(board)
	local board_dimension = table.getn(board)
	local test_game_copy = deepcopy(board)
	local moves = 0

	repeat
		local colours_count = get_colours_count(test_game_copy, 1, 1, test_game_copy[1][1])
		local max_count, colour = table_maximum(colours_count)

		if max_count > 0 then
			--Corrects the invalid colour values set by
			--get_colours_count, this also acts as a move
			for x=1,board_dimension do
				for y=1,board_dimension do
					if test_game_copy[x][y] < 0 then
						test_game_copy[x][y] = test_game_copy[x][y] * -1
					elseif test_game_copy[x][y] == 0 then
						test_game_copy[x][y] = colour
					end
				end
			end

			moves = moves + 1
		else
			return moves
		end
		--Manual garbage collection is needed so it doesn't run out of
		--memory
		collectgarbage("collect")
	until false
end

--Calculates the number of blocks of each colour adjacent to the filled
--region identified by the passed parameters. A colour indexed table
--containing the counts is returned.
--
--The 'board' table is also adjusted as follows: The filled region's
--colour index is set to zero and each of the adjacent areas' colour
--indexes are multiplied by -1. These invalid colour values are later
--corrected in the calculate_par function.
function get_colours_count(board, x, y, original_colour)
	local board_dimension = table.getn(board)
	local count_table = {0, 0, 0, 0, 0, 0}

	if x > 0 and y > 0 and x <= board_dimension and y <= board_dimension then
		if board[x][y] == original_colour then
			board[x][y] = 0

			local r1 = get_colours_count(board, x - 1, y, original_colour)
			local r2 = get_colours_count(board, x, y - 1, original_colour)
			local r3 = get_colours_count(board, x + 1, y, original_colour)
			local r4 = get_colours_count(board, x, y + 1, original_colour)
			for i=1,NUM_COLOURS do
				count_table[i] = r1[i] + r2[i] + r3[i] + r4[i]
			end
		elseif board[x][y] > 0 then
			local c = board[x][y]
			count_table[c] = fill_board(board, -1 * c, x, y, c)
		end
	end

	return count_table
end

--Returns a randomly coloured board of the indicated dimensions
function generate_board(board_dimension, num_colours, seed)
	math.randomseed(seed)

	local board = {}
	for x=1,board_dimension do
		board[x] = {}
		for y=1,board_dimension do
			board[x][y] = math.random(1,num_colours)
		end
	end

	return board
end

--Flood fills the board from the top left using selected_colour
--Returns the number of boxes filled
function fill_board(board, fill_colour, x, y, original_colour)
	local board_dimension = table.getn(board)
	if x > 0 and y > 0 and x <= board_dimension and 
		y <= board_dimension and board[x][y] == original_colour then

		board[x][y] = fill_colour
		return fill_board(board, fill_colour, x - 1, y, original_colour) + 
		       fill_board(board, fill_colour, x, y - 1, original_colour) +
		       fill_board(board, fill_colour, x + 1, y, original_colour) +
		       fill_board(board, fill_colour, x, y + 1, original_colour) + 1
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
	NUM_COLOURS = table.getn(COLOURS)
	DEFAULT_DIFFICULTY = 2 --1: Easy, 2: Normal, 3: Hard

	SCORES_FILE = "/pixel-painter.score"
	SAVE_FILE = "/pixel-painter.save"
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
		state["board"] = generate_board(board_dimension, NUM_COLOURS, rb.current_tick()+os.time())
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
	function redraw_game(game_state)
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
		rb.lcd_putsxy(title_xpos, 0, title)
		rb.lcd_hline(title_xpos, title_xpos + title_width, TEXT_LINE_HEIGHT)

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
				rb.lcd_putsxy(xpos, ypos, word_buffer)

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
		local action = rb.get_action(rb.contexts.CONTEXT_KEYBOARD, -1)
	end

	--Draws the application menu and handles its logic
	function app_menu()
		local options = {"Resume game", "Start new game", "Change difficulty", 
			"Help", "Quit without saving", "Quit"}
		local item = rb.do_menu("Pixel painter menu", options, nil, false)

		if item == 0 then
			redraw_game(game_state)
		elseif item == 1 then
			os.remove(SAVE_FILE)
			game_state = init_game(game_state["difficulty"])
			redraw_game(game_state)
		elseif item == 2 then
			local diff = rb.do_menu("Difficulty", {"Easy", "Medium", "Hard"}, game_state["difficulty"] - 1, false)
			if diff < 0 then
				app_menu()
			else
				local difficulty = diff + 1 --lua is 1 indexed
				os.remove(SAVE_FILE)
				game_state = init_game(difficulty)
				redraw_game(game_state)
			end
		elseif item == 3 then
			app_help()
			redraw_game(game_state)
		elseif item == 4 then
			os.remove(SAVE_FILE)
			os.exit()		
		elseif item == 5 then
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

	--Don't run if we're running as a library
	if as_library == nil then
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
		--FIXME: Remove kill_action
		if LAYOUT == 2 then
			prev_action = rb.actions.ACTION_KBD_LEFT
			next_action = rb.actions.ACTION_KBD_RIGHT
			kill_action = rb.actions.ACTION_KBD_UP
		else
			prev_action = rb.actions.ACTION_KBD_UP
			next_action = rb.actions.ACTION_KBD_DOWN
			kill_action = rb.actions.ACTION_KBD_LEFT
		end

		repeat
			local action = rb.get_action(rb.contexts.CONTEXT_KEYBOARD, -1)

			if action == rb.actions.ACTION_KBD_SELECT then
				if game_state["selected_colour"] ~= game_state["board"][1][1] then
					fill_board(game_state["board"], game_state["selected_colour"], 
						1, 1, game_state["board"][1][1])
					game_state["move_number"] = game_state["move_number"] + 1
					redraw_game(game_state, highscores)
					if check_win(game_state["board"]) then
						local par_diff = game_state["move_number"] - game_state["par"]
						if not highscores[game_state["difficulty"]] or 
							par_diff < highscores[game_state["difficulty"]] then

							rb.splash(3*rb.HZ, win_text(par_diff)..", a new high score!")
							highscores[game_state["difficulty"]] = par_diff
							save_scores(highscores, SCORES_FILE)
						else
							rb.splash(3*rb.HZ, win_text(par_diff)..".")
						end
						os.remove(SAVE_FILE)
						os.exit()
					end
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
		until action == kill_action
	end
end
