local interface = {}

local module = machine.images[':cartslot'].filename
interface.level = 1
interface.cur_level = nil

function interface.get_module()
	if machine.system.name == "miniscc" then
		return "Fidelity Mini Sensory v2"
	else
		return machine.system.description
	end
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
		send_input(":IN.0", 0x08, 0.6) -- LV
		
		local level_node = root:output("0." .. tostring(level - 1))
		local level_val = level_node and level_node:get() or 0
	until level_val ~= 0
	
	send_input(":IN.0", 0x40, 0.6) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	send_input(":IN.0", 0x80, 0.6) -- RE
	emu.wait(0.6)
	send_input(":IN.0", 0x40, 0.6) -- CL
	emu.wait(0.6)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		if module == "cbo" then
			return ("ERROR: 'Setup' mode is not working with module 'cbo'!")
		end
		return (":board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		
		local cpu = machine.devices[":maincpu"]
		if not cpu then return end
		
		local ram = cpu.spaces["data"]
		if not ram then return end
		
		send_input(":IN.0", 0x20, 0.6) -- PB
		for i = 0, 31 do
			ram:write_u8(0x0020 + i, 0x00)
		end
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
			local adr = 0x0003
			local val = 0xff
			if module == "cac" then
				val = 0x00
			end
			ram:write_u8(adr, val)
		end
	end
	send_input(":IN.0", 0x40, 0.6) -- CL
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 0.6) -- RV
end

function interface.stop_play()
	send_input(":IN.0", 0x02, 0.6) -- DM
end

function interface.is_selected(x, y)
	local root = machine.devices[":"]
	if not root then return false end

	local x_node = root:output("1." .. tostring(x - 1))
	local y_node = root:output("0." .. tostring(y - 1))
	
	local xval = x_node and x_node:get() or 0
	local yval = y_node and y_node:get() or 0
	
	return xval ~= 0 and yval ~= 0
end

function interface.select_piece(x, y, event)
	if (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
	end
end

function interface.get_options()
	if (module == "cac") then
		return {
			{ "spin", "Level", "1", "1", "6" },
		}
	else
		return {
			{ "spin", "Level", "1", "1", "4" },
		}
	end
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		local maxlevel = 4
		if (module == "cac") then
			maxlevel = 6
		end
		if (level < 1 or level > maxlevel) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.test_promotion(x, y)
	local function piece_led(port, code, x, y)
		local root = machine.devices[":"]
		if not root then return false end

		for n=1,8 do
			send_input(port, code, 0.5)
			for i=1,4 do
				local c_node = root:output("1." .. tostring(x - 1))
				local r_node = root:output("0." .. tostring(y - 1))
				local c_val = c_node and c_node:get() or 0
				local r_val = r_node and r_node:get() or 0

				if c_val ~= 0 and r_val ~= 0 then
					return true
				end
				emu.wait(0.15)
			end
		end
		return false
	end

	local p
	local throttled_state = machine.video.throttled
	machine.video.throttled = false

	if     piece_led(":IN.0", 0x10, x, y) then p = "Q"
	elseif piece_led(":IN.0", 0x02, x, y) then p = "N"
	elseif piece_led(":IN.0", 0x04, x, y) then p = "B"
	elseif piece_led(":IN.0", 0x08, x, y) then p = "R"
	else p = "Q"
	end

	send_input(":IN.0", 0x40, 1) -- CL
	machine.video.throttled = throttled_state
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	if piece == piece:lower() then
		promotion_error(piece)
		sb_promote(":board", x, y, "q")
	else
		sb_promote(":board", x, y, piece)
 	end
end

return interface

