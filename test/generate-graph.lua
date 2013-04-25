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

function combine_nodes(graph, node1, node2)
  local function remove_from_set(list, number)
    local new_value = {}
    for _,v in pairs(list) do
      if v ~= number then
        table.insert(new_value, v)
      end
    end

    return new_value
  end
  local function add_to_set(list, number)
    local new_value = remove_from_set(list, number)
    table.insert(new_value, number)

    return new_value
  end

  assert (node1 ~= node2)
  local small, large = math.min(node1, node2), math.max(node1, node2)

  for _, other_node in pairs(graph.connections[large]) do
    if other_node ~= small then
      -- Point the larger nodes connections to the smaller node
      local upd_other = remove_from_set(graph.connections[other_node], large)
      upd_other = add_to_set(upd_other, small)
      graph.connections[other_node] = upd_other

      -- Combine the sets of connections into the smaller node
      local upd_small = add_to_set(graph.connections[small], other_node)
      graph.connections[small] = upd_small
    end
  end
  -- Remove the reference to the larger node from the small
  graph.connections[small] = remove_from_set(graph.connections[small], large)
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
  local key_group_number = nil
  local ind_con, con_group_number = nil, nil
  local function iter()
    if ind_con == nil then
      key_group_number = next(graph.connections, key_group_number)
      if key_group_number == nil then
        return nil
      end
    end

    -- If we've been merged
    if graph.connections[key_group_number] == nil then
      ind_con, con_group_number = nil, nil
      return iter()
    end

    ind_con, con_group_number = next(graph.connections[key_group_number], ind_con)

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

function get_connections(board)
  graph = board_to_nodes(board)
  fully_simplified = false
  while not fully_simplified do
    num_simplified = simplify_nodes(graph)
    fully_simplified = num_simplified == 0
  end

  return graph
end

function print_thing(a)
  for k,v in pairs(a.connections) do
    local row = k .. ": {"
    for _,itm in pairs(v) do
      row = row .. itm .. ", "
    end
    print(row.."}")
  end
end

test_board = {
  {1, 2, 1, 1, 1, 1},
  {1, 2, 1, 2, 2, 1},
  {1, 2, 1, 2, 2, 1},
  {1, 2, 1, 1, 2, 1},
  {1, 2, 2, 2, 2, 1},
  {1, 1, 1, 1, 1, 1},
}

a = get_connections(test_board)
print_thing(a)
