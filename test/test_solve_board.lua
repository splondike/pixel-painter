-- Test the behaviour of the solve_board function

as_library = true
dofile("util/test.lua")
dofile("../pixel-painter.lua")

function solve_board_finds_solution()
  local board = {
    {1, 2, 3},
    {3, 1, 2},
    {2, 3, 1},
  }

  local solution = solve_board(board)
  for _,color in ipairs(solution) do
    fill_board(board, color, 1, 1, board[1][1])
  end

  local expected_colour = board[1][1]
  for y,row in pairs(board) do
    for x,colour in pairs(row) do
      local msg = "("..x..","..y..") was " .. colour .. " not " .. expected_colour
      assert(colour == expected_colour, msg)
    end
  end
end

solve_board_finds_solution()
