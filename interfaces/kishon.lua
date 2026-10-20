interface = load_interface("chesster")

function interface.get_module()
	return "Fidelity Kishon Chesster"
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(1)
	send_input(":IN.0", 0x20, 1) -- OPTION
	emu.wait(1)
	sb_press_square(":board", 1, 8, 1) -- h1
	emu.wait(1)
	sb_press_square(":board", 1, 2, 1) -- b1
	emu.wait(1)
	send_input(":IN.0", 0x01, 1) -- CLEAR
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "a1"
	interface.setlevel()
end

function interface.select_piece(x, y, event)
	if (event == "get_castling") then
		emu.wait(1)
	end
	sb_select_piece(":board", 1, x, y, event)
	emu.wait(1)
end

return interface
