interface = {}

interface.level = "le 1"
interface.cur_level = nil

interface.score = "0"
interface.depth = "0"
interface.pv = ""

interface.lock_print = false  -- Prevents repeated trailing calculations on move found

function interface.get_module()
	if machine.system.name == "mm4" then
		return "Mephisto MM IV"
	elseif machine.system.name == "mm4a" then
		return "Mephisto MM IV v2"
	elseif machine.system.name == "mm4b" then
		return "Mephisto MM IV v3"
	elseif machine.system.name == "mm4tk" then
		return "Mephisto MM IV Turbokit"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ed Schröder"
end

function interface.setdigit(n)
	if     (n == 0) then  send_input(":KEY.0", 0x40, 0.5)
	elseif (n == 1) then  send_input(":KEY.1", 0x08, 0.5)
	elseif (n == 2) then  send_input(":KEY.1", 0x20, 0.5)
	elseif (n == 3) then  send_input(":KEY.1", 0x40, 0.5)
	elseif (n == 4) then  send_input(":KEY.1", 0x80, 0.5)
	elseif (n == 5) then  send_input(":KEY.1", 0x01, 0.5)
	elseif (n == 6) then  send_input(":KEY.1", 0x02, 0.5)
	elseif (n == 7) then  send_input(":KEY.1", 0x04, 0.5)
	elseif (n == 8) then  send_input(":KEY.1", 0x10, 0.5)
	elseif (n == 9) then  send_input(":KEY.0", 0x80, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY.0", 0x10, 1) -- LEV
	if (interface.level:sub(1,2) == "bl") then
		send_input(":KEY.0", 0x10, 1) -- LEV
	end
	local n = tonumber(interface.level:sub(4))
	interface.setdigit(n)
	send_input(":KEY.0", 0x20, 1) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	ioport.ports[":RESET"]:field(0x01):set_value(1) -- Res 1
	ioport.ports[":RESET"]:field(0x02):set_value(1) -- Res 2
	emu.wait(0.3)
	ioport.ports[":RESET"]:field(0x01):set_value(0) -- RES 1
	ioport.ports[":RESET"]:field(0x02):set_value(0) -- RES 2
	emu.wait(0.5)
	sb_reset_board(":board:board")
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "le 1"
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
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p > 0 then
						interface.setdigit(0) -- White
					else
						interface.setdigit(9) -- Black
					end
					interface.setdigit(7 - math.abs(p))
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
		send_input(":KEY.0", 0x01, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY.0", 0x04, 0.5) -- MEM
	else
		send_input(":KEY.0", 0x01, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":KEY.0", 0x20, 1) -- ENT
end

function interface.stop_play()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
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
		{ "string", "Level", "le 1" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = string.lower(value:match("^%s*(.-)%s*$"):gsub("%s%s+", " ")) -- trim
		if (string.match(level, "^[0-9]$")) then
			level = "le " .. level
		end
		if (string.match(level, "^le [0-9]$") or string.match(level, "^bl [1-8]$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY.0", 0x08, 0.5) -- INFO
	send_input(":KEY.1", 0x08, 0.5) -- 1
	local target_piece_segments = 0
	
	for i = 0, 5 do
		local d1, d2, d3, d4 = gather_display_segments(3)
		
		-- 'Pr' appears on segments d1 and d2
		if (d1 == 0x73 and d2 == 0x50) then 
			target_piece_segments = d4
			break
		end
		send_input(":KEY.0", 0x40, 0.5) -- 0
	end
	send_input(":KEY.0", 0x08, 0.5) -- INFO
	machine.video.throttled = throttled_state
	
	if     (target_piece_segments == 0x5e) then return "q"
	elseif (target_piece_segments == 0x31) then return "r"
	elseif (target_piece_segments == 0x38) then return "b"
	elseif (target_piece_segments == 0x6d) then return "n"
	end
	
	return "q" -- Safe immediate fallback so it never hangs up piece-movement execution
end

function interface.promote(x, y, piece)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_promote(":board:board", x, y, piece)
	if     (piece == "q") then send_input(":KEY.1", 0x01, 1)
	elseif (piece == "r") then send_input(":KEY.1", 0x80, 1)
	elseif (piece == "b") then send_input(":KEY.1", 0x40, 1)
	elseif (piece == "n") then send_input(":KEY.1", 0x20, 1)
	end
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		send_input(":KEY.0", 0x20, 1)
	end
	machine.video.throttled = throttled_state
end

-- Reads the display strings repeatedly over 2 seconds, requiring 2 identical consecutive reads
local function read_validated_display(digit_mode)
	local previous_read = nil
	local fallback_empty = (digit_mode == "full") and "    " or "  "
	
	for sample = 1, 10 do
		local d1, d2, d3, d4 = gather_display_segments(15)
		emu.wait(0.05)
		
		local visual_string
		if digit_mode == "full" then
			visual_string = digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4)
		elseif digit_mode == "first_two" then
			visual_string = digit_ascii(d1) .. digit_ascii(d2)
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

-- A quick local helper to absolutely guarantee zero string concatenation crashes
local function safe_str(val, default)
	if val == nil then return default end
	return tostring(val)
end

function interface.show_info(on)
	if not on then return nil end

	-- Check the state of the calculation hardware status indicator LED
	local led_105_state = machine.devices[":"]:output("led105")
	local move_is_found = led_105_state and led_105_state:get() ~= 0

	-- Short circuit loop if a print lock is actively engaged
	if interface.lock_print then
		return nil
	end

	-- If the indicator turns ON, the move has been found!
	if move_is_found then
		interface.lock_print = true -- Engage print lock instantly
		return "info score cp " .. safe_str(interface.score, "0") .. " depth " .. safe_str(interface.depth, "0") .. " pv " .. safe_str(interface.pv, "")
	end

	local throttled_state = machine.video.throttled
	machine.video.throttled = true
	
	local raw_pv = "    "
	local raw_score = "    "
	local raw_depth = "  "
	
	-- =================================================================
	-- STEP 1: COLLECT THE PRINCIPAL VARIATION (PV)
	-- =================================================================
	send_input(":KEY.0", 0x08, 0.2) -- INFO
	emu.wait(0.2)
	raw_pv = read_validated_display("full")
	interface.pv = raw_pv
	
	-- Mid-navigation race fallback check for high-speed emulation drops
	if machine.devices[":"]:output("led105") and machine.devices[":"]:output("led105"):get() ~= 0 then
		interface.lock_print = true
		send_input(":KEY.0", 0x01, 0.2) -- CL
		machine.video.throttled = throttled_state
		return "info score cp " .. safe_str(interface.score, "0") .. " depth " .. safe_str(interface.depth, "0") .. " pv " .. safe_str(interface.pv, "")
	end
	
	-- =================================================================
	-- STEP 2: COLLECT THE CENTIPAWN SCORE (CP)
	-- =================================================================
	send_input(":KEY.1", 0x08, 0.2) -- 1
	emu.wait(0.2)
	raw_score = read_validated_display("full")
	local cleaned_score = raw_score:gsub(" ", "")
	
	if cleaned_score:match("[a-h]%d") then
		cleaned_score = ""
	end
	
	interface.score = cleaned_score
	if interface.score == "" then interface.score = "0" end
	
	-- =================================================================
	-- STEP 3: COLLECT THE CURRENT DEPTH (WITH TIMING PROTECTION GATE)
	-- =================================================================
	-- Intercept immediately if a move was resolved during the step 2 delay
	if machine.devices[":"]:output("led105") and machine.devices[":"]:output("led105"):get() ~= 0 then
		interface.lock_print = true
		send_input(":KEY.0", 0x01, 0.2) -- CL
		machine.video.throttled = throttled_state
		return "info score cp " .. safe_str(interface.score, "0") .. " depth " .. safe_str(interface.depth, "0") .. " pv " .. safe_str(interface.pv, "")
	end

	send_input(":KEY.1", 0x40, 0.2) -- 3
	emu.wait(0.2)
	raw_depth = read_validated_display("first_two")
	interface.depth = raw_depth:gsub(" ", "")
	if interface.depth == "" then interface.depth = "0" end
	
	send_input(":KEY.0", 0x01, 0.2) -- CL
	emu.wait(0.1)
	
	machine.video.throttled = throttled_state
	
	-- Final safety sweep check right before sending the text output
	if machine.devices[":"]:output("led105") and machine.devices[":"]:output("led105"):get() ~= 0 then
		interface.lock_print = true
		return "info score cp " .. safe_str(interface.score, "0") .. " depth " .. safe_str(interface.depth, "0") .. " pv " .. safe_str(interface.pv, "")
	end

	return "info score cp " .. safe_str(interface.score, "0") .. " depth " .. safe_str(interface.depth, "0") .. " pv " .. safe_str(interface.pv, "")
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
