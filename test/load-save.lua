#!/usr/bin/env lua

-----
-- bool= Loc_CoveringContents( tbl1, tbl2 )
--
-- Returns 'true' if 'tbl1' covers all entries of 'tbl2' (with identical contents).
-- This means that 'tbl2' is a subset of 'tbl1' entries.
-- Modified from: http://lua-users.org/lists/lua-l/2003-04/msg00181.html
--
local function Loc_CoveringContents( tbl1, tbl2 )
    --
    for k,v in pairs(tbl2) do
        --
        if (tbl1[k] ~= v) then
            
            if ((type(tbl1[k])~="table") or (type(v)~="table")) then
                --
                return false    -- some entry didn't exist or was different!
            end
            
            -- Subtables need to be dived into (different refs doesn't mean
            -- different contents).
            --
            if (not Loc_CoveringContents( tbl1[k], v )) then
                return false
            end
            
            -- go on...
        end
    end    
    
    return true     -- covered it all!
end

as_library = true
dofile("pixel-painter.lua")

--Test that load and save are inverse operations

--For the game state save
save_state = {}
save_state["difficulty"] = 1
save_state["par"] = 20
save_state["move_number"] = 10
save_state["selected_colour"] = 1
local board = {}
local dimension = diff_to_dimension(1)
for x=1,dimension do
	board[x] = {}
	for y=1,dimension do
		board[x][y] = x + y
	end
end
save_state["board"] = board
save_game(save_state, "test.save")

load_state = load_game("test.save")
assert(Loc_CoveringContents(save_state, load_state))
os.remove("test.save")

--For high score save
save_score = {1, 2, 3}
save_scores(save_score, "test.score")

load_score = load_scores("test.score")
assert(Loc_CoveringContents(save_score, load_score))
os.remove("test.score")

--Test that stuff works if we don't have permission or file doesn't
--exist

--For the game state save
rtn = save_game(save_state, "/dev/blah")
assert(not rtn)
rtn = load_game("/etc/shadow")
assert(not rtn)
rtn = load_game("/blahdyblah")
assert(not rtn)

--For high score save
rtn = save_scores(save_score, "/dev/blah")
assert(not rtn)
rtn = load_scores("/etc/shadow")
assert(not rtn)
rtn = load_scores("/blahdyblah")
assert(not rtn)
