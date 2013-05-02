as_library = true
dofile("util/test.lua")
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

fill_board(test_board, 3, 1, 1, 1, non_matching)
assert(tables_equal(test_board, expected_result))

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

fill_board(test_board, 3, 1, 1, 1)
assert(tables_equal(test_board, expected_result))
