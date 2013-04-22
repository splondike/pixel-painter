as_library = true
dofile("../pixel-painter.lua")

local function print_board(board)
  output = ""
  for k,v in pairs(board) do
    for k1,v1 in pairs(v) do
      output = output .. v1 .. " "
    end
    output = output .. "\n"
  end
  print(output)
end

-- If top_down true, then iterate top left to bottom right
-- if false, then go the other way
local function board_iter(board, top_down)
  local dim = table.getn(board)
  local counter, max = 0, dim*dim
  return function() 
    counter = counter + 1
    if top_down then
      i = counter
    else
      i = max - counter + 1
    end
    if counter <= max then
      local ycoord, xcoord = math.ceil(i/dim), 1 + (i-1)%dim
      return {x = xcoord, y = ycoord}, board[ycoord][xcoord]
    end
  end
end

-- Get the other coords (depending on scan direction)
-- which are within bounds
local function get_current_coords(board_dim, currCoord, topToBottom)
  local within_board = {currCoord} -- I match myself
  if topToBottom then
    if currCoord.x < board_dim then
      table.insert(within_board, {x = currCoord.x + 1, y = currCoord.y})
    end
    if currCoord.y < board_dim then
      table.insert(within_board, {x = currCoord.x, y = currCoord.y + 1})
    end
  else
    if currCoord.x > 1 then
      table.insert(within_board, {x = currCoord.x - 1, y = currCoord.y})
    end
    if currCoord.y > 1 then
      table.insert(within_board, {x = currCoord.x, y = currCoord.y - 1})
    end
  end

  return within_board
end

local function color_board_to_groups_board(board)
  local board_dim = table.getn(board)
  local function filter_for_color(coords, color)
    local matching = {}
    for i,c in pairs(coords) do
      if board[c.y][c.x] == color then
        table.insert(matching, c)
      end
    end

    return matching
  end
  local function clone_with_inf(board)
    local rtn = {}
    for y = 1,board_dim do
      rtn[y] = {}
      for x = 1,board_dim do
        rtn[y][x] = math.huge
      end
    end
    return rtn
  end
  local function assign_groups(groups, next_group_num, top_to_bottom)
    local largest_group_num = 0
    for coord, color in board_iter(board, top_to_bottom) do
      local group_num = next_group_num()
      local within_board = get_current_coords(board_dim, coord, top_to_bottom)
      local matching_coords = filter_for_color(within_board, color)

      -- Find the smallest group number
      for i,oc in pairs(matching_coords) do
        if groups[oc.y][oc.x] < group_num then
          group_num = groups[oc.y][oc.x]
        end
      end

      -- Assign all the groups that number
      for i,coord in pairs(matching_coords) do
        groups[coord.y][coord.x] = group_num
      end

      -- Keep track of where the sweeper's up to
      if group_num > largest_group_num then
        largest_group_num = group_num
      end
    end

    return largest_group_num
  end

  -- Coordinate -> group number mapping
  local groups = clone_with_inf(board)

  -- Populate groups with the appropriate values

  local counter = 0
  local groups_counter = function()
    counter = counter + 1
    return counter
  end
  local last_largest_group_num = nil
  local still_changing = true
  local top_to_bottom = true
  while still_changing do
    local largest_group_num = assign_groups(groups, groups_counter, top_to_bottom)
 
    still_changing = (last_largest_group_num == nil) or
                     (largest_group_num ~= last_largest_group_num)

    last_largest_group_num = largest_group_num
    top_to_bottom = not top_to_bottom
  end

  return groups
end

function groups_board_to_connections(groups_board)
  local board_dim = table.getn(groups_board)
  local connections_map = {}
  for coord in board_iter(groups_board, top_to_bottom) do
    local all = get_current_coords(board_dim, coord, true)
    local curr_group = groups_board[coord.y][coord.x]
    for i,other_coord in pairs(all) do
      local other_group = groups_board[other_coord.y][other_coord.x]
      if curr_group ~= other_group then
        local key = ""
        if curr_group < other_group then
          key = curr_group .. "-" .. other_group
        else
          key = other_group .. "-" .. curr_group
        end
        connections_map[key] = true
      end
    end
  end

  local rtn = {}
  for k,_ in pairs(connections_map) do
    table.insert(rtn, k)
  end
  table.sort(rtn)

  return rtn
end

test_board = {
  {1, 2, 3, 1, 1, 1},
  {1, 2, 1, 2, 2, 1},
  {1, 2, 1, 2, 2, 1},
  {1, 2, 1, 1, 2, 1},
  {1, 2, 2, 2, 2, 1},
  {1, 1, 1, 1, 1, 1},
}

test_board = {
  {4, 2, 3, 5, 1, 1, 3, 1, 5, 5, 1, 2, 2, 6, 4, 1, 3, 6, 5, 1, 6, 4},
  {5, 3, 1, 4, 3, 5, 4, 6, 4, 6, 2, 4, 4, 4, 5, 6, 4, 2, 2, 5, 3, 6},
  {6, 6, 6, 4, 1, 5, 1, 4, 3, 6, 3, 4, 1, 4, 1, 6, 5, 2, 4, 5, 3, 1},
  {5, 4, 3, 2, 5, 6, 1, 2, 2, 6, 4, 3, 4, 2, 1, 6, 6, 4, 3, 4, 5, 1},
  {4, 4, 6, 1, 2, 4, 2, 6, 1, 2, 4, 5, 4, 2, 6, 5, 4, 6, 1, 2, 5, 3},
  {5, 1, 6, 3, 6, 3, 3, 5, 5, 4, 1, 5, 6, 2, 4, 4, 2, 5, 3, 5, 3, 5},
  {1, 1, 1, 4, 4, 5, 1, 3, 1, 4, 4, 6, 5, 1, 6, 1, 2, 2, 2, 3, 4, 6},
  {2, 4, 1, 4, 5, 3, 5, 1, 1, 6, 1, 1, 5, 3, 1, 6, 6, 1, 4, 3, 3, 3},
  {1, 5, 3, 3, 6, 2, 5, 6, 5, 4, 3, 5, 1, 3, 5, 1, 5, 4, 3, 2, 2, 3},
  {5, 3, 1, 2, 3, 3, 2, 4, 2, 1, 5, 5, 3, 2, 1, 3, 2, 1, 1, 2, 1, 3},
  {5, 2, 6, 1, 2, 5, 2, 2, 6, 6, 6, 4, 1, 6, 1, 6, 4, 3, 4, 4, 6, 4},
  {3, 6, 3, 6, 5, 1, 2, 2, 3, 4, 1, 3, 2, 4, 2, 4, 6, 4, 3, 1, 6, 3},
  {3, 1, 2, 6, 5, 4, 6, 1, 5, 4, 2, 2, 3, 1, 1, 2, 2, 3, 2, 2, 1, 6},
  {4, 2, 5, 5, 4, 6, 6, 1, 3, 6, 5, 3, 3, 5, 4, 6, 2, 4, 3, 2, 4, 4},
  {6, 3, 1, 6, 5, 4, 4, 3, 2, 6, 3, 3, 6, 4, 1, 4, 2, 3, 5, 3, 4, 6},
  {3, 2, 6, 6, 1, 1, 2, 4, 5, 2, 5, 4, 2, 3, 4, 4, 4, 1, 1, 6, 6, 1},
  {5, 6, 3, 2, 3, 2, 4, 4, 4, 1, 4, 3, 2, 5, 6, 2, 6, 5, 2, 2, 1, 3},
  {5, 1, 4, 2, 5, 1, 5, 2, 3, 6, 2, 3, 4, 4, 5, 6, 6, 1, 4, 2, 3, 1},
  {1, 4, 1, 1, 4, 4, 2, 4, 4, 5, 2, 6, 1, 6, 3, 3, 1, 3, 2, 6, 2, 3},
  {5, 4, 5, 4, 4, 1, 2, 2, 1, 2, 2, 1, 3, 3, 6, 4, 4, 6, 4, 1, 3, 3},
  {1, 3, 3, 5, 2, 2, 4, 5, 5, 6, 3, 2, 5, 2, 3, 5, 4, 2, 6, 3, 2, 4},
  {5, 5, 6, 6, 2, 4, 1, 6, 3, 4, 2, 3, 3, 5, 3, 4, 2, 2, 2, 1, 3, 6}
}

groupy = color_board_to_groups_board(test_board)
conns = groups_board_to_connections(groupy)

print_board(test_board)
print_board(groupy)
print(table.concat(conns, " "))

print(table.getn(conns))
--TODO: Even better... Instead of making groups map, and then the connections list
-- make something like this:
-- 1 -> {2, 3, 4}
-- 2 -> {1, 3}
-- 3 -> {1, 2}
-- 4 -> {1, 5}
-- 5 -> {4}
-- Then check, if 5 is the same color as 2, the map becomes:
-- 1 -> {2, 3, 4}
-- 2 -> {1, 3, 4}
-- 3 -> {1, 2}
-- 4 -> {1, 2}
-- This reduction strategy will be essential later for the tree searching algorithm
--
-- Thought: Maybe don't even bother including the smaller number in the bigger's list
-- the lookup strategy could be to search for the smaller number's thing. No, don't do
-- this, it will make merging 5 into 2 harder, since I'll need to scan all smaller
-- numbers to rejoin 5 correctly
