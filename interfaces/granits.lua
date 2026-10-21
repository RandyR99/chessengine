interface = load_interface("fexcel")

function interface.get_module()
	return "Fidelity Granit S"
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(1)
	send_input(":IN.0", 0x80, 0.5) -- NEW GAME
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 6
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x20, 0.5) -- OPTIONS
		send_input(":board:RANK." .. tostring(1), 1 << (7 - 1), 0.5) -- Clear board
		send_input(":IN.0", 0x01, 0.5) -- CLEAR
		emu.wait(0.5)
		send_input(":IN.0", 0x01, 0.5) -- CLEAR
		emu.wait(1)
		send_input(":IN.0", 0x20, 0.5) -- OPTIONS
		send_input(":IN.0", 0x40, 0.5) -- VERIFY
		sb_clear_board(":board")
		machine.video.throttled = throttled_state
		return ("")
	else
		local piece = 7
		local z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x80 >> (math.abs(p)), 0.5)
					end
					send_input(":board:RANK." .. tostring(9 - y), 1 << (x - 1), 0.5)
					if p < 0 then
						emu.wait(0.5)
						send_input(":board:RANK." .. tostring(9 - y), 1 << (x - 1), 0.5)
					end
					if p > 0 then
						z = 6 - p
					else
						z = 12 + p
					end
					send_input(":board:SPAWN", 0x01 << z, 0.09)
					sb_move_piece(":board", x, 9 - y)
					emu.wait(0.5)
					piece = p
				end
			end
		end
		send_input(":IN.0", 0x01, 0.5) -- CLEAR
		if mode == -1 then
			send_input(":IN.0", 0x20, 0.5) -- OPTIONS
			send_input(":board:RANK." .. tostring(1), 1 << (5 - 1), 0.5) -- Change color
			send_input(":IN.0", 0x01, 0.5) -- CLEAR
			sb_select_piece(":board", 0.5, 5, 1, "")
		end
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.editing = on
	send_input(":IN.0", 0x20, 0.5) -- OPTIONS
	sb_press_square(":board", 0.1, 3, 1) -- Monitor mode
	send_input(":IN.0", 0x01, 0.5) -- CLEAR
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.select_piece(x, y, event)
	if interface.editing then
		emu.wait(1) -- in Monitor Mode the Granit misses a fast lift/put (Qd8-h4+ in chk_h)
	end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.start_play(init)
	send_input(":IN.0", 0x02, 1) -- MOVE
	emu.wait(1)
end

return interface
