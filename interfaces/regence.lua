interface = {}

interface.level = 2
interface.cur_level = nil
interface.edit = false
local lastx = 0
local lasty = 0
local lastp = 0

function interface.get_module()
	return "La Régence"
end

function interface.get_author()
	return "Richard Lang"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	repeat
		send_input(":IN.1", 0x02, 0.5) -- Level
		local cur_level = 0
		for y = 0, 7 do
			if output:get_indexed_value("0.", 7 - y) ~= 0 then
				cur_level = cur_level + 1
			end
		end
	until cur_level == interface.level
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(1)
	send_input(":IN.0", 0x01, 1) -- Set Up
	send_input(":IN.0", 0x04, 1) -- New Game
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 2
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x08, 0.6) -- K
	elseif (n == 2) then send_input(":IN.0", 0x10, 0.6) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x20, 0.6) -- R
	elseif (n == 4) then send_input(":IN.0", 0x40, 0.6) -- B
	elseif (n == 5) then send_input(":IN.1", 0x40, 0.6) -- N
	elseif (n == 6) then send_input(":IN.1", 0x20, 0.6) -- P
	end
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.1", 0x01, 1) -- Sound
		send_input(":IN.0", 0x01, 1) -- Set Up
		emu.wait(1)
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
					if p * piece < 0 then
						if p > 0 then
							send_input(":IN.1", 0x10, 0.6) -- White
						else
							send_input(":IN.1", 0x08, 0.6) -- Black
						end
					end
					if math.abs(p) ~= math.abs(piece) then
						setpiece(math.abs(p))
					end
					if p > 0 then
						z = 6 - p
					else
						z = 12 + p
					end
					send_input(":board:SPAWN", 0x01 << z, 0.09)
					sb_select_piece(":board", 1, x, 9 - y, "put")
					piece = p
				end
			end
		end
		if mode == 1 then
			send_input(":IN.1", 0x10, 0.6) -- White
		else
			send_input(":IN.1", 0x08, 0.6) -- Black
		end
		send_input(":IN.0", 0x01, 1) -- Set Up
		send_input(":IN.1", 0x01, 1) -- Sound
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if on then
		send_input(":IN.1", 0x01, 1) -- Sound
		send_input(":IN.0", 0x01, 1) -- Set Up
	else
		if lastp > 0 then
			send_input(":IN.1", 0x08, 0.6) -- Black
		else
			send_input(":IN.1", 0x10, 0.6) -- White
		end
		send_input(":IN.0", 0x01, 1) -- Set Up
		send_input(":IN.1", 0x01, 1) -- Sound
	end
	interface.edit = on
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.1", 0x04, 1) -- Move / Halt
end

function interface.is_selected(x, y)
	return output:get_indexed_value(tostring(x - 1) .. ".", 8 - y) ~= 0
end

function interface.select_piece(x, y, event)
	if interface.edit then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		if event == "get" or event == "get_castling" then
			lastx = x
			lasty = y
			lastp = get_piece_id(x, y)
		elseif event == "put" or event == "put_castling" then
			local move_type = get_move_type(lastx, lasty, x, y)
			sb_select_piece(":board", 1, lastx, lasty, "get")
			if lastp > 0 then
				send_input(":IN.1", 0x10, 0.6) -- White
			else
				send_input(":IN.1", 0x08, 0.6) -- Black
			end
			if move_type == "promotion" or move_type == "capture_promotion" then
				setpiece(6) -- P
			else
				setpiece(math.abs(lastp))
			end
			sb_select_piece(":board", 1, x, y, "put")
		elseif event == "capture" or event == "en_passant" then
			sb_press_square(":board", 1, x, y)
			sb_remove_piece(":board", x, y)
		end
		machine.video.throttled = throttled_state
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "2", "1", "8" },
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
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_promote(":board", x, y, piece)
	if interface.edit then
		sb_select_piece(":board", 1, x, y, "get")
		if lastp > 0 then
			send_input(":IN.1", 0x10, 0.6) -- White
		else
			send_input(":IN.1", 0x08, 0.6) -- Black
		end
	end
	if     (piece == "q") then send_input(":IN.0", 0x10, 0.6)
	elseif (piece == "r") then send_input(":IN.0", 0x20, 0.6)
	elseif (piece == "b") then send_input(":IN.0", 0x40, 0.6)
	elseif (piece == "n") then send_input(":IN.1", 0x40, 0.6)
	end
	if interface.edit then
		sb_select_piece(":board", 1, x, y, "put")
	end
	machine.video.throttled = throttled_state
end

return interface
