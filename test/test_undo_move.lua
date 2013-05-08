-- Tests the behaviour of the undo_move function

as_library = true
dofile("util/test.lua")
dofile("../pixel-painter.lua")

local board = {
  {1, 2},
  {3, 4},
}
graph_original = board_to_graph(board)

-- Test that undoing a move works
graph = board_to_graph(board)
move = combine_nodes(graph, 1, 2)
undo_move(graph, move)
assert(tables_equal(graph_original, graph))

-- Test that combining moves together works
move1 = combine_nodes(graph, 1, 2)
move2 = combine_nodes(graph, 1, 4)
combined_move = combine_moves({move1, move2})
undo_move(graph, combined_move)
assert(tables_equal(graph_original, graph))

-- Test that attempting to combine moves with a different
-- remaining_node throws an exception
move1 = combine_nodes(graph, 1, 2)
move2 = combine_nodes(graph, 3, 4)
status = pcall(combine_moves, {move1, move2})
assert(status == false)
