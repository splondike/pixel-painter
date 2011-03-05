as_library = true
dofile("../pixel-painter.lua")

collectgarbage("stop")
test_board = load_game("stopper-pixel-painter.save")["board"]
print("Pre fill: "..collectgarbage("count"))
num_filled = fill_board(test_board, 0, 1, 1, 6)
print("Post fill: "..collectgarbage("count"))
