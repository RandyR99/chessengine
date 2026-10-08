interface = {}

interface.turn = true
interface.last_get = nil
interface.level = 1
interface.cur_level = nil
interface.edit = false

function interface.get_module()
	return "Chess Partner 2000"
end

function interface.get_author()
	return "Mike Johnson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.2", 0x08, 1) -- LEVEL
	if (interface.level <= 4)	then
		send_input(":IN." .. tostring(4-interface.level), 0x01, 1)
	else
		send_input(":IN." .. tostring(8-interface.level), 0x02, 1)
	end
	send_input(":IN.1", 0x04, 1) -- ENTER
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	interface.turn = true
	interface.last_get = nil
	send_input(":IN.3", 0x08, 1) -- NEW GAME
	interface.cur_level = 1
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.2", 0x02, 0.75) -- K
	elseif (n == 2) then send_input(":IN.3", 0x02, 0.75) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x01, 0.75) -- R
	elseif (n == 4) then send_input(":IN.1", 0x01, 0.75) -- B
	elseif (n == 5) then send_input(":IN.2", 0x01, 0.75) -- N
	elseif (n == 6) then send_input(":IN.3", 0x01, 0.75) -- P
	end
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.1", 0x08, 0.5) -- ENTER POS.
		send_input(":IN.3", 0x08, 0.5) -- NEW GAME
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					sb_press_square(":board", 0.5, x, 9-y)
					if p * piece < 0 then
						if p > 0 then
							send_input(":IN.1", 0x02, 0.5) -- White
						else
							send_input(":IN.0", 0x02, 0.5) -- Black
						end
					end
					setpiece(math.abs(p))
					send_input(":IN.1", 0x04, 0.5) -- ENTER
					piece = p
				end
			end
		end
		if mode == 1 then
			send_input(":IN.1", 0x02, 0.5) -- White
		else
			send_input(":IN.0", 0x02, 0.5) -- Black
		end
		send_input(":IN.1", 0x04, 0.5) -- ENTER
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	send_input(":IN.3", 0x04, 0.5) -- MULTIMOVE
	interface.edit = on
	emu.wait(0.5)
end

function interface.start_play(init)
	interface.turn = false
	send_input(":IN.1", 0x04, 1) -- ENTER
end

function interface.stop_play()
end

function interface.is_selected_int(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output:get_value("digit0")
	local d1 = output:get_value("digit1")
	local d2 = output:get_value("digit2")
	local d3 = output:get_value("digit3")
	if (d0 == 0 or d1 == 0) then
		return false
	end
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.is_selected(x, y)
	if (interface.is_selected_int(x, y)) then
		emu.wait(0.5)
		return interface.is_selected_int(x, y)
	end
	return false
end

function interface.select_piece(x, y, event)
	if (event == "get") then
		interface.last_get = {x=x, y=y}
	elseif (event == "put") then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local move_type = get_move_type(interface.last_get.x, interface.last_get.y, x, y)
		sb_select_piece(":board", 1, interface.last_get.x, interface.last_get.y, "get")
		sb_select_piece(":board", 1, x, y, "put")
		-- special moves require extra steps
		if (move_type == "castling" and x == 7) then
			sb_select_piece(":board", 1, 8, y, "get")
			sb_select_piece(":board", 1, 6, y, "put")
		elseif (move_type == "castling" and x == 3) then
			sb_select_piece(":board", 1, 1, y, "get")
			sb_select_piece(":board", 1, 4, y, "put")
		elseif (move_type == "en_passant") then
			sb_remove_piece(":board", x, interface.last_get.y)
			sb_press_square(":board", 1, x, interface.last_get.y)
		elseif (move_type == "capture") then
			sb_press_square(":board", 1, x, y)
		end
		if (interface.turn or interface.edit) then
			send_input(":IN.1", 0x04, 1) -- ENTER
		end
		interface.last_get = nil
		interface.turn = not interface.turn
		machine.video.throttled = throttled_state
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "8" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 8) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- TODO
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	sb_promote(":board", x, y, "q") -- TODO
end

return interface
