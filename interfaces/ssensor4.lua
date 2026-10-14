interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 1
interface.cur_level = nil
interface.edit = false
local lastx = 0
local lasty = 0

function interface.get_module()
	return "Novag Super Sensor IV"
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
	repeat
		send_input(":IN.6", 0x02, 0.5) -- Set Level
		local cur_level = 0
		for y = 0, 7 do
			if output_value("1." .. y) ~= 0 then
				cur_level = cur_level + 1
			end
		end
	until cur_level == math.abs(interface.level)
	send_input(":IN.7", 0x01, 1) -- Go
	local tc = 0x00
	if (interface.level < 0 ) then
		tc = 0x08
	end
	if (machine.devices[":maincpu"].spaces["program"]:read_u8(0x58) & 0x08 ~= tc) then
		send_input(":IN.1", 0x02, 1) -- Time Control
	end
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	send_input(":IN.0", 0x01, 1) -- New Game
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
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
		send_input(":IN.3", 0x01, 0.5) -- Clear Board
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						send_input(":IN.2", 0x01, 0.5) -- Change Color
					end
					if math.abs(p) ~= math.abs(piece) then
						setpiece(math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9 - y)
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

function interface.edit_game(on)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if on then
		send_input(":IN.2", 0x02, 0.5) -- Sound
		send_input(":IN.1", 0x01, 0.5) -- Verify/Setup
		send_input(":IN.1", 0x01, 0.5) -- Verify/Setup
	else
		local c1 = false
		for i = 1, 5 do
			if output_value("0.7") ~= 0 then
				c1 = true
				break
			end
			emu.wait(0.2)
		end
		send_input(":IN.7", 0x01, 0.5) -- GO
		local c2 = false
		for i = 1, 5 do
			if output_value("0.7") ~= 0 then
				c2 = true
				break
			end
			emu.wait(0.2)
		end
		if c2 == c1 then
			send_input(":IN.2", 0x01, 0.5) -- Change Color
		end
		send_input(":IN.2", 0x02, 0.5) -- Sound
	end
	interface.edit = on
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.7", 0x01, 1) -- Go
end

function interface.is_selected(x, y)
	return (output_value("1." .. (8 - y)) ~= 0) and (output_value("2." .. (x - 1)) ~= 0)
end

function interface.select_piece(x, y, event)
	if interface.edit then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		if event == "get" or event == "get_castling" then
			lastx = x
			lasty = y
		elseif event == "put" or event == "put_castling" then
			local move_type = get_move_type(lastx, lasty, x, y)
			sb_select_piece(":board", 0.5, lastx, lasty, "get")
			if move_type == "promotion" or move_type == "capture_promotion" then
				setpiece(2) -- Q
			end
			sb_select_piece(":board", 0.5, x, y, "put")
		elseif event == "capture" or event == "en_passant" then
			sb_press_square(":board", 0.5, x, y)
			sb_remove_piece(":board", x, y)
			send_input(":IN.2", 0x01, 0.5) -- Change Color
		end
		machine.video.throttled = throttled_state
	elseif (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "-8", "8" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < -8 or level > 8) then
			return
		elseif (level == 0) then
			level = 1
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	sb_promote(":board", x, y, "q") -- TODO
end

return interface
