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
dofile("../pixel-painter.lua")

test_board = {
	{1, 2, 1, 2},
	{1, 1, 1, 2},
	{2, 2, 1, 1},
	{1, 1, 1, 2},
}

expected_result = {
	{3, 2, 3, 2},
	{3, 3, 3, 2},
	{2, 2, 3, 3},
	{3, 3, 3, 2},
}
--Order is important to Loc_CoveringContents
expected_non_matching = {{3,2}, {3,1}, {1,2}, {2,4}, {4,4}, {1,4}}

non_matching = {}
num_filled = fill_board(test_board, 3, 1, 1, 1, non_matching)
--Remove duplicates from non_matching
temp = {}
for k,v in pairs(non_matching) do
	temp[v[1]..":"..v[2]] = v
end
non_matching = {}
for k, v in pairs(temp) do
	table.insert(non_matching, v)
end

assert(num_filled == 10)
assert(Loc_CoveringContents(test_board, expected_result))
assert(Loc_CoveringContents(non_matching, expected_non_matching))

test_board = {
	{1, 2, 1, 2, 1},
	{1, 2, 1, 1, 2},
	{1, 2, 2, 1, 2},
	{1, 1, 1, 1, 2},
	{2, 2, 2, 2, 1},
}

expected_result = {
	{3, 2, 3, 2, 1},
	{3, 2, 3, 3, 2},
	{3, 2, 2, 3, 2},
	{3, 3, 3, 3, 2},
	{2, 2, 2, 2, 1},
}

num_filled = fill_board(test_board, 3, 1, 1, 1)

assert(num_filled == 11)
assert(Loc_CoveringContents(test_board, expected_result))
