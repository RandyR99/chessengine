interface = {}

local function led_on(name)
	local led = machine.devices[":"]:output(name)
	return led ~= nil and led:get() ~= 0
end

interface.turn = true
interface.invert = false
interface.color = "B"
interface.level = 1
interface.cur_level = nil
interface.set = false

function interface.get_module()
	return "Conic Computer Chess"
end

function interface.get_author()
	return "Stephen Chen"
end

function interface.setnumber(n)
	if     (n ==  1) then send_input(":IN.6", 0x01, 1)
	elseif (n ==  2) then send_input(":IN.5", 0x08, 1)
	elseif (n ==  3) then send_input(":IN.5", 0x04, 1)
	elseif (n ==  4) then send_input(":IN.5", 0x02, 1)
	elseif (n ==  5) then send_input(":IN.5", 0x01, 1)
	elseif (n ==  6) then send_input(":IN.4", 0x08, 1)
	elseif (n ==  7) then send_input(":IN.6", 0x04, 1)
	elseif (n ==  8) then send_input(":IN.6", 0x08, 1)
	elseif (n ==  9) then send_input(":IN.7", 0x01, 1)
	elseif (n == 10) then send_input(":IN.7", 0x02, 1)
	elseif (n == 11) then send_input(":IN.7", 0x04, 1)
	elseif (n == 12) then send_input(":IN.7", 0x08, 1)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = interface.level
	send_input(":IN.4", 0x04, 1) -- Level
	interface.setnumber(level)
	send_input(":IN.6", 0x02, 1) -- Clear
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.invert = false
	interface.color = "B"
	sb_reset_board(":board")
	emu.wait(8)
	local switch = false
	if (machine.devices[':maincpu'].spaces['program']:read_u8(0x13) == 0x04) then
		send_input(":IN.0", 0x08, 1)  -- Play
		switch = true
	end
	if (machine.devices[':maincpu'].spaces['program']:read_u8(0x07) == 0x01) then
		send_input(":IN.1", 0x02, 1)  -- White
		switch = true
	end
	if (switch) then
		send_input(":RESET", 0x01, 1) -- Reset
		emu.wait(8)
	end
	send_input(":IN.6", 0x02, 1)  -- Clear
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		sb_clear_board(":board")
		send_input(":IN.0", 0x04, 1)  -- Modify
		send_input(":RESET", 0x01, 0.5) -- RESET
		send_input(":IN.6", 0x02, 0.5) -- CLEAR
		machine.video.throttled = throttled_state
		return ("")
	else
		local piece = 7
		local z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p ~= piece then
						if p > 0 then
							z = 6 - p
						else
							z = 12 + p
						end
						interface.setnumber(z + 1)
					end
					send_input(":board:SPAWN", 0x01 << z, 0.09)
					sb_select_piece(":board", 1, x, 9 - y, "put")
					piece = p
				end
			end
		end
		if mode == -1 then
			machine.devices[':maincpu'].spaces['program']:write_u8(0x0007,0x01)
			send_input(":IN.1", 0x01, 1)  -- Black
			interface.color = "W"
		end
		send_input(":IN.0", 0x08, 1)  -- Play
		interface.set = true
	end
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if (init and not interface.set) then
		interface.turn = false
		interface.invert = true
		interface.color = "W"
		sb_rotate_board(":board")
		send_input(":IN.1", 0x01, 1)  -- Black
		send_input(":RESET", 0x01, 1) -- Reset
		emu.wait(1)
	else
		interface.turn = not interface.turn
		if (interface.color == "W") then
			interface.color = "B"
			send_input(":IN.1", 0x01, 1)  -- Black
		else
			interface.color = "W"
			send_input(":IN.1", 0x02, 1)  -- White
		end
		interface.set = false
	end
	send_input(":IN.4", 0x01, 1)  -- Enter
	machine.video.throttled = throttled_state
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	if (interface.invert) then
		x = 9 - x
		y = 9 - y
	end
	-- castling moves
	if (y == 8 or y == 1) then
		local d1 = (led_on((y - 1) .. "." .. 0))
		local d2 = (led_on((y - 1) .. "." .. 1))
		local d3 = (led_on((y - 1) .. "." .. 2))
		local d4 = (led_on((y - 1) .. "." .. 3))
		local d5 = (led_on((y - 1) .. "." .. 4))
		local d6 = (led_on((y - 1) .. "." .. 5))
		local d7 = (led_on((y - 1) .. "." .. 6))
		local d8 = (led_on((y - 1) .. "." .. 7))
		if (not interface.invert) then
			if (d1 and d3 and d4 and d5) then
				if (x == 5 or x == 3) then
					return true
				else
					return false
				end
			end
			if (d5 and d6 and d7 and d8) then
				if (x == 5 or x == 7) then
					return true
				else
					return false
				end
			end
		else
			if (d1 and d2 and d3 and d4) then
				if (x == 4 or x == 2) then
					return true
				else
					return false
				end
			end
			if (d4 and d5 and d6 and d8) then
				if (x == 4 or x == 6) then
					return true
				else
					return false
				end
			end
		end
	-- enpassant moves
	elseif (y == 4) then
		local d1 = (led_on(3 .. "." .. (x-2)))
		local d2 = (led_on(3 .. "." .. (x-1)))
		local d3 = (led_on(3 .. "." .. (x-0)))
		local d4 = (led_on(2 .. "." .. (x-1)))
		if (d2 and d4 and (d1 or d3)) then
			return false
		end
	elseif (y == 5) then
		local d1 = (led_on(4 .. "." .. (x-2)))
		local d2 = (led_on(4 .. "." .. (x-1)))
		local d3 = (led_on(4 .. "." .. (x-0)))
		local d4 = (led_on(5 .. "." .. (x-1)))
		if (d2 and d4 and (d1 or d3)) then
			return false
		end
	end
	return led_on((y - 1) .. "." .. (x - 1))
end

function interface.select_piece(x, y, event)
	if (interface.invert) then
		x = 9 - x
		y = 9 - y
	end
	if (event == "en_passant") then
		sb_remove_piece(":board", x, y)
		send_input(":IN.4", 0x01, 1) -- Enter
	else
		sb_select_piece(":board", 1, x, y, event)
		if (event == "put_castling") then
			send_input(":IN.4", 0x01, 1) -- Enter
		end
	end
	if (event == "put") then
		if (interface.turn) then
			send_input(":IN.4", 0x01, 1) -- Enter
			emu.wait(0.25)
		end
		interface.turn = not interface.turn
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "12" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 12) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	if (interface.invert) then
		x = 9 - x
		y = 9 - y
	end
	promotion_error(piece)
	sb_promote(":board", x, y, "q") -- TODO
end

return interface
