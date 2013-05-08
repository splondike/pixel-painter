-- Tests the behaviour of the undo_move function

as_library = true
dofile("util/test.lua")
dofile("../pixel-painter.lua")

local board = {
  {1, 2},
  {3, 4},
}
graph_original = board_to_graph(board)

graph = board_to_graph(board)
move = combine_nodes(graph, 1, 2)
undo_move(graph, move)

assert(tables_equal(graph_original, graph))
