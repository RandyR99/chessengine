local interface = {}

interface.opt_clear_announcements = true
interface.level = "a1"
interface.cur_level = nil
interface.score = "0.00"
interface.depth = "0"
interface.pv = ""

function interface.get_module()
	if machine.system.name == "fdes2265" then
		return "Fidelity Designer Mach III"
	elseif machine.system.name == "fdes2265a" then
		return "Fidelity Designer Mach III v2"
	elseif machine.system.name == "fdes2325" then
		return "Fidelity Designer Mach IV"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setdigit(d)
	d = tonumber(d)
	if (d == 0) then
		sb_press_square(":board", 1, 2, 1)
	elseif (d == 9) then
		sb_press_square(":board", 1, 2, 8)
	else
		sb_press_square(":board", 1, 1, d)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = interface.level:sub(2, 2)
	send_input(":IN.0", 0x10, 0.5)	-- LEVEL
	if (level:len() == 2) then
		sb_press_square(":board", 1, x, y)
	else
		level = level:sub(3)
		y = 1
		while (level ~= "") do
			sb_press_square(":board", 1, x, y)
			interface.setdigit(level:sub(1,1))
			interface.setdigit(level:sub(3,3))
			interface.setdigit(level:sub(4,4))
			sb_press_square(":board", 1, x, y+1)
			interface.setdigit(level:sub(6,6))
			interface.setdigit(level:sub(7,7))
			level = level:sub(9)
			y = y + 2
		end
	end
	send_input(":IN.0", 0x01, 0.5) -- CLEAR
	machine.video.throttled = throttled_state
end

function rotatingDisplay()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	
	local root = machine.devices[":"]
	if not root then return end
	
	send_input(":IN.0", 0x20, 1) -- option
	send_input(":IN.0", 0x20, 1) -- option
	
	local b2_node = root:output("1.1")
	local b2_val = b2_node and b2_node:get() or 0
	if b2_val == 0 then
		sb_press_square(":board", 1, 2, 2)  -- b2
		emu.wait(0.5)
	end
	
	local c2_node = root:output("1.2")
	local c2_val = c2_node and c2_node:get() or 0
	if c2_val == 0 then
		sb_press_square(":board", 1, 3, 2)  -- c2
		emu.wait(0.5)
	end
	
	local e2_node = root:output("1.4")
	local e2_val = e2_node and e2_node:get() or 0
	if e2_val == 0 then
		sb_press_square(":board", 1, 5, 2)  -- e2
		emu.wait(0.5)
	end
	
	local a2_node = root:output("1.0")
	local a2_val = a2_node and a2_node:get() or 0
	if a2_val ~= 0 then
		sb_press_square(":board", 1, 1, 2)  -- a2
		emu.wait(0.5)
	end
	
	send_input(":IN.0", 0x20, 1) -- option
	send_input(":IN.0", 0x01, 1) -- clear
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(2)
	machine.video.throttled = throttled_state
	interface.cur_level = "a1"
	interface.setlevel()
	rotatingDisplay()
	
	local root = machine.devices[":"]
	if not root then return end
	
	-- Ton ausschalten
	local throttled_state_sound = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x20, 1) -- OPTION
	
	local b1_node = root:output("1.1")
	local b1_val = b1_node and b1_node:get() or 0
	if b1_val == 0 then
		sb_press_square(":board", 1, 2, 1)  -- b1
		emu.wait(0.5)
	end
	
	send_input(":IN.0", 0x01, 1) -- CLEAR
	send_input(":IN.0", 0x01, 1) -- CLEAR
	machine.video.throttled = throttled_state_sound
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x20, 1) -- OPTION
		sb_press_square(":board", 1, 7, 1) -- Clear board
		send_input(":IN.0", 0x01, 1) -- CLEAR
		send_input(":IN.0", 0x01, 1) -- CLEAR
		emu.wait(0.5)
		send_input(":IN.0", 0x80, 1) -- SHIFT
		send_input(":IN.0", 0x40, 1) -- PROBLEM
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x80 >> (math.abs(p)), 1)
					end
					sb_press_square(":board", 1, x, 9 - y)
					if p < 0 then
						sb_press_square(":board", 1, x, 9 - y)
					end
					piece = p
				end
			end
		end
		send_input(":IN.0", 0x01, 1) -- CLEAR
		if mode == -1 then
			send_input(":IN.0", 0x20, 1) -- OPTION
			sb_press_square(":board", 1, 5, 1) -- Change color
			send_input(":IN.0", 0x01, 1) -- CLEAR
		end
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x20, 1) -- OPTION
	sb_press_square(":board", 1, 3, 1)
	send_input(":IN.0", 0x01, 1) -- CLEAR
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x02, 1) -- MOVE
end

function interface.clear_announcements()
	local root = machine.devices[":"]
	if not root then return end

	local d2_node = root:output("digit2")
	local d3_node = root:output("digit3")
	local d4_node = root:output("digit4")
	local d5_node = root:output("digit5")

	local d2 = d2_node and d2_node:get() or 0
	local d3 = d3_node and d3_node:get() or 0
	local d4 = d4_node and d4_node:get() or 0
	local d5 = d5_node and d5_node:get() or 0
	
	if ((d3 == 0x54 or d3 == 0x37) or											
	   (d2 == 0x5e and d3 == 0x50 and d5 == 0x4f) or					
	   (d2 == 0x5e and d3 == 0x50 and d4 == 0x6d and d5 == 0x3f)) then	
		send_input(":IN.0", 0x01, 1)
	end
end

interface.debounce_latch = {}
interface.was_machine_turn = false
interface.settle_frames = 0

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end
	
	local root = machine.devices[":"]
	if not root then return false end

	local d_node = root:output("1.3")
	local e_node = root:output("1.4")
	local d_val = d_node and d_node:get() or 0
	local e_val = e_node and e_node:get() or 0
	
	local current_machine_turn = (d_val ~= 0 or e_val ~= 0)

	if interface.was_machine_turn and not current_machine_turn then
		interface.settle_frames = 20
	end
	interface.was_machine_turn = current_machine_turn

	if interface.settle_frames > 0 then
		interface.settle_frames = interface.settle_frames - 1
		return false
	end

	local r_node = root:output("0." .. tostring(y - 1))
	local c_node = root:output("1." .. tostring(x - 1))
	local r_val = r_node and r_node:get() or 0
	local c_val = c_node and c_node:get() or 0
	
	local square_key = x .. "_" .. y
	local is_intersecting = (r_val ~= 0 and c_val ~= 0)
	
	if is_intersecting then
		local active_count = (interface.debounce_latch[square_key] or 0) + 1
		interface.debounce_latch[square_key] = active_count
		
		if active_count >= 3 then
			return true
		end
	else
		interface.debounce_latch[square_key] = 0
	end
	
	return false
end

function interface.select_piece(x, y, event)
	if (interface.opt_clear_announcements) then
		interface.clear_announcements()
	end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "a1" },
		{ "check", "Clear announcements", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^[ab][1-8]$") or level:match("^[d-h][1-8]$") or level:match("^c%s%d:[0-5]%d/%d%d$") or level:match("^c%s%d:[0-5]%d/%d%d%s%d:[0-5]%d/%d%d$") or level:match("^c%s%d:[0-5]%d/%d%d%s%d:[0-5]%d/%d%d%s%d:[0-5]%d/%d%d$")) then
			interface.level = level
			interface.setlevel()
		end
	elseif (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function interface.test_promotion(x, y)
	local function piece_led(port, code, x, y)
		local root = machine.devices[":"]
		if not root then return false end
		
		for n=1,8 do
			send_input(port, code, 0.5)
			for i=1,4 do
				-- FIXED: Modern non-deprecated node object API mapping format
				local r_node = root:output("0." .. tostring(y - 1))
				local c_node = root:output("1." .. tostring(x - 1))
				local r_val = r_node and r_node:get() or 0
				local c_val = c_node and c_node:get() or 0
				
				if r_val ~= 0 and c_val ~= 0 then
					return true
				end
				emu.wait(0.15)
			end
		end
		return false
	end

	if (interface.opt_clear_announcements) then
		interface.clear_announcements()
	end

	local p
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(1)
	send_input(":IN.0", 0x40, 1) -- VERIFY

	if     piece_led(":IN.0", 0x20, x, y) then p = "Q"
	elseif piece_led(":IN.0", 0x04, x, y) then p = "N"
	elseif piece_led(":IN.0", 0x08, x, y) then p = "B"
	elseif piece_led(":IN.0", 0x10, x, y) then p = "R"
	else p = "Q"
	end

	emu.wait(1)
	send_input(":IN.0", 0x01, 1) -- CLEAR
	machine.video.throttled = throttled_state
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	emu.wait(1)
	if	   (piece == "q") then send_input(":IN.0", 0x20, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x08, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x04, 1)
	end
end

interface.last_thinking_state = false

function interface.show_info(on)
	if on and not interface.last_thinking_state then
		interface.score = "0.00"
		interface.depth = "0"
		interface.pv = ""
	end
	interface.last_thinking_state = on

 	if on then
		local root = machine.devices[":"]
		if not root then return "" end

		local dot_node = root:output("3.7")
		local d1_node  = root:output("digit2")
		local d2_node  = root:output("digit3")
		local d3_node  = root:output("digit4")
		local d4_node  = root:output("digit5")

		local dot = dot_node and dot_node:get() or 0
		local d1  = d1_node and d1_node:get() or 0
		local d2  = d2_node and d2_node:get() or 0
		local d3  = d3_node and d3_node:get() or 0
		local d4  = d4_node and d4_node:get() or 0

		local raw_d1 = digit_ascii(d1)
		local raw_d2 = digit_ascii(d2)
		local raw_d3 = digit_ascii(d3)
		local raw_d4 = digit_ascii(d4)

		if dot == 0 then
			if raw_d1 == "a" or raw_d1 == "b" or raw_d1 == "c" or raw_d1 == "d" or raw_d1 == "e" or raw_d1 == "f" or raw_d1 == "g" or raw_d1 == "h" then
				interface.pv = raw_d1 .. raw_d2 .. raw_d3 .. raw_d4
			else
				local clean_depth = (raw_d3 .. raw_d4):gsub(" ","")
				if clean_depth:match("^%d+$") then
					interface.depth = clean_depth
				end
			end
		else
			local clean_score = (raw_d1 .. raw_d2 .. raw_d3 .. raw_d4):gsub(" ","")
			if clean_score:match("^%-?%d+$") and clean_score:len() <= 4 then
				interface.score = clean_score
			end
		end
		
		return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " ..  interface.pv
	else
		return ""
	end
end

function digit_ascii(digit)
	if     digit == nil then return " "
	elseif digit == 63  then return "0"
	elseif digit == 6   then return "1"
	elseif digit == 91  then return "2"
	elseif digit == 79  then return "3"
	elseif digit == 102 then return "4"
	elseif digit == 109 then return "5"
	elseif digit == 111 then return "5"
	elseif digit == 125 then return "6"
	elseif digit == 7   then return "7"
	elseif digit == 127 then return "8"
	elseif digit == 103 then return "9"
	elseif digit == 119 then return "a"
	elseif digit == 124 then return "b"
	elseif digit == 57  then return "c"
	elseif digit == 94  then return "d"
	elseif digit == 121 then return "e"
	elseif digit == 113 then return "f"
	elseif digit == 61  then return "g"
	elseif digit == 118 then return "h"
	elseif digit == 0   then return " "
	elseif digit == 28  then return "Nr."
	elseif digit == 64  then return "-"
	elseif digit == 115 then return "P"
	elseif digit == 55  then return "N"
	end
end

return interface

