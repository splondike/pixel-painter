require("actions")

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

function init_game(difficulty)
	init_variables(difficulty)
	generate_board()
end

--Initialises the game variables at the given difficulty
function init_variables(difficulty)
	vertical_dimension = diff_to_dimension(difficulty)
	horizontal_dimension = vertical_dimension
	block_width = rb.LCD_HEIGHT / vertical_dimension

	chooser_xpos = (horizontal_dimension)*block_width + 2
	chooser_width = rb.LCD_WIDTH - chooser_xpos
	chooser_height = rb.LCD_HEIGHT / num_colours - 6
	chooser_pip_width = 6

	--Game variables
	selected_colour = 1
	num_moves = 0
end

function generate_board()
	board = {}
	for x=1,horizontal_dimension do
		board[x] = {}
		for y=1,vertical_dimension do
			board[x][y] = math.random(1,num_colours)
		end
	end

end

--Flood fills the board from the top left using selected_colour
function fill_board(x, y, fill_colour)
	if x > 0 and y > 0 and x <= horizontal_dimension and 
		y <= vertical_dimension and board[x][y] == fill_colour then

		board[x][y] = selected_colour
		fill_board(x - 1, y, fill_colour)
		fill_board(x, y - 1, fill_colour)
		fill_board(x + 1, y, fill_colour)
		fill_board(x, y + 1, fill_colour)
	end
end

function draw_board()
	for x=1,horizontal_dimension do
		for y=1,vertical_dimension do
			rb.lcd_set_foreground(colours[board[x][y]])
			rb.lcd_fillrect((x-1)*block_width, (y-1)*block_width, block_width, block_width)
		end
	end
end

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

--TODO: Set the positions and text appropriately
function draw_moves()
	rb.lcd_set_foreground(rb.lcd_rgbpack(255,255,255))
	rb.lcd_putsxy(177, 140, "Mov: "..num_moves)
	rb.lcd_putsxy(177, 152, "Par: 20")
	if highscores[difficulty] then
		rb.lcd_putsxy(177, 164, "Best: "..highscores[difficulty])
	end
end

function redraw_game()
	rb.lcd_clear_display()
	draw_board()
	draw_chooser()
	draw_moves()
	rb.lcd_update()
end

function check_win()
	for x=1,horizontal_dimension do
		for y=1,vertical_dimension do
			if board[x][y] ~= board[1][1] then
				return false
			end
		end
	end

	return true
end

function load_game()
	local f = io.open(SAVE_FILE, "r")
	if f == nil then
		return false
	else
		difficulty = tonumber(f:read())
		--Set up the positioning variables
		init_variables(difficulty)

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

function save_game()
	local f = io.open(SAVE_FILE, "w")
	f:write(difficulty,"\n")
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

function save_scores()
	local f = io.open(SCORES_FILE, "w")
	for i=1,3 do
		rb.splash(100, i)
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

function app_help()
	redraw_game()
	--rb.lcd_clear_display()
	--rb.lcd_update()
	--local action = rb.get_action(rb.contexts.CONTEXT_KEYBOARD, -1)
end

--TODO: Some way of exiting difficulty menu back to main one, don't kill
--the save file then
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
		difficulty = diff + 1 --lua is 1 indexed
		os.remove(SAVE_FILE)
		init_game(difficulty)
		load_scores()
		redraw_game()
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

--Run on load

--if not load_game() then
	--init_game(difficulty)
--end
--load_scores()
--redraw_game()

--Joins and flattens the two variables into a single table up to a depth
--of 1
function table.append(tab, values)
	if type(values) == "table" then
		for key,val in pairs(values) do
			table.insert(tab, val)
		end
	elseif type(values) == "number" then
		table.insert(tab, values)
	end
end

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

function get_available_colours(game_board, x, y, original_colour)
	--defaults
	original_colour = original_colour or game_board[1][1]
	x = x or 1
	y = y or 1

	if x > 0 and y > 0 and x <= horizontal_dimension and 
		y <= vertical_dimension then

		if game_board[x][y] == original_colour then
			game_board[x][y] = 0
			local t = get_available_colours(game_board, x - 1, y, original_colour) or {}
			table.append(t,get_available_colours(game_board, x, y - 1, original_colour))
			table.append(t,get_available_colours(game_board, x + 1, y, original_colour))
			table.append(t,get_available_colours(game_board, x, y + 1, original_colour))

			return t
		elseif game_board[x][y] ~= 0 then
			return {game_board[x][y]}
		end
	end
end

init_game(3)
redraw_game()

repeat
	available_colours = get_available_colours(deepcopy(board))
	selected_colour = available_colours[math.random(1, table.getn(available_colours))]

	fill_board(1, 1, board[1][1])
	num_moves = num_moves + 1
	redraw_game()
until check_win()
rb.splash(3*rb.HZ, "You took " .. num_moves .. " moves.")
os.exit()

repeat
	local action = rb.get_action(rb.contexts.CONTEXT_KEYBOARD, -1)

	if action == rb.actions.ACTION_KBD_SELECT then
		if selected_colour ~= board[1][1] then
			fill_board(1, 1, board[1][1])
			num_moves = num_moves + 1
			redraw_game()
			if check_win() then
				if not highscores[difficulty] or num_moves < highscores[difficulty] then
					rb.splash(3*rb.HZ, num_moves .. " moves is a new high score.")
					highscores[difficulty] = num_moves
					save_scores()
				else
					rb.splash(3*rb.HZ, "You took " .. num_moves .. " moves.")
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
	elseif action == 1 then
		app_menu()
	end
until action == rb.actions.ACTION_KBD_LEFT
