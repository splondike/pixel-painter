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

-- Turns the board's 2d matrix representation
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
        table.insert(connections_map[curr_node_id], other_node_id)
        table.insert(connections_map[other_node_id], curr_node_id)
        node_colors[other_node_id] = board[y][x + 1]
      end
      if y < board_dim then
        local other_node_id = xy_to_flat(x, y + 1)
        table.insert(connections_map[curr_node_id], other_node_id)
        table.insert(connections_map[other_node_id], curr_node_id)
        node_colors[other_node_id] = board[y + 1][x]
      end
    end
  end

  return {connections = connections_map, colors = node_colors}
end

-- Simplifies a node collection by combining adjacent nodes of the same
-- color
function simplify_nodes(node_info)
  local simplified_node_info = {connections = {}, colors = {}}

  -- TODO: Check pairs() goes from lowest to highest, otherwise problems
  -- with combining toward the lowest group number and skipping merged nodes
  for curr_node, connected_nodes in pairs(node_info.connections) do
    local curr_color = node_info.colors[curr_node]
    -- Skip here if already combined

    simplified_node_info.connections[curr_node] = {}
    for _, connected_node in pairs(connected_nodes) do
      if node_info.colors[connected_node] == curr_color then
        local other_connections = node_info.connections[connected_node]

      else
        table.insert(simplified_node_info.connections[curr_node], connected_node)
      end
    end
  end

  return simplified_node_info
end

function get_connections(board)
  unsimplified_node_info = board_to_nodes(board)
end

test_board = {
  {1, 2, 3, 1, 1, 1},
  {1, 2, 1, 2, 2, 1},
  {1, 2, 1, 2, 2, 1},
  {1, 2, 1, 1, 2, 1},
  {1, 2, 2, 2, 2, 1},
  {1, 1, 1, 1, 1, 1},
}

a = get_connections(test_board)

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
