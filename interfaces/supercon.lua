interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 2
interface.cur_level = nil

function interface.get_module()
	return "Novag Super Constellation"
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
	until cur_level == interface.level
	send_input(":IN.7", 0x01, 1) -- Go
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	send_input(":IN.0", 0x01, 1) -- New Game
	emu.wait(5)
	machine.video.throttled = throttled_state
	interface.cur_level = 2
	interface.setlevel()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.6", 0x02, 1) -- Set Level
	local d0 = output_value("0.2")
	if d0 == 0 then
		send_input(":IN.2", 0x02, 1) -- Depth Search
	end
	send_input(":IN.7", 0x01, 1) -- Go
	machine.video.throttled = throttled_state
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

function interface.edit_game()
	send_input(":IN.0", 0x02, 1) -- MultiMove
	emu.wait(1)
end

function interface.start_play(init)
	send_input(":IN.7", 0x01, 1) -- Go
end

function interface.is_selected(x, y)
	return (output_value("1." .. (8 - y)) ~= 0) and (output_value("2." .. (x - 1)) ~= 0)
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
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

function interface.get_promotion_led()
	if     (output_value("0.1") ~= 0) then return 'q'
	elseif (output_value("0.4") ~= 0) then return 'r'
	elseif (output_value("0.2") ~= 0) then return 'b'
	elseif (output_value("0.3") ~= 0) then return 'n'
	end
	return nil
end

function interface.get_promotion(x, y)
	for i = 1, 5 do
		local p = interface.get_promotion_led()
		if (p ~= nil) then
			return p
		end
		emu.wait(0.25)
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	emu.wait(1)
	if     (piece == "q") then send_input(":IN.1", 0x02, 1)
	elseif (piece == "r") then send_input(":IN.4", 0x02, 1)
	elseif (piece == "b") then send_input(":IN.2", 0x02, 1)
	elseif (piece == "n") then send_input(":IN.3", 0x02, 1)
	end
end

return interface
