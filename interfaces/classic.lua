local interface = {}

interface.invert = false
interface.level = 1
interface.cur_level = nil

function interface.get_module()
	return "Fidelity Classic"
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	
	local root = machine.devices[":"]
	if not root then return end
	
	local level = interface.level
	repeat
		send_input(":IN.0", 0x08, 0.6) -- Level
		
		-- Modern non-deprecated node-object query format
		local level_node = root:output("0." .. tostring(level - 1))
		local level_val = level_node and level_node:get() or 0
	until level_val ~= 0
	
	send_input(":IN.0", 0x40, 0.6) -- Clear
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	interface.invert = false
	send_input(":IN.0", 0x40, 0.6) -- Clear
	emu.wait(0.6)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		return (":board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		
		local cpu = machine.devices[":maincpu"]
		if not cpu then return end
		
		-- FIXED: Target the internal volatile data RAM space cleanly
		local ram = cpu.spaces["data"]
		if not ram then return end
		
		send_input(":IN.0", 0x80, 0.6) -- NEW GAME
		send_input(":IN.0", 0x20, 0.6) -- PROBLEM
		
		-- FIXED: Utilizing the true modern write_u8 API memory method
		ram:write_u8(0x008c, 0x00)
		ram:write_u8(0x00fc, 0x00)
		
		send_input(":IN.0", 0x20, 0.6) -- PROBLEM
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x40 >> math.abs(p), 0.6)
					end
					sb_press_square(":board", 0.6, x, 9 - y)
					if p < 0 then
						sb_press_square(":board", 0.6, x, 9 - y)
					end
					piece = p
				end
			end
		end
		if mode == -1 then
			-- FIXED: Utilizing the true modern write_u8 API memory method
			ram:write_u8(0x0003, 0x00)
		end
		send_input(":IN.0", 0x40, 0.6) -- CLEAR
	end
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":IN.0", 0x01, 0.6) -- Move
end

function interface.stop_play()
	send_input(":IN.0", 0x01, 0.6) -- Move
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	
	local root = machine.devices[":"]
	if not root then return false end
	
	-- Modern non-deprecated node-object query format
	local x_node = root:output("1." .. tostring(x - 1))
	local y_node = root:output("0." .. tostring(y - 1))
	
	local xval = x_node and x_node:get() or 0
	local yval = y_node and y_node:get() or 0
	
	return xval ~= 0 and yval ~= 0
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	if (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1.2, x, y, event)
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
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	promotion_error(piece)
	sb_promote(":board", x, y, "q")	-- TODO
end

return interface

