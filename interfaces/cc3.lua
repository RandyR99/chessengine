interface = {}

interface.turn = true
interface.invert = false
interface.last_get = nil
interface.level = 1
interface.cur_level = nil

function interface.get_module()
	return "Fidelity Chess Challenger 3"
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	-- Prevent redundant setup tramping if the level is already initialized
	if (interface.cur_level == interface.level) then
		return
	end
	
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	
	-- 1. HARD HARDWARE RESET: Trigger the absolute 8080 CPU reset line latch
	send_input(":RESET", 0x01, 0.4) -- RE (Reset Button)
	
	-- 2. BOOT SYNCHRONIZATION DELAY: Wait for the firmware's internal memory stacks to fully boot
	emu.wait(0.6)
	
	-- 3. LEVEL INCREMENT LOOP: Tap the 'CL' key sequentially to cycle up the level register
	-- Level 1 = 0 presses, Level 2 = 1 press, Level 3 = 2 presses
	if interface.level > 1 then
		for i = 1, interface.level - 1 do
			send_input(":IN.1", 0x04, 0.4) -- CL (Chess Level Key, input mask 0x04)
			emu.wait(0.4)
		end
	end
	
	-- Synchronize the level tracking flag safely
	interface.cur_level = interface.level
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	interface.turn = true
	interface.invert = false
	interface.last_get = nil
	
	-- Clean up the baseline state buffers prior to initializing the configuration loops
	interface.cur_level = nil
	interface.setlevel()
end

function interface.start_play(init)
	if (init) then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		interface.invert = true
		interface.turn = false
		send_input(":IN.1", 0x02, 0.5) -- DM
		emu.wait(0.5)
		send_input(":IN.1", 0x02, 0.5) -- DM
		emu.wait(0.5)
		send_input(":IN.1", 0x01, 0.5) -- EN
		emu.wait(0.5)
		machine.video.throttled = throttled_state
	end
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x6f, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	
	-- MODERNIZED: Switched inputs securely via the proxy device output containers
	local root = machine.devices[":"]
	local p0 = root:output("digit0")
	local p1 = root:output("digit1")
	local p2 = root:output("digit2")
	local p3 = root:output("digit3")
	
	local d0 = p0 and p0:get() or 0
	local d1 = p1 and p1:get() or 0
	local d2 = p2 and p2:get() or 0
	local d3 = p3 and p3:get() or 0
	
	if (d0 == 0x3f and d1 == 0x3f and d2 == 0x3f and d3 == 0x00) then -- "000 ", computer castles queenside
		return (interface.invert and y == 1 and (x == 5 or x == 7)) or (not interface.invert and y == 8 and (x == 5 or x == 3))
	end
	if (d0 == 0x3f and d1 == 0x3f and d2 == 0x00 and d3 == 0x00) then -- "00  ", computer castles kingside
		return (interface.invert and y == 1 and (x == 5 or x == 3)) or (not interface.invert and y == 8 and (x == 5 or x == 7))
	end
	if (interface.invert) then
		x = 9 - x
		y = 9 - y
	end
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if (interface.invert) then
		p = 9 - p
	end
	if     (p == 1)	then send_input(":IN.0", 0x80, 0.5)
	elseif (p == 2)	then send_input(":IN.0", 0x40, 0.5)
	elseif (p == 3)	then send_input(":IN.0", 0x20, 0.5)
	elseif (p == 4)	then send_input(":IN.0", 0x10, 0.5)
	elseif (p == 5)	then send_input(":IN.0", 0x08, 0.5)
	elseif (p == 6)	then send_input(":IN.0", 0x04, 0.5)
	elseif (p == 7)	then send_input(":IN.0", 0x02, 0.5)
	elseif (p == 8)	then send_input(":IN.0", 0x01, 0.5)
	end
end

function interface.send_pos_full(x, y)
	interface.send_pos(x)
	interface.send_pos(y)
end

function interface.select_piece(x, y, event)
	if (event == "get" and interface.turn) then
		interface.last_get = {x=x, y=y}
	elseif (event == "put" and interface.turn) then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local move_type = get_move_type(interface.last_get.x, interface.last_get.y, x, y)
		local dy
		if (move_type == "castling") then
			send_input(":IN.1", 0x02, 0.5) -- DM
		elseif (move_type == "en_passant") then
			dy = y
			y = interface.last_get.y
			send_input(":IN.1", 0x02, 0.5) -- DM
		end
		interface.send_pos_full(interface.last_get.x, interface.last_get.y)
		interface.send_pos_full(x, y)
		send_input(":IN.1", 0x01, 0.5) -- EN

		-- special moves require extra steps
		if (move_type == "castling" and x == 7) then
			interface.send_pos_full(8, y)
			interface.send_pos_full(6, y)
			send_input(":IN.1", 0x01, 0.5) -- EN
		elseif (move_type == "castling" and x == 3) then
			interface.send_pos_full(1, y)
			interface.send_pos_full(4, y)
			send_input(":IN.1", 0x01, 0.5) -- EN
		elseif (move_type == "en_passant") then
			interface.send_pos_full(x, y)
			interface.send_pos_full(x, dy)
			send_input(":IN.1", 0x01, 0.5) -- EN
		end
		interface.last_get = nil
		machine.video.throttled = throttled_state
	end
	if (event == "put") then
		interface.turn = not interface.turn
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "3" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 3) then
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

