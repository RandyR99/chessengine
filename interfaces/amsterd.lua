interface = {}

interface.level = "2"
interface.cur_level = nil
interface.score = "0.00"
interface.depth = "0"
interface.pv = ""
interface.info_state = 0   -- 0: IDLE, 1: PV, 2: SCORE, 3: DEPTH, 4: CLEANUP
interface.delay_counter = 0 -- Counts frames to slow down transitions


function interface.get_module()
	return "Mephisto Amsterdam"
end

function interface.get_author()
	return "Richard Lang"
end

function interface.setdigit(n)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if     (n == 0) then send_input(":KEY.1", 0x80, 0.5)
	elseif (n == 1) then send_input(":KEY.1", 0x01, 0.5)
	elseif (n == 2) then send_input(":KEY.1", 0x02, 0.5)
	elseif (n == 3) then send_input(":KEY.1", 0x04, 0.5)
	elseif (n == 4) then send_input(":KEY.1", 0x08, 0.5)
	elseif (n == 5) then send_input(":KEY.1", 0x10, 0.5)
	elseif (n == 6) then send_input(":KEY.1", 0x20, 0.5)
	elseif (n == 7) then send_input(":KEY.0", 0x40, 0.5)
	elseif (n == 8) then send_input(":KEY.0", 0x80, 0.5)
	elseif (n == 9) then send_input(":KEY.1", 0x40, 0.5)
	end
	machine.video.throttled = throttled_state
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.cur_level = interface.level
	local level = interface.level
	send_input(":KEY.0", 0x04, 0.5) -- LEV
	for i = 1, level:len() do
		local n = level:sub(i, i)
		if (n == " " or n == ":") then
			send_input(":KEY.0", 0x20, 0.5) -- ENT
		else
			interface.setdigit(tonumber(n))
		end
	end
	send_input(":KEY.0", 0x20, 0.5) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	emu.wait(1)
	interface.cur_level = "2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY.0", 0x02, 0.5) -- POS
		for i = 1, 14 do
			send_input(":KEY.0", 0x20, 0.5) -- ENT
		end
		machine.video.throttled = throttled_state
		return (":board:board")
	else
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x ,9 - y)
				if p ~= 0 then
					if p > 0 then
						interface.setdigit(0) -- White
					else
						interface.setdigit(9) -- Black
					end
					interface.setdigit(8 - math.abs(p))
					interface.setdigit(x)
					interface.setdigit(9 - y)
					send_input(":KEY.0", 0x20, 0.5) -- ENT
				end
			end
		end
		if mode == 1 then
			interface.setdigit(0) -- White
		else
			interface.setdigit(9) -- Black
		end
		send_input(":KEY.0", 0x20, 0.5) -- ENT
		send_input(":KEY.0", 0x10, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY.0", 0x08, 0.5) -- MEM
	else
		send_input(":KEY.0", 0x10, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":KEY.0", 0x20, 1) -- ENT
end

function interface.is_selected(x, y)
	local led_idx = (y - 1) * 8 + (x - 1)
	local led_name = "led" .. tostring(led_idx)
	local led_state = machine.devices[":"]:output(led_name)
	return led_state and led_state:get() ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board:board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "2" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+", " ") -- trim
		-- Updated pattern to support a single digit (0-9) followed by an optional space and a timestamp
		if (string.match(level, "^[0-9]$") or string.match(level, "^%d%s%d%d:[0-5]%d:[0-5]%d$") or string.match(level, "^%s%d%d:[0-5]%d:[0-5]%d$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY.0", 0x01, 0.5) -- INFO
	send_input(":KEY.1", 0x01, 0.5) -- 1
	local d3 = 0
	for i = 0, 5 do
		local digit3_state = machine.devices[":"]:output("digit3")
		local digit2_state = machine.devices[":"]:output("digit2")
		local d0 = (digit3_state and digit3_state:get() or 0) & 0x7f
		local d1 = (digit2_state and digit2_state:get() or 0) & 0x7f
		if (d0 == 0x73 and d1 == 0x50) then -- display shows 'Pr'
			local digit0_state = machine.devices[":"]:output("digit0")
			d3 = (digit0_state and digit0_state:get() or 0) & 0x7f
			break
		end
		send_input(":KEY.1", 0x80, 0.5) -- 0
	end
	send_input(":KEY.0", 0x10, 0.5) -- CLR
	machine.video.throttled = throttled_state
	if     (d3 == 0x5e) then return "q"
	elseif (d3 == 0x31) then return "r"
	elseif (d3 == 0x38) then return "b"
	elseif (d3 == 0x6d) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board:board", x, y, piece)
	if     (piece == "q") then send_input(":KEY.1", 0x20, 1)
	elseif (piece == "r") then send_input(":KEY.1", 0x10, 1)
	elseif (piece == "b") then send_input(":KEY.1", 0x08, 1)
	elseif (piece == "n") then send_input(":KEY.1", 0x04, 1)
	end
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		send_input(":KEY.0", 0x20, 1)
	end
end

function interface.show_info(on)
	if on then
		local digit3_state = machine.devices[":"]:output("digit3")
		local digit2_state = machine.devices[":"]:output("digit2")
		local digit1_state = machine.devices[":"]:output("digit1")
		local digit0_state = machine.devices[":"]:output("digit0")

		-- HELPER FUNCTION: Safely waits out the display's "off" blink phase
		local function get_lit_digits()
			local d1, d2, d3, d4
			for retry = 1, 60 do -- Safe timeout loop (approx 1 second max)
				d1 = (digit3_state and digit3_state:get() or 0) & 0x7f
				d2 = (digit2_state and digit2_state:get() or 0) & 0x7f
				d3 = (digit1_state and digit1_state:get() or 0) & 0x7f
				d4 = (digit0_state and digit0_state:get() or 0) & 0x7f
				
				-- If at least one segment is illuminated, the display is "on"
				if d1 ~= 0 or d2 ~= 0 or d3 ~= 0 or d4 ~= 0 then
					return d1, d2, d3, d4
				end
				emu.wait(0.016) -- Wait exactly 1 video frame (60Hz) before re-checking
			end
			return d1, d2, d3, d4
		end

		-- SAFE CONVERSION: Ensures digit_ascii never returns nil into a concatenation sequence
		local function safe_ascii(digit_val)
			local char = digit_ascii(digit_val)
			return char or " " -- Fallback to empty space if character is unmapped/nil
		end

		-- STEP 1: Enter the Info menu to get Principal Variation (PV)
		send_input(":KEY.0", 0x01, 0.15) -- Press INFO
		emu.wait(0.2) -- Wait for menu transition
		
		local d1, d2, d3, d4 = get_lit_digits()
		local current_pv = safe_ascii(d1) .. safe_ascii(d2) .. safe_ascii(d3) .. safe_ascii(d4)
		if string.match(current_pv, "^[a-h][1-8][a-h][1-8]$") then
			interface.pv = current_pv
		end
		
		-- STEP 2: Shift to Evaluation Score Screen
		send_input(":KEY.1", 0x01, 0.15) -- Press 1
		emu.wait(0.2) -- Wait for screen switch
		
		d1, d2, d3, d4 = get_lit_digits()
		local current_score = (safe_ascii(d1) .. safe_ascii(d2) .. safe_ascii(d3) .. safe_ascii(d4)):gsub(" ","")
		if string.match(current_score, "[0-9%-]+") and not string.match(current_score, "^[a-h][1-8]") then
			interface.score = current_score
		end
		
		-- STEP 3: Shift to Depth Screen
		send_input(":KEY.1", 0x04, 0.15) -- Press 3
		emu.wait(0.2) -- Wait for screen switch
		
		d1, d2, d3, d4 = get_lit_digits()
		local full_str = safe_ascii(d1) .. safe_ascii(d2) .. safe_ascii(d3) .. safe_ascii(d4)
		local clean_depth = full_str:gsub("n", ""):gsub("=", ""):gsub(" ", "")
		if clean_depth ~= "" and tonumber(clean_depth) then
			interface.depth = string.format("%02d", tonumber(clean_depth))
		end
		
		-- STEP 4: Exit backout
		send_input(":KEY.0", 0x10, 0.15) -- Press CL
		emu.wait(0.1) -- Wait for escape handling
		
		return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
	end
end

function digit_ascii(digit)
	if     digit == 0   then return " "
	elseif digit == 64  then return "-"
	elseif digit == 8   then return "_"
	elseif digit == 63  then return "0"
	elseif digit == 6   then return "1"
	elseif digit == 91  then return "2"
	elseif digit == 79  then return "3"
	elseif digit == 102 then return "4"
	elseif digit == 109 then return "5"
	elseif digit == 125 then return "6"
	elseif digit == 7   then return "7"
	elseif digit == 127 then return "8"
	elseif digit == 111 then return "9"
	elseif digit == 119 then return "a"
	elseif digit == 124 then return "b"
	elseif digit == 57  then return "c"
	elseif digit == 94  then return "d"
	elseif digit == 121 then return "e"
	elseif digit == 113 then return "f"
	elseif digit == 61  then return "g"
	elseif digit == 118 then return "h"
	end
end

return interface

