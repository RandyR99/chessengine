interface = {}

interface.turn = true
interface.invert = false
interface.selected = {}
interface.selected_cnt = 0
interface.level = 1
interface.cur_level = nil

function interface.get_module()
	if machine.system.name == "savant" then
		return "Novag Savant"
	elseif machine.system.name == "savant2" then
		return "Novag Savant II"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "David Kittinger"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level_id = { 0x182418, 0x381010, 0x3c1818, 0x3c383c, 0x207c20, 0x1c1c3c, 0x181c18, 0x04103c, 0x181818, 0x183818 }
	repeat
		local levid = 0
		send_input(":IN.2", 0x04, 1) -- Set Level
		for x = 0, 7 do
			if (output:get_value(tostring(x) .. "." .. tostring(50 - (8 - 1) * 3)) == 1) then levid = levid | (1 << x)	end
			if (output:get_value(tostring(x) .. "." .. tostring(50 - (5 - 1) * 3)) == 1) then levid = levid | (1 << (8 + x))	end
			if (output:get_value(tostring(x) .. "." .. tostring(50 - (2 - 1) * 3)) == 1) then levid = levid | (1 << (16 + x))	end
		end
	until level_id[interface.level + 1] == levid
	send_input(":IN.1", 0x10, 1) -- Return
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.invert = false
	interface.selected = {}
	interface.selected_cnt = 0
	emu.wait(1)
	send_input(":IN.2", 0x08, 1) -- New Game
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function setpiece(n)
	if     (n == 2) then send_input(":IN.1", 0x40, 1) -- Q
	elseif (n == 3) then send_input(":IN.1", 0x04, 1) -- R
	elseif (n == 4) then send_input(":IN.0", 0x40, 1) -- B
	elseif (n == 5) then send_input(":IN.0", 0x04, 1) -- N
	elseif (n == 6) then send_input(":IN.2", 0x04, 1) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x04, 1) -- Sound on/off
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		if mode == -1 then
			send_input(":IN.2", 0x10, 1) -- Go
			emu.wait(2)
		end
		send_input(":IN.2", 0x80, 1) -- Set Up
		send_input(":IN.0", 0x80, 1) -- Clear Board
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, y)
				if p == -1 then
					sb_press_square(":board", 1, 5, 8)
					sb_press_square(":board", 1, x, y)
				elseif p == 1 then
					sb_press_square(":board", 1, 5, 1)
					sb_press_square(":board", 1, x, y)
				end
			end
		end
		local piece = 1
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if math.abs(p) > 1 then
					if p * piece < 0 then
						send_input(":IN.1", 0x80, 1) -- Change Color
					end
					setpiece(math.abs(p))
					sb_press_square(":board", 1, x, 9 - y)
					piece = p
				end
			end
		end
		send_input(":IN.2", 0x80, 1) -- Set Up
		if mode == -1 then
			send_input(":IN.1", 0x80, 1) -- Change Color
			interface.invert = true
		end
		send_input(":IN.0", 0x04, 1) -- Sound on/off
	end
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x80, 1) -- Change Color
	send_input(":IN.2", 0x10, 1) -- Go
	interface.turn = not interface.turn
	interface.invert = not interface.invert
	machine.video.throttled = throttled_state
end

function interface.stop_play()
	send_input(":IN.2", 0x10, 1) -- Go
end

function interface.is_pos_selected(x, y, piece)
	local piece_id = get_piece_id(x, y)
	local selected = (piece_id == 0 and piece ~= 0) or (piece_id > 0 and piece <= 0) or (piece_id < 0 and piece >= 0)
	if (selected) then
		interface.selected[y*10+x] = piece_id
	end

	-- ignore the rook in castling
	if     (y == 1 and (x == 8 or x == 6) and (interface.selected[1*10+5] ==  1 and interface.selected[1*10+7] == 0 and interface.selected[1*10+8] ==  3)) then	return false	-- white kingside castling
	elseif (y == 1 and (x == 1 or x == 4) and (interface.selected[1*10+5] ==  1 and interface.selected[1*10+3] == 0 and interface.selected[1*10+1] ==  3)) then	return false	-- white queenside castling
	elseif (y == 8 and (x == 8 or x == 6) and (interface.selected[8*10+5] == -1 and interface.selected[8*10+7] == 0 and interface.selected[8*10+8] == -3)) then	return false	-- black kingside castling
	elseif (y == 8 and (x == 1 or x == 4) and (interface.selected[8*10+5] == -1 and interface.selected[8*10+3] == 0 and interface.selected[8*10+1] == -3)) then	return false	-- black queenside castling

	-- ignore en-passant capture
	elseif (y == 5 and x < 8 and piece_id == -6 and interface.selected[(y+1)*10+x] == 0 and interface.selected[y*10+(x+1)] ==  6) then	return false	-- white en passant
	elseif (y == 5 and x > 1 and piece_id == -6 and interface.selected[(y+1)*10+x] == 0 and interface.selected[y*10+(x-1)] ==  6) then	return false	-- white en passant
	elseif (y == 4 and x < 8 and piece_id ==  6 and interface.selected[(y-1)*10+x] == 0 and interface.selected[y*10+(x+1)] == -6) then	return false	-- black en passant
	elseif (y == 4 and x > 1 and piece_id ==  6 and interface.selected[(y-1)*10+x] == 0 and interface.selected[y*10+(x-1)] == -6) then	return false	-- black en passant
	end
	if (x == 1 and y == 1) then
		interface.selected_cnt = interface.selected_cnt + 1
	end
	if (interface.selected_cnt >= 25) then
		interface.selected_cnt = 0
		interface.selected = {}
	end

	-- wait complete scan before report selections
	if (interface.selected_cnt <= 3) then
		return false
	end
	return selected
end

function interface.is_selected_int(x, y)
	local piece0 = output:get_value(tostring(x - 1) .. "." .. tostring(50 - (y - 1) * 3))
	local piece1 = output:get_value(tostring(x - 1) .. "." .. tostring(23 - (y - 1) * 3))
	if (interface.invert) then
		piece0 = output:get_value(tostring(8 - x) .. "." .. tostring(50 - (8 - y) * 3))
		piece1 = output:get_value(tostring(8 - x) .. "." .. tostring(23 - (8 - y) * 3))
	end
	local piece = 0
	if (piece0 == 1 and piece1 == 1) then		piece = -1
	elseif (piece0 == 1 and piece1 == 0) then	piece = 1
	end
	return interface.is_pos_selected(x, y, piece)
end

function interface.is_selected(x, y)
	if (interface.is_selected_int(x, y)) then
		emu.wait(0.5)
		return interface.is_selected_int(x, y)
	end
	return false
end

function interface.select_piece(x, y, event)
	if (interface.invert) then
		x = 9 - x
		y = 9 - y
	end
	if (interface.turn) then
		if (event == "get" or event == "put") then
			sb_select_piece(":board", 1, x, y, event)
		end
	end
	if (event == "put") then
		interface.turn = not interface.turn
		interface.selected = {}
		interface.selected_cnt = 0
		emu.wait(2)
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "0", "9" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 0 or level > 9) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local   piece =  tostring(output:get_value(tostring(x - 1) .. "." .. tostring(22 - (y - 1) * 3)))
	piece = piece .. tostring(output:get_value(tostring(x - 1) .. "." .. tostring(49 - (y - 1) * 3)))
	piece = piece .. tostring(output:get_value(tostring(x - 1) .. "." .. tostring(21 - (y - 1) * 3)))
	piece = piece .. tostring(output:get_value(tostring(x - 1) .. "." .. tostring(48 - (y - 1) * 3)))
	if     piece == "0110" then return 'q'
	elseif piece == "0100" then return 'r'
	elseif piece == "0011" then return 'b'
	elseif piece == "1000" then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	if interface.turn == false and interface.get_promotion(x, y) ~= piece:lower() then
		send_input(":IN.2", 0x40, 1) -- Promote
		if     piece == "q" then send_input(":IN.1", 0x40, 1)
		elseif piece == "r" then send_input(":IN.1", 0x04, 1)
		elseif piece == "b" then send_input(":IN.0", 0x40, 1)
		elseif piece == "n" then send_input(":IN.0", 0x04, 1)
		end
	end
end

return interface
