require("actions")

if rb.lcd_rgbpack == nil then
	rb.splash(2*rb.HZ, "Non RGB targets not currently supported")
	os.exit()
end

--The colours used by the game
local COLOURS = {
	rb.lcd_rgbpack(255, 119, 34),
	rb.lcd_rgbpack(255, 255, 102),
	rb.lcd_rgbpack(119, 204, 51),
	rb.lcd_rgbpack(102, 170, 255),
	rb.lcd_rgbpack(51, 68, 255),
	rb.lcd_rgbpack(51, 51, 51),
}
--The colour of the selection pip
local PIP_COLOURS = {
	rb.lcd_rgbpack(0, 0, 0),
	rb.lcd_rgbpack(0, 0, 0),
	rb.lcd_rgbpack(0, 0, 0),
	rb.lcd_rgbpack(0, 0, 0),
	rb.lcd_rgbpack(0, 0, 0),
	rb.lcd_rgbpack(255, 255, 255),
}
local NUM_COLOURS = table.getn(COLOURS)
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

--Game variables (most are initialized in init_variables)
local highscores = {false, false, false}

local difficulty = 2 --1:easy, 2:medium, 3:hard
local board_dimension = 0 --Number of rows and columns
local chooser_pip_dimension = 6 --pixel dimension of the selected colour pip
local block_width = 0 --pixel dimension of each game square
local chooser_start_pos = 0 --x or y position of the first block (depending on LAYOUT)

local board = {}
local num_moves = 0
local selected_colour = 1 --index of the current colour

--Convenience function
function init_game(difficulty)
	init_variables(difficulty)
	board = generate_board(board_dimension)
	rb.splash(1, "Calculating par...") --Will stay on screen until it's done
	par = calculate_par(board)
end

--Initialises the game variables at the given difficulty, and the UI
--variables for the screen LAYOUT
function init_variables(difficulty)
	board_dimension = diff_to_dimension(difficulty)

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
	end

	--Game variables
	selected_colour = 1 
	num_moves = 0
end

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
function calculate_par(game_board)
	local test_game_copy = deepcopy(game_board)
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
		rb.yield()
	until false
end

--Calculates the number of blocks of each colour adjacent to the filled
--region identified by the passed parameters. A colour indexed table
--containing the counts is returned.
--
--The game_board table is also adjusted as follows: The filled region's
--colour index is set to zero and each of the adjacent areas' colour
--indexes are multiplied by -1. These invalid colour values are later
--corrected in the calculate_par function.
function get_colours_count(game_board, x, y, original_colour)
	local count_table = {0, 0, 0, 0, 0, 0}

	if x > 0 and y > 0 and x <= board_dimension and y <= board_dimension then
		if game_board[x][y] == original_colour then
			game_board[x][y] = 0

			local r1 = get_colours_count(game_board, x - 1, y, original_colour)
			local r2 = get_colours_count(game_board, x, y - 1, original_colour)
			local r3 = get_colours_count(game_board, x + 1, y, original_colour)
			local r4 = get_colours_count(game_board, x, y + 1, original_colour)
			for i=1,NUM_COLOURS do
				count_table[i] = r1[i] + r2[i] + r3[i] + r4[i]
			end
		elseif game_board[x][y] > 0 then
			local c = game_board[x][y]
			count_table[c] = fill_board(game_board, -1 * c, x, y, c)
		end
	end

	return count_table
end

--Returns a randomly coloured board of the indicated dimensions
function generate_board(board_dimension)
	math.randomseed(rb.current_tick()+os.time())

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
function fill_board(game_board, fill_colour, x, y, original_colour)
	--defaults
	x = x or 1
	y = y or 1
	fill_colour = fill_colour or selected_colour
	game_board = game_board or board
	original_colour = original_colour or game_board[1][1]

	if x > 0 and y > 0 and x <= board_dimension and 
		y <= board_dimension and game_board[x][y] == original_colour then

		game_board[x][y] = fill_colour
		return fill_board(game_board, fill_colour, x - 1, y, original_colour) + 
		       fill_board(game_board, fill_colour, x, y - 1, original_colour) +
		       fill_board(game_board, fill_colour, x + 1, y, original_colour) +
		       fill_board(game_board, fill_colour, x, y + 1, original_colour) + 1
	end

	return 0
end

--Draws the game board to screen
function draw_board()
	for x=1,board_dimension do
		for y=1,board_dimension do
			rb.lcd_set_foreground(COLOURS[board[x][y]])
			rb.lcd_fillrect((x-1)*block_width, (y-1)*block_width, block_width, block_width)
		end
	end
end

--Draw the colour chooser along with selected pip at the appropriate
--position
function draw_chooser()
	for i=1,NUM_COLOURS do
		rb.lcd_set_foreground(COLOURS[i])
		if LAYOUT == 1 then
			rb.lcd_fillrect(chooser_start_pos, (i - 1)*(chooser_height), chooser_width, chooser_height)
		elseif LAYOUT == 2 then
			rb.lcd_fillrect((i - 1)*(chooser_width), chooser_start_pos, chooser_width, chooser_height)
		end
	end

	rb.lcd_set_foreground(PIP_COLOURS[selected_colour])
	local xpos = 0
	local ypos = 0
	if LAYOUT == 1 then
		xpos = chooser_start_pos + (chooser_width - chooser_pip_dimension)/2
		ypos = (selected_colour-1)*(chooser_height) + (chooser_height - chooser_pip_dimension)/2
	elseif LAYOUT == 2 then
		xpos = (selected_colour-1)*(chooser_width) + (chooser_width - chooser_pip_dimension)/2
		ypos = chooser_start_pos + (chooser_height - chooser_pip_dimension)/2
	end
	rb.lcd_fillrect(xpos, ypos, chooser_pip_dimension, chooser_pip_dimension)
end

--Draws the current moves, par and high score
function draw_status()
	rb.lcd_set_foreground(rb.lcd_rgbpack(255,255,255))
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
			
			return rtn_str .. static_str
		end

		local start_height = NUM_COLOURS*chooser_height
		rb.lcd_putsxy(chooser_start_pos, start_height, calc_string("Move", ":"..num_moves))
		rb.lcd_putsxy(chooser_start_pos, start_height + TEXT_LINE_HEIGHT, calc_string("Par", ":"..par))
		if highscores[difficulty] then
			rb.lcd_putsxy(chooser_start_pos, start_height + TEXT_LINE_HEIGHT*2, 
				calc_string("Best", ":"..highscores[difficulty]))
		end
	elseif LAYOUT == 2 then
		local best_str = ""
		if highscores[difficulty] then
			best_str = " Best: "..highscores[difficulty]
		end
		rb.lcd_putsxy(0, chooser_start_pos - TEXT_LINE_HEIGHT - 1, 
			"Move: "..num_moves.." Par: "..par..best_str)
	end
end

--Convenience function to redraw the whole board to screen
function redraw_game()
	rb.lcd_clear_display()
	draw_board()
	draw_chooser()
	draw_status()
	rb.lcd_update()
end

--Checks whether the given board is a single colour
function check_win(game_board)
	for x=1,board_dimension do
		for y=1,board_dimension do
			if game_board[x][y] ~= game_board[1][1] then
				return false
			end
		end
	end

	return true
end

--Attempt to load the save file into the game variables
--Returns true on success, false otherwise
function load_game()
	local f = io.open(SAVE_FILE, "r")
	if f == nil then
		return false
	else
		difficulty = tonumber(f:read())
		--Set up the positioning variables
		init_variables(difficulty)

		par = tonumber(f:read())
		num_moves = tonumber(f:read())
		selected_colour = tonumber(f:read())

		board={}
		local dimension = diff_to_dimension(difficulty)
		for x=1,dimension do
			board[x] = {}
			local line = f:read()
			local bits = {line:match(("([^ ]*) "):rep(dimension))}
			for y=1,dimension do
				board[x][y] = tonumber(bits[y])
			end
		end

		f:close()
		return true
	end
end

--Saves the game state to file
function save_game()
	local f = io.open(SAVE_FILE, "w")
	f:write(difficulty,"\n")
	f:write(par,"\n")
	f:write(num_moves,"\n")
	f:write(selected_colour,"\n")
	for x=1,board_dimension do
		for y=1,board_dimension do
			f:write(board[x][y]," ")
		end
		f:write("\n")
	end
	f:close()
end

--Loads the high scores from file
--Returns true on success, false otherwise
function load_scores()
	local f = io.open(SCORES_FILE, "r")
	if f == nil then
		return false
	else
		highscores = {}
		for i=1,3 do
			local line = f:read()
			local value = false
			if line ~= nil then
				value = tonumber(line)
			end

			highscores[i] = value
		end
		f:close()
		return true
	end
end

--Saves the high scores to file
function save_scores()
	local f = io.open(SCORES_FILE, "w")
	for i=1,3 do
		local value = highscores[i]
		if value == false then
			value = ""
		end
		f:write(value,"\n")
	end
	f:close()
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
		redraw_game()
	elseif item == 1 then
		os.remove(SAVE_FILE)
		init_game(difficulty)
		redraw_game()
	elseif item == 2 then
		local diff = rb.do_menu("Difficulty", {"Easy", "Medium", "Hard"}, difficulty - 1, false)
		if diff < 0 then
			app_menu()
		else
			difficulty = diff + 1 --lua is 1 indexed
			os.remove(SAVE_FILE)
			init_game(difficulty)
			redraw_game()
		end
	elseif item == 3 then
		app_help()
		redraw_game()
	elseif item == 4 then
		os.remove(SAVE_FILE)
		os.exit()		
	elseif item == 5 then
		rb.splash(1, "Saving game...") --Will stay on screen till the app exits
		save_game()
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

----------------------------------
--Code under here is run on load--
----------------------------------

if not load_game() then
	init_game(difficulty)
end
load_scores()
redraw_game()

repeat
	local action = rb.get_action(rb.contexts.CONTEXT_KEYBOARD, -1)

	if action == rb.actions.ACTION_KBD_SELECT then
		if selected_colour ~= board[1][1] then
			fill_board()
			num_moves = num_moves + 1
			redraw_game()
			if check_win(board) then
				local par_diff = num_moves - par
				if not highscores[difficulty] or par_diff < highscores[difficulty] then
					rb.splash(3*rb.HZ, win_text(par_diff)..", a new high score!")
					highscores[difficulty] = par_diff
					save_scores()
				else
					rb.splash(3*rb.HZ, win_text(par_diff)..".")
				end
				os.remove(SAVE_FILE)
				os.exit()
			end
		end
	elseif action == rb.actions.ACTION_KBD_DOWN then
		if selected_colour < NUM_COLOURS then
			selected_colour = selected_colour + 1
			redraw_game()
		end
	elseif action == rb.actions.ACTION_KBD_UP then
		if selected_colour > 1 then
			selected_colour = selected_colour - 1
			redraw_game()
		end
	elseif action == 1 then 
		--TODO: Should I do a button_get(false) thing here to check for
		--the menu button?
		--app_menu()
	end
until action == rb.actions.ACTION_KBD_LEFT
