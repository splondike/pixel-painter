require("actions")

--The colours used by the game
local colours = {
	rb.lcd_rgbpack(255, 119, 34),
	rb.lcd_rgbpack(255, 255, 102),
	rb.lcd_rgbpack(119, 204, 51),
	rb.lcd_rgbpack(102, 170, 255),
	rb.lcd_rgbpack(51, 68, 255),
	rb.lcd_rgbpack(51, 51, 51),
}
local num_colours = table.getn(colours)
local difficulty = 2 --1:easy, 2:medium, 3:hard
local highscores = {false, false, false}

SCORES_FILE = "/pixel-painter.score"
SAVE_FILE = "/pixel-painter.save"

--Convenience function
function init_game(difficulty)
	init_variables(difficulty)
	board = generate_board(horizontal_dimension, vertical_dimension)
	par = calculate_par(board)
end

--Initialises the game variables at the given difficulty
function init_variables(difficulty)
	vertical_dimension = diff_to_dimension(difficulty)
	horizontal_dimension = vertical_dimension
	block_width = rb.LCD_HEIGHT / vertical_dimension --pixel dimension of each game square

	chooser_xpos = (horizontal_dimension)*block_width + 2 --xpos of the colour chooser
	chooser_width = rb.LCD_WIDTH - chooser_xpos
	chooser_height = rb.LCD_HEIGHT / num_colours - 6
	chooser_pip_width = 6 --pixel dimension of the selected colour pip

	--Game variables
	selected_colour = 1 --index of the current colour
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

--Returns the number of blocks which have changed colour between the two
--boards, used by calculate_par
function count_differences(board1, board2)
	local count = 0

	for x=1,horizontal_dimension do
		for y=1,vertical_dimension do
			if board1[x][y] ~= board2[x][y] then
				count = count + 1
			end
		end
	end

	return count
end

--Gets the move which fills in the most colour for the passed board,
--used by calculate_par
function get_preferred_colour(game_board)
	local biggest_change = 0
	local biggest_index = 0

	for i=1,num_colours do
		if i ~= game_board[1][1] then
			local board_copy = deepcopy(game_board)

			--Fill with zeroes after applying the colour so
			--count_differences works
			fill_board(board_copy, i)
			fill_board(board_copy, 0)

			local num_changed = count_differences(game_board, board_copy)
			if num_changed > biggest_change then
				biggest_index = i
				biggest_change = num_changed
			end
		end
	end

	return biggest_index
end

--Solves the board using a simple algorithm and returns the number of
--moves required
function calculate_par(game_board)
	local board_copy = deepcopy(game_board)
	local moves = 0

	repeat
		local colour = get_preferred_colour(board_copy)

		fill_board(board_copy, colour)
		moves = moves + 1
	until check_win(board_copy)

	return moves
end

--Returns a randomly coloured board of the indicated dimensions
function generate_board(horizontal_dimension, vertical_dimension)
	math.randomseed(rb.current_tick()+os.time())

	local board = {}
	for x=1,horizontal_dimension do
		board[x] = {}
		for y=1,vertical_dimension do
			board[x][y] = math.random(1,num_colours)
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

	if x > 0 and y > 0 and x <= horizontal_dimension and 
		y <= vertical_dimension and game_board[x][y] == original_colour then

		local count = 1

		game_board[x][y] = fill_colour
		count = count + fill_board(game_board, fill_colour, x - 1, y, original_colour)
		count = count + fill_board(game_board, fill_colour, x, y - 1, original_colour)
		count = count + fill_board(game_board, fill_colour, x + 1, y, original_colour)
		count = count + fill_board(game_board, fill_colour, x, y + 1, original_colour)

		return count
	end

	return 0
end

--Draws the game board to screen
function draw_board()
	for x=1,horizontal_dimension do
		for y=1,vertical_dimension do
			rb.lcd_set_foreground(colours[board[x][y]])
			rb.lcd_fillrect((x-1)*block_width, (y-1)*block_width, block_width, block_width)
		end
	end
end

--Draw the colour chooser on the side, along with selected pip
function draw_chooser()
	for i=1,num_colours do
		rb.lcd_set_foreground(colours[i])
		rb.lcd_fillrect(chooser_xpos, (i - 1)*(chooser_height), chooser_width, chooser_height)
	end

	rb.lcd_set_foreground(rb.lcd_rgbpack(0,0,0))
	local xpos = chooser_xpos + (chooser_width - chooser_pip_width)/2
	local ypos = (selected_colour-1)*(chooser_height) + (chooser_height - chooser_pip_width)/2
	rb.lcd_fillrect(xpos, ypos, chooser_pip_width, chooser_pip_width)
end

--TODO: Set the positions appropriately
--Draw the current moves, par and high score
function draw_moves()
	rb.lcd_set_foreground(rb.lcd_rgbpack(255,255,255))
	rb.lcd_putsxy(chooser_xpos, 140, "Mov: "..num_moves)
	rb.lcd_putsxy(chooser_xpos, 152, "Par: "..par)
	if highscores[difficulty] then
		rb.lcd_putsxy(chooser_xpos, 164, "Best: "..highscores[difficulty])
	end
end

--Convenience function to redraw the whole board to screen
function redraw_game()
	rb.lcd_clear_display()
	draw_board()
	draw_chooser()
	draw_moves()
	rb.lcd_update()
end

--Checks whether the given board is a single colour
function check_win(game_board)
	for x=1,horizontal_dimension do
		for y=1,vertical_dimension do
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
	for x=1,horizontal_dimension do
		for y=1,vertical_dimension do
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

--TODO: Do this
--Draws help to screen, waits for a keypress to exit
function app_help()
	rb.lcd_clear_display()

	local title = "Pixel painter help"
	local title_width = rb.font_getstringsize(title, 0, 0, rb.FONT_SYSFIXED)
	local title_xpos = (rb.LCD_WIDTH - title_width) / 2

	rb.lcd_putsxy(title_xpos, 0, title)
	rb.lcd_hline(title_xpos, title_xpos + title_width, 13)

	local body_text = [[
		The aim is to fill the screen with a single colour. A new colour is filled from the top left corner.

		The bottom right displays the number of moves taken, the score attained by the computer and your best score relative to the computer's.
	]]

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
		local diff = rb.do_menu("Difficulty", {"Easy", "Medium", "Hard"}, nil, false)
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
	elseif item == 4 then
		os.remove(SAVE_FILE)
		os.exit()		
	elseif item == 5 then
		save_game()
		os.exit()
	end
end

--Determine what victory text to show depending on the relation of the
--score to the calculated par value
function win_text(delta)
	if delta < 0 then
		return "You were "..(delta*-1).." under par"
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
		if selected_colour < num_colours then
			selected_colour = selected_colour + 1
			redraw_game()
		end
	elseif action == rb.actions.ACTION_KBD_UP then
		if selected_colour > 1 then
			selected_colour = selected_colour - 1
			redraw_game()
		end
	elseif action == 1 then --TODO: Do this properly
		app_menu()
	end
until action == rb.actions.ACTION_KBD_LEFT
