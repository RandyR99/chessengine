interface = {}

interface.level = "bl 2"
interface.cur_level = nil

function interface.get_module()
	if machine.system.name == "bup" then
		return "Mephisto Blitz & Problem"
	elseif machine.system.name == "bupa" then
		return "Mephisto Blitz & Problem v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ulf Rathsman"
end

function interface.setdigit(n)
	if     (n == 1) then  send_input(":KEY.0", 0x01, 0.5)
	elseif (n == 2) then  send_input(":KEY.0", 0x02, 0.5)
	elseif (n == 3) then  send_input(":KEY.0", 0x04, 0.5)
	elseif (n == 4) then  send_input(":KEY.0", 0x08, 0.5)
	elseif (n == 5) then  send_input(":KEY.0", 0x10, 0.5)
	elseif (n == 6) then  send_input(":KEY.0", 0x20, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local l0 = 0x7c -- 'b'
	local l1 = 0x38 -- 'l'
	if (interface.level:sub(1, 2) == "pl") then
		l0 = 0x73 -- 'p'
	end
	
	repeat
		send_input(":KEY.1", 0x40, 1) -- LEV
		local d3_state = machine.devices[":"]:output("digit3")
		local d2_state = machine.devices[":"]:output("digit2")
		local d0 = d3_state and (d3_state:get() & 0x7f) or 0
		local d1 = d2_state and (d2_state:get() & 0x7f) or 0
	until (d0 == l0 and d1 == l1)
	
	local n = tonumber(interface.level:sub(4))
	if (n == 1) then
		send_input(":KEY.0", 0x01, 1)
	elseif (n == 2) then
		send_input(":KEY.0", 0x02, 1)
	elseif (n == 3) then
		send_input(":KEY.0", 0x04, 1)
	elseif (n == 4) then
		send_input(":KEY.0", 0x08, 1)
	elseif (n == 5) then
		send_input(":KEY.0", 0x10, 1)
	elseif (n == 6) then
		send_input(":KEY.0", 0x20, 1)
	end
	send_input(":KEY.1", 0x02, 1) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board:board")
	emu.wait(1)
	
	local led_101 = machine.devices[":"]:output("led101")
	while (not led_101 or led_101:get() == 0) do
		machine:soft_reset()
		emu.wait(1)
		led_101 = machine.devices[":"]:output("led101")
	end
	
	send_input(":KEY.1", 0x01, 1) -- CL
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "bl 2"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":KEY.1", 0x20, 0.5) -- POS
		send_input(":KEY.1", 0x01, 0.5) -- CL
		return (":board:board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					interface.setdigit(7 - math.abs(p))
					if p < 0 then
						interface.setdigit(7 - math.abs(p))
					end
					sb_press_square(":board:board", 0.5, x, 9 - y)
				end
			end
		end
		send_input(":KEY.1", 0x01, 0.5) -- CL
		if mode == 1 then
			send_input(":KEY.0", 0x40, 0.5) -- White
		else
			send_input(":KEY.0", 0x80, 0.5) -- Black
		end
		send_input(":KEY.1", 0x02, 0.5) -- ENT
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game(on)
	if on then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":KEY.1", 0x01, 0.5) -- CL
		send_input(":KEY.1", 0x40, 0.5) -- LEV
		send_input(":KEY.1", 0x10, 0.5) ---MON
		send_input(":KEY.1", 0x02, 0.5) -- ENT
		machine.video.throttled = throttled_state
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	local led_100 = machine.devices[":"]:output("led100")
	local led_101 = machine.devices[":"]:output("led101")
	
	if (led_100 and led_100:get() ~= 0) then
		send_input(":KEY.0", 0x80, 1) -- BLACK
	elseif (led_101 and led_101:get() ~= 0) then
		send_input(":KEY.0", 0x40, 1) -- WHITE
	end
	send_input(":KEY.1", 0x02, 1) -- ENT
end

function interface.is_selected(x, y)
	local xval = {0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76}
	local yval = {0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f}
	
	local d0_state = machine.devices[":"]:output("digit0")
	local d1_state = machine.devices[":"]:output("digit1")
	local d2_state = machine.devices[":"]:output("digit2")
	local d3_state = machine.devices[":"]:output("digit3")
	local led_state = machine.devices[":"]:output("led" .. tostring(8 * (y - 1) + (x - 1)))
	
	local d0 = d0_state and (d0_state:get() & 0x7f) or 0
	local d1 = d1_state and (d1_state:get() & 0x7f) or 0
	local d2 = d2_state and (d2_state:get() & 0x7f) or 0
	local d3 = d3_state and (d3_state:get() & 0x7f) or 0
	local led_val = led_state and led_state:get() or 0
	
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3) or led_val ~= 0
end

function interface.select_piece(x, y, event)
	local d0_state = machine.devices[":"]:output("digit0")
	local d1_state = machine.devices[":"]:output("digit1")
	local d2_state = machine.devices[":"]:output("digit2")
	local d3_state = machine.devices[":"]:output("digit3")
	
	local d0 = d0_state and (d0_state:get() & 0x7f) or 0
	local d1 = d1_state and (d1_state:get() & 0x7f) or 0
	local d2 = d2_state and (d2_state:get() & 0x7f) or 0
	local d3 = d3_state and (d3_state:get() & 0x7f) or 0
	
	if ((d0 == 0x31 and d1 == 0x30 and d2 == 0x37 and d3 == 0x79) or (d0 == 0x77 and d1 == 0x06 and d2 == 0x77 and d3 == 0x06)) then -- 'TIME' or 'A1A1'
		send_input(":KEY.1", 0x01, 0.3) -- CL
	end
	sb_select_piece(":board:board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "bl 2" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		value = value:gsub("_", " ")
		local level = string.lower(value:match("^%s*(.-)%s*$"):gsub("%s%s+", " ")) -- trim
		if (string.match(level, "^[1-6]$")) then
			level = "bl " .. level
		end
		if (string.match(level, "^[bp]l [1-6]$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	local d0_state = machine.devices[":"]:output("digit0")
	local d1_state = machine.devices[":"]:output("digit1")
	local d3_state = machine.devices[":"]:output("digit3")
	
	local d0 = d0_state and (d0_state:get() & 0x7f) or 0
	local d1 = d1_state and (d1_state:get() & 0x7f) or 0
	local d3 = d3_state and (d3_state:get() & 0x7f) or 0
	
	if (d0 == 0x73 and d1 == 0x50) then -- display shows 'Pr'
		if     (d3 == 0x5e) then return "q"
		elseif (d3 == 0x31) then return "r"
		elseif (d3 == 0x38) then return "b"
		elseif (d3 == 0x6d) then return "n"
		end
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board:board", x, y, piece)
	if     (piece == "q" or piece == "Q") then send_input(":KEY.0", 0x10, 1)
	elseif (piece == "r" or piece == "R") then send_input(":KEY.0", 0x08, 1)
	elseif (piece == "b" or piece == "B") then send_input(":KEY.0", 0x04, 1)
	elseif (piece == "n" or piece == "N") then send_input(":KEY.0", 0x02, 1)
	end
end

return interface

