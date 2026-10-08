interface = {}

interface.level = 3
interface.cur_level = nil
interface.score = "0"
interface.depth = "0"
interface.pv = ""

function interface.get_module()
	if machine.system.name == "mm1" then
		return "Mephisto MM I"
	elseif machine.system.name == "mm1b" then
		return "Mephisto MM I v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Thomas Nitsche & Elmar Henne"
end

function interface.setdigit(n)
	if     (n == 0) then send_input(":IN.0", 0x04, 1)
	elseif (n == 1) then send_input(":IN.1", 0x20, 1)
	elseif (n == 2) then send_input(":IN.1", 0x80, 1)
	elseif (n == 3) then send_input(":IN.1", 0x04, 1)
	elseif (n == 1) then send_input(":IN.1", 0x10, 1)
	elseif (n == 5) then send_input(":IN.0", 0x01, 1)
	elseif (n == 6) then send_input(":IN.1", 0x40, 1)
	elseif (n == 7) then send_input(":IN.0", 0x40, 1)
	elseif (n == 8) then send_input(":IN.0", 0x10, 1)
	elseif (n == 9) then send_input(":IN.1", 0x01, 1)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x20, 1) -- LEV
	local n = tonumber(interface.level)
	interface.setdigit(n)
	send_input(":IN.1", 0x08, 1) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	emu.wait(1)
	interface.cur_level = 3
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x08, 0.5) -- POS
		for i = 1, 14 do
			send_input(":IN.1", 0x08, 0.5) -- ENT
		end
		machine.video.throttled = throttled_state
		return (":board:board")
	else
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p > 0 then
						interface.setdigit(0) -- White
					else
						interface.setdigit(9) -- Black
					end
					interface.setdigit(8 - math.abs(p))
					interface.setdigit(x)
					interface.setdigit(9 - y)
					send_input(":IN.1", 0x08, 0.5) -- ENT
				end
			end
		end
		if mode == 1 then
			interface.setdigit(0) -- White
		else
			interface.setdigit(9) -- Black
		end
		send_input(":IN.1", 0x08, 0.5) -- ENT
		send_input(":IN.1", 0x02, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":IN.0", 0x80, 0.5) -- MEM
	else
		send_input(":IN.1", 0x02, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.1", 0x08, 1) -- ENT
end

function interface.is_selected(x, y)
	if x == 6 and (y == 8 or y == 1) then
		local led_7 = machine.devices[":"]:output("led" .. tostring((y - 1) * 8 + (7 - 1)))
		local led_8 = machine.devices[":"]:output("led" .. tostring((y - 1) * 8 + (8 - 1)))
		if led_7 and led_7:get() ~= 0 and led_8 and led_8:get() ~= 0 then
			return 0
		end
	end
	if x == 1 and (y == 8 or y == 1) then
		local led_3 = machine.devices[":"]:output("led" .. tostring((y - 1) * 8 + (3 - 1)))
		local led_5 = machine.devices[":"]:output("led" .. tostring((y - 1) * 8 + (5 - 1)))
		if led_3 and led_3:get() ~= 0 and led_5 and led_5:get() ~= 0 then
			return 0
		end
	end
	
	local target_led = machine.devices[":"]:output("led" .. tostring((y - 1) * 8 + (x - 1)))
	return target_led and target_led:get() ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board:board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "3", "0", "9" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		value = value:gsub("_", " ")
		local level = tonumber(value)
		if (level < 0 or level > 9) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.start_play(init)
	send_input(":KEY.0", 0x20, 1) -- ENT
end

function interface.stop_play()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	
	-- Sending ENT tells the Mephisto MM IV to stop thinking and play immediately
	send_input(":KEY.0", 0x20, 1) -- ENT
	
	machine.video.throttled = throttled_state
end

-- Unified helper to harvest and merge segment fragments over several frames
local function gather_display_segments(cycles)
	local r3, r2, r1, r0 = 0, 0, 0, 0
	for i = 1, cycles do
		local p3 = machine.devices[":"]:output("digit3")
		local p2 = machine.devices[":"]:output("digit2")
		local p1 = machine.devices[":"]:output("digit1")
		local p0 = machine.devices[":"]:output("digit0")
		
		r3 = r3 | (p3 and p3:get() or 0)
		r2 = r2 | (p2 and p2:get() or 0)
		r1 = r1 | (p1 and p1:get() or 0)
		r0 = r0 | (p0 and p0:get() or 0)
		
		emu.wait(0.01)
	end
	return r3 & 0x7f, r2 & 0x7f, r1 & 0x7f, r0 & 0x7f
end

function interface.get_promotion(x, y)
	local throttled_state = machine.video.throttled
	machine.video.throttled = true -- Enforce stable timing context
	
	send_input(":IN.0", 0x02, 0.5) -- INFO
	send_input(":IN.1", 0x20, 0.5) -- 1
	emu.wait(0.2)
	
	local previous_d3 = nil
	local verified_d3 = 0
	local match_found = false
	
	for sample = 1, 10 do
		local d0, d1, _, d3 = gather_display_segments(15)
		emu.wait(0.05)
		
		-- Look for the 'Pr' confirmation layout status flags
		if (d0 == 0x73 and d1 == 0x50) then
			if previous_d3 == d3 then
				verified_d3 = d3
				match_found = true
				break
			end
			previous_d3 = d3
		end
		send_input(":IN.0", 0x04, 0.5) -- Loop through 0 key toggles
	end
	
	send_input(":IN.0", 0x02, 0.5) -- INFO
	emu.wait(0.1)
	machine.video.throttled = throttled_state
	
	if match_found then
		if     (verified_d3 == 0x5e) then return "q"
		elseif (verified_d3 == 0x31) then return "r"
		elseif (verified_d3 == 0x38) then return "b"
		elseif (verified_d3 == 0x6d) then return "n"
		end
	end
	return "q"
end

function interface.promote(x, y, piece)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_promote(":board:board", x, y, piece)
	if     (piece == "q") then send_input(":IN.1", 0x40, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x01, 1)
	elseif (piece == "b") then send_input(":IN.1", 0x10, 1)
	elseif (piece == "n") then send_input(":IN.1", 0x04, 1)
	end
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		send_input(":IN.1", 0x08, 1) -- ENT
	end
	machine.video.throttled = throttled_state
end

-- Reads the display strings repeatedly over 2 seconds, requiring 2 identical consecutive reads
local function read_validated_display(full_four_digits)
	local previous_read = nil
	local fallback_empty = full_four_digits and "    " or "  "
	
	for sample = 1, 10 do
		local d1, d2, d3, d4 = gather_display_segments(15)
		emu.wait(0.05)
		
		local visual_string
		if full_four_digits then
			visual_string = digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4)
		else
			visual_string = digit_ascii(d3) .. digit_ascii(d4)
		end
		
		if visual_string:gsub(" ", "") ~= "" then
			if previous_read == visual_string then
				return visual_string
			end
			previous_read = visual_string
		end
	end
	
	if previous_read then
		return previous_read
	else
		return fallback_empty
	end
end

function interface.show_info(on)
	if on then
		local throttled_state = machine.video.throttled
		machine.video.throttled = true
		
		-- Initialize safe, clean defaults so concatenation can NEVER fail
		local raw_pv = "    "
		local raw_score = "    "
		local raw_depth = "  "
		
		-- =================================================================
		-- STEP 1: COLLECT THE PRINCIPAL VARIATION (PV)
		-- =================================================================
		send_input(":IN.0", 0x02, 0.2) -- INFO
		emu.wait(0.2)
		raw_pv = read_validated_display(true)
		interface.pv = raw_pv
		
		-- =================================================================
		-- STEP 2: COLLECT THE CENTIPAWN SCORE (CP)
		-- =================================================================
		send_input(":IN.1", 0x20, 0.2) -- 1
		emu.wait(0.2)
		raw_score = read_validated_display(true)
		local cleaned_score = raw_score:gsub(" ", "")
		
		-- Filter out move coordinates leaking into score string (e.g., matching letter + number)
		if cleaned_score:match("[a-h]%d") then
			cleaned_score = ""
		end
		
		interface.score = cleaned_score
		if interface.score == "" then interface.score = "0" end
		
		-- =================================================================
		-- STEP 3: COLLECT THE CURRENT DEPTH
		-- =================================================================
		send_input(":IN.1", 0x04, 0.2) -- 3
		emu.wait(0.2)
		raw_depth = read_validated_display(false)
		interface.depth = raw_depth:gsub(" ", "")
		if interface.depth == "" then interface.depth = "0" end
		
		-- Reset layout screen state to default game board view
		send_input(":IN.1", 0x02, 0.2) -- CL
		emu.wait(0.1)
		
		machine.video.throttled = throttled_state
		
		local final_score = interface.score or "0"
		local final_depth = interface.depth or "0"
		local final_pv = interface.pv or ""
		
		return "info score cp " .. final_score .. " depth " .. final_depth .. " pv " .. final_pv
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
