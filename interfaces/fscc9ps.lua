interface = load_interface("fscc9")

function interface.get_module()
	return "Fidelity Playmatic Sensory 9"
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x80, 0.5) -- RE
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local ram = machine.devices[':maincpu'].spaces['program']
		send_input(":IN.0", 0x20, 0.5) -- PB
		sb_clear_board(":board")
		local piece = 7
		local z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x20 >> (math.abs(p) - 1), 0.5)
					end
					if p > 0 then
						z = 6 - p
					else
						z = 12 + p
					end
					send_input(":board:SPAWN", 0x01 << z, 0.09)
					sb_select_piece(":board", 1, x, 9 - y, "put")
					if p < 0 then
						sb_select_piece(":board", 1, x, 9 - y, "get")
						sb_select_piece(":board", 1, x, 9 - y, "put")
					end
					piece = p
				end
			end
		end
		if mode == -1 then
			ram:write_u8(0x008b, 0x10)
		end
		send_input(":IN.0", 0x40, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		local ram = machine.devices[':maincpu'].spaces['program']
		ram:write_u8(0x00cd, ram:read_u8(0x00cd) | 0x40)
	end
end

return interface
