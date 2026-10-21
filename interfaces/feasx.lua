interface = load_interface("feas")

-- the experimental A/S has no speech: no voice on/off around the setup

function interface.get_module()
	return "Fidelity Elite A/S Experimental"
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x01, 0.5) -- GAME CONTROL
		sb_press_square(":board", 0.5, 4, 7) -- Clear board
		send_input(":IN.1", 0x02, 0.5) -- CL
		send_input(":IN.0", 0x04, 0.5) -- PB
		sb_clear_board(":board")
		machine.video.throttled = throttled_state
		return ("")
	else
		local piece=7
		local z
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if math.abs(p)~=math.abs(piece) then
						send_input(":IN.0", 0x01<<(math.abs(p)+1), 0.5)
					end
					if p>0 then
						z=6-p
					else
						z=12+p
					end
					send_input(":board:SPAWN", 0x01<<z, 0.09)
					sb_select_piece(":board", 1, x, 9-y, "put")
					if p<0 then
						sb_select_piece(":board", 1, x, 9-y, "get")
						sb_select_piece(":board", 1, x, 9-y, "put")
					end
					piece=p
				end
			end
		end
		send_input(":IN.1", 0x02, 0.5) -- CL
		if mode==-1 then
			send_input(":IN.0", 0x01, 0.5) -- GAME CONTROL
			sb_press_square(":board", 0.5, 4, 5) -- Change color
			send_input(":IN.1", 0x02, 0.5) -- CL
		end
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	send_input(":IN.0", 0x01, 0.5) -- GAME CONTROL
	sb_press_square(":board", 0.5, 5, 6)
	send_input(":IN.1", 0x02, 0.5) -- CL
	emu.wait(0.5)
end

return interface
