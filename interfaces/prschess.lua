interface = {}

interface.level = 1
interface.cur_level = nil

function interface.get_module()
	return "SciSys President Chess"
end

function interface.get_author()
	return "Julio Kaplan & Craig Barnes"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = interface.level
	while output:get_indexed_value("7.", level - 1) == 0 do
		send_input(":IN.0", 0x80, 0.5) -- Level
	end
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		sb_clear_board(":board")
		emu.wait(2)
		send_input(":IN.1", 0x02, 1) -- Reset
		emu.wait(1)
		send_input(":IN.1", 0x40, 0.5) -- Verify/Setup
		send_input(":IN.1", 0x20, 0.5) -- Clear Board
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
						send_input(":IN.1", 0x80, 0.5) -- White
						emu.wait(0.5)
					end
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.2", 0x01 << (8 - math.abs(p)), 1)
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
		if mode * piece < 0 then
			send_input(":IN.1", 0x80, 0.5) -- White
			emu.wait(0.5)
		end
		send_input(":IN.1", 0x40, 0.5) -- Verify/Setup
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":IN.1", 0x08, 1) -- Player-Player
	else
		send_input(":IN.1", 0x04, 1) -- Player-Computer
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x08, 1)    -- Move
end

function interface.stop_play()
	send_input(":IN.0", 0x04, 1)    -- Interrupt
end

function interface.is_selected(x, y)
	return output:get_value((x - 1) .. "." .. (y - 1)) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 0.5, x, y, event)
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
	if     (output:get_value("8.6") ~= 0) then return 'q'
	elseif (output:get_value("8.2") ~= 0) then return 'r'
	elseif (output:get_value("8.4") ~= 0) then return 'b'
	elseif (output:get_value("8.3") ~= 0) then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	if piece == piece:lower() then
		if     (piece == "q") then send_input(":IN.2", 0x40, 1)
		elseif (piece == "r") then send_input(":IN.2", 0x20, 1)
		elseif (piece == "b") then send_input(":IN.2", 0x10, 1)
		elseif (piece == "n") then send_input(":IN.2", 0x08, 1)
		end
	end
	interface.select_piece(x, y, "")
	sb_promote(":board", x, y, piece)
end

return interface
