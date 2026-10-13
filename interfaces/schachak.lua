interface = load_interface("chessac")

function interface.setup_machine()
	sb_reset_board(":board")
	local promcode = 0
	emu.wait(3.5)


	interface.cur_level = 63
	interface.setlevel()
end

return interface
