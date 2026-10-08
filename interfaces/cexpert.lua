interface = {}

interface.level = 1
interface.cur_level = nil
interface.firststart = true

function interface.get_module()
	return "Novag Constellation Expert"
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
	local level = math.abs(interface.level)
	send_input(":IN.6", 0x02, 1) -- Set Level
	local infinite = output:get_value("0.6") == 0 and output:get_value("0.5") ~= 0
	local training = output:get_value("8.1") ~= 0
	if (level == 0) then
		if (not infinite) then
			send_input(":IN.3", 0x02, 1) -- Infinite
		end
	else
		if (level < 9) then
			sb_press_square(":board", 0.5, 1, level)
		else
			sb_press_square(":board", 0.5, 1, 8)
			for i = 1, level - 8 do
				send_input(":IN.6", 0x02, 0.5) -- Set Level
			end
		end
		if (interface.level < 0 ~= training) then
			send_input(":IN.1", 0x02, 1) -- Training Level
		end
	end
	send_input(":IN.7", 0x01, 1) -- Go
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	send_input(":IN.0", 0x01, 1) -- New Game
	emu.wait(1)
	interface.cur_level = ""
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x02, 0.5) -- K
	elseif (n == 2) then send_input(":IN.1", 0x02, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.4", 0x02, 0.5) -- R
	elseif (n == 4) then send_input(":IN.2", 0x02, 0.5) -- B
	elseif (n == 5) then send_input(":IN.3", 0x02, 0.5) -- N
	elseif (n == 6) then send_input(":IN.5", 0x02, 0.5) -- P
	end
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.2", 0x02, 0.5) -- Sound
		send_input(":IN.1", 0x01, 0.5) -- Verify/Setup
		send_input(":IN.1", 0x01, 0.5) -- Verify/Setup
		sb_clear_board(":board")
		emu.wait(6)
		send_input(":IN.3", 0x01, 0.5) -- Clear Board
		machine.video.throttled = throttled_state
		return ("")
	else
		local piece = 7
		local z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x ,9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						send_input(":IN.2", 0x01, 0.5) -- Change Color
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
					sb_move_piece(":board", x, 9 - y)
					emu.wait(0.5)
					piece = p
				end
			end
		end
		send_input(":IN.7", 0x01, 0.5) -- GO
		if mode == -1 then
			send_input(":IN.2", 0x01, 0.5) -- Change Color
		end
		send_input(":IN.2", 0x02, 0.5) -- Sound
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	send_input(":IN.0", 0x02, 1) -- Player/Player
	emu.wait(1)
end

function interface.start_play(init)
	send_input(":IN.7", 0x01, 1) -- Go
end

function interface.is_selected(x, y)
	return output:get_indexed_value(tostring(x - 1) .. ".", 8 - y) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "-14", "14"},
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		value = value:gsub("_", " ")
		local level = tonumber(value)
		if (level < -14 or level > 14) then return end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local ram = emu.item(machine.devices[':maincpu'].items['0/0000-ffff'])
	local adr = 0x0370
	local piece = (ram:read(adr - 16 * (y - 1) + x - 1)) & 0x07
	if     piece == 0x05 then return 'q'
	elseif piece == 0x03 then return 'r'
	elseif piece == 0x04 then return 'b'
	elseif piece == 0x02 then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.1", 0x02, 1)
	elseif (piece == "r") then send_input(":IN.4", 0x02, 1)
	elseif (piece == "b") then send_input(":IN.2", 0x02, 1)
	elseif (piece == "n") then send_input(":IN.3", 0x02, 1)
	end
end

return interface
