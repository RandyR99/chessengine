interface = load_interface("centurion")

function interface.setup_machine()
	sb_reset_board(":board")
	interface.invert = false
	promcode = 0
--	send_input(":IN.0", 0x01, 0.5) -- New Game
	emu.wait(6) -- the power-on LED sweep ends at ~4.6 s; a key pressed during it is lost

	interface.cur_level = "a4"
	interface.setlevel()
	interface.rotating.select_pages()
end

return interface
