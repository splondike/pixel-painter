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
function get_connections(board)
  graph = board_to_nodes(board)
  fully_simplified = false
  while not fully_simplified do
    num_simplified = simplify_nodes(graph)
    fully_simplified = num_simplified == 0
  end

  return graph
end

-- Don't know how to do this in Lua without internet, hence this
function len_map(map)
  local count = 0
  for _ in pairs(map) do
    count = count + 1
  end
  return count
end

function graph_solver(graph)
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

function print_thing(a)
  for k,v in pairs(a.connections) do
    local row = k .. ": {"
    for itm in pairs(v) do
      row = row .. itm .. ", "
    end
    print(row.."}")
  end
end

test_board = {
  {1, 2, 3, 1, 1, 1},
  {1, 2, 1, 2, 2, 1},
  {1, 2, 1, 2, 2, 1},
  {1, 2, 3, 1, 2, 1},
  {1, 2, 2, 2, 2, 1},
  {1, 1, 1, 1, 1, 1},
}

a = get_connections(test_board)
--print_thing(a)
solution = graph_solver(a)
local rtn = "{"
for _,move in pairs(solution) do
  rtn = rtn .. move .. ","
end
rtn = rtn .. "}"
print(rtn)
