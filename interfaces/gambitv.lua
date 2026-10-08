local interface = {}

interface.level = 1
interface.cur_level = nil
interface.prom = false
interface.invert = false

function interface.get_module()
	if machine.system.name == "gambitv" then
		return "Fidelity Gambit Voice"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	interface.cur_level = interface.level
	local root = machine.devices[":"]
	if not root then return end

	repeat
		send_input(":IN.0", 0x08, 0.6) -- LV
		emu.wait(0.5)
		
		-- Modern non-deprecated node-object query layout
		local level_node = root:output("0." .. tostring(interface.level - 1))
		local level_val = level_node and level_node:get() or 0
	until level_val ~= 0
	
	send_input(":IN.0", 0x40, 1) -- CL
end

function interface.setup_machine()
	emu.wait(5)
	send_input(":IN.0", 0x80, 1) -- RE
	sb_reset_board(":board")
	emu.wait(1.0)
	send_input(":IN.0", 0x40, 1) -- CL
	emu.wait(1.0)
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
	
	-- Modern non-deprecated node-object query layout
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
		sb_select_piece(":board", 1, x, y, event)
	end
	emu.wait(0.5)
end

function interface.get_options() 
	return {{"spin", "Level", "1", "1", "8"}} 
end

function interface.set_option(name, value)
	if (name == "level") then
		value = value:gsub("_", " ")
		local level = tonumber(value)
		if (level < 1 or level > 8) then return end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	interface.prom = true
	return 'q'
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board", x, y, piece)
	piece = string.lower(piece)
	if interface.prom == false then
		if (piece == "q") then
			send_input(":IN.0", 0x10, 1)
		elseif (piece == "r") then
			send_input(":IN.0", 0x08, 1)
		elseif (piece == "b") then
			send_input(":IN.0", 0x04, 1)
		elseif (piece == "n") then
			send_input(":IN.0", 0x02, 1)
		end
	end
	interface.prom = false
end

function interface.set_pos(mode)
	if mode == 0 then
		return (":board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		
		local cpu = machine.devices[":maincpu"]
		if not cpu then return end
		
		-- Target internal volatile data RAM space cleanly
		local ram = cpu.spaces["data"]
		if not ram then return end
		
		send_input(":IN.0", 0x20, 0.6) -- PROBLEM
		
		-- Utilizing modern write_u8 API memory method
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
			-- Utilizing modern write_u8 API memory method
			ram:write_u8(0x0003, 0x00) 
		end
		send_input(":IN.0", 0x40, 0.6) -- CLEAR
		interface.setlevel()
		machine.video.throttled = throttled_state
	end
end

return interface

