interface = {}

interface.turn = true
interface.invert = false
interface.level = 1
interface.cur_level = nil

function interface.get_module()
	if machine.system.name == "cc7" then
		return "Fidelity Chess Challenger 7"
	elseif machine.system.name == "cc7a" then
		return "Fidelity Chess Challenger 7 v2"
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
	
	local lcd_num = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local root = machine.devices[":"]
	local safety_counter = 0
	
	-- Level selector clicks LV loop to increment until the digit mask matches
	repeat
		send_input(":IN.3", 0x02, 0.5) -- LV (Chess Level, input mask 0x02 on IN.3)
		emu.wait(0.2)
		
		-- MODERNIZED: Sniffs the output safely from the container device proxy
		local p3 = root:output("digit3")
		local d3_val = p3 and p3:get() or 0
		
		if d3_val == lcd_num[interface.level] then
			break
		end
		
		-- Watchdog protection to prevent infinite loops on high-speed dropped frames
		safety_counter = safety_counter + 1
		if safety_counter > 20 then
			break
		end
	until false
	
	send_input(":IN.1", 0x01, 0.5) -- CL (Confirm Level / Clear)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.invert = false
	send_input(":IN.3", 0x01, 1) -- RE (Reset Button, input mask 0x01 on IN.3)
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.start_play(init)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	
	local root = machine.devices[":"]
	local p0 = root:output("digit0")
	
	if (init) then
		interface.turn = false
		interface.invert = true
		send_input(":IN.2", 0x01, 0.5) -- CB
	elseif (interface.invert) then
		local col
		local d0_val = p0 and p0:get() or 0
		if (d0_val == 0x5e) then
			col = 4 -- d2d4
		else
			col = 5 -- e2e4
		end
		interface.setup_machine()
		interface.turn = false
		interface.send_pos(col)
		interface.send_pos(2)
		interface.send_pos(col)
		interface.send_pos(4)
		send_input(":IN.0", 0x01, 1) -- EN
	else
		interface.turn = false
		send_input(":IN.2", 0x02, 0.5) -- DM
		send_input(":IN.1", 0x02, 0.5) -- PB
	end
	machine.video.throttled = throttled_state
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x6f, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	
	-- MODERNIZED: Updated raw digit queries safely using modern proxy handles
	local root = machine.devices[":"]
	local p0 = root:output("digit0")
	local p1 = root:output("digit1")
	local p2 = root:output("digit2")
	local p3 = root:output("digit3")
	
	local d0 = p0 and p0:get() or 0
	local d1 = p1 and p1:get() or 0
	local d2 = p2 and p2:get() or 0
	local d3 = p3 and p3:get() or 0
	
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then send_input(":IN.3", 0x04, 0.5)
	elseif (p == 2)	then send_input(":IN.2", 0x04, 0.5)
	elseif (p == 3)	then send_input(":IN.1", 0x04, 0.5)
	elseif (p == 4)	then send_input(":IN.0", 0x04, 0.5)
	elseif (p == 5)	then send_input(":IN.3", 0x08, 0.5)
	elseif (p == 6)	then send_input(":IN.2", 0x08, 0.5)
	elseif (p == 7)	then send_input(":IN.1", 0x08, 0.5)
	elseif (p == 8)	then send_input(":IN.0", 0x08, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn) then
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "put") then
			if (interface.turn) then
				interface.invert = false
				send_input(":IN.0", 0x01, 1) -- EN
			end
			interface.turn = not interface.turn
		end
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "7" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 7) then
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
	promotion_error(piece)
end

return interface

