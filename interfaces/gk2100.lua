interface = load_interface("gk2000")

interface.level = "a4"
interface.cur_level = nil
local promcode = 0

function interface.setup_machine()
	sb_reset_board(":board")
	promcode = 0
--	send_input(":IN.0", 0x01, 0.5) -- New Game
	emu.wait(6) -- the power-on LED sweep ends at ~4.6 s; a key pressed during it is lost

	interface.cur_level = "a4"
	interface.setlevel()
	interface.rotating.select_pages(true)
end

function interface.get_options()
	return {{"string", "Level", "a4"}, }
end

return interface
