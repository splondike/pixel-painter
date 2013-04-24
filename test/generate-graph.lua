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

function combine_nodes(node_info, node1, node2)
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

  for _, other_node in pairs(node_info.connections[large]) do
    if other_node ~= small then
      -- Point the larger nodes connections to the smaller node
      local upd_other = remove_from_set(node_info.connections[other_node], large)
      upd_other = add_to_set(upd_other, small)
      node_info.connections[other_node] = upd_other

      -- Combine the sets of connections into the smaller node
      local upd_small = add_to_set(node_info.connections[small], other_node)
      node_info.connections[small] = upd_small
    end
  end
  -- Remove the reference to the larger node from the small
  node_info.connections[small] = remove_from_set(node_info.connections[small], large)
  -- Delete the larger node's info
  -- TODO: Work out a nice way of doing this, if it's even necessary
  -- to speed up the works
  node_info.colors[large] = nil
  node_info.connections[large] = nil
  --node_info.colors = compact_table(node_info.colors)
  --node_info.connections = compact_table(node_info.connections)
end

-- Simplifies a node collection by combining adjacent nodes of the same
-- color
-- NOTE: Mutates the passed in table (saves memory)
--
-- @return the number of nodes simplified
function simplify_nodes(node_info)
  -- Keep a separate copy of the nodes to iterate over while
  -- we're mutating the table
  local keys = {}
  local n = 0
  for key,value in pairs(node_info.connections) do
    n = n + 1 -- Faster than table.insert
    keys[n] = key
  end
  -- It's important we iterate in ascending order
  table.sort(keys)

  local combined_nodes = {}
  for _, curr_node in ipairs(keys) do
    if combined_nodes[curr_node] == nil then
      local curr_color = node_info.colors[curr_node]

      for _, connected_node in pairs(node_info.connections[curr_node]) do
        if node_info.colors[connected_node] == curr_color then
          print(curr_node, connected_node)
          print_thing(node_info)
          combine_nodes(node_info, curr_node, connected_node)
          combined_nodes[connected_node] = true
          -- This is wrong, curr could have been combined into connected
        end
      end
    end
  end

  return table.getn(combined_nodes)
end

function compact_table(table)
  local rtn = {}
  for k,v in pairs(table) do
    if v ~= nil then
      rtn[k] = v
    end
  end

  return rtn
end

function get_connections(board)
  node_info = board_to_nodes(board)
  fully_simplified = false
  while not fully_simplified do
    print_thing(node_info)
    num_simplified = simplify_nodes(node_info)
    fully_simplified = num_simplified == 0
  end

  return node_info
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
