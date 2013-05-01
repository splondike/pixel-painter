as_library = true
dofile("/pixel-painter.lua")

game = load_game("/data/speed-test.save")
if not game then
	rb.splash(rb.HZ * 5, "Please ensure pixel-painter-test.save exists in the root directory with pixel-painter.lua and speed-test.lua.")
	os.exit()
end

function do_calcs()
	start = os.time()
	for i=1,20 do
		local par = calculate_par(game["board"])
		assert(par == game["par"])
	end
	stop = os.time()
	return stop - start
end

if rb.audio_status() ~= 1 then
	rb.splash(rb.HZ * 2, "Please enqueue some music into a playlist and start it playing.")
	os.exit()
end

music_playing = do_calcs()
rb.audio_stop()
no_music = do_calcs()

local f = io.open("/speed-test-results.txt", "w")
f:write("With music: ", music_playing,"\n")
f:write("Without music: ", no_music)
f:close()
