interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 2
interface.cur_level = nil
interface.player = false

function interface.get_module()
	return "CXG Chess 2001"
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
		send_input(":IN.1", 0x40, 0.3) -- Level
		emu.wait(1)
		local cur_level = 0
		for y = 0, 7 do
			if output_value("7." .. (7 - y)) ~= 0 then
				cur_level = cur_level + 1
			end
		end
		if (cur_level == 0) then
			cur_level = 8
			for y = 0, 3 do
				if output_value("6." .. (7 - y)) ~= 0 then
					cur_level = cur_level + 1
				end
			end
		end
	until cur_level == interface.level
	send_input(":IN.0", 0x80, 1) -- White
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(1)
	send_input(":IN.1", 0x02, 1) -- New Game
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 2
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x01, 0.5) -- Set Up
		sb_clear_board(":board")
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local piece = 7
		local z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						if p > 0 then
							send_input(":IN.0", 0x80, 0.5) -- White
						else
							send_input(":IN.0", 0x01, 0.5) -- Black
						end
					end
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x01 << math.abs(p), 0.5)
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
			send_input(":IN.0", 0x80, 0.5) -- White
		else
			send_input(":IN.0", 0x01, 0.5) -- Black
		end
		send_input(":IN.1", 0x01, 0.5) -- Set Up
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game(on)
	if on then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":IN.1", 0x01, 1) -- Set Up
		emu.wait(0.5)
		send_input(":IN.1", 0x20, 1) -- Move
		emu.wait(0.5)
		machine.video.throttled = throttled_state
	end
end

function interface.start_play(init)
	send_input(":IN.1", 0x20, 1) -- Move
	interface.player = false
end

function interface.is_selected(x, y)
	return output_value((x - 1) .. "." .. (8 - y)) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
	if event:match("^put") and interface.player == true then
		interface.player = false
		send_input(":IN.1", 0x20, 1) -- Move
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "2", "1", "12" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		value = value:gsub("_", " ")
		local level = tonumber(value)
		if (level < 1 or level > 12) then return end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x04, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x08, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x20, 1)
	end
end

return interface
