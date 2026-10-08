interface = {}

interface.level = 3
interface.cur_level = nil
interface.score = "0.00"
interface.depth = "0"
interface.pv = ""

function interface.get_module()
	if machine.system.name == "mephisto3" then
		return "Mephisto III"
	elseif machine.system.name == "mephisto3a" then
		return "Mephisto III v2"
	elseif machine.system.name == "mephisto3b" then
		return "Mephisto III v3"
	elseif machine.system.name == "mephisto3c" then
		return "Mephisto III v4"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Thomas Nitsche & Elmar Henne"
end

function interface.setdigit(n)
	if     (n == 0)	then send_input(":IN.3", 0x01, 0.5)
	elseif (n == 1)	then send_input(":IN.0", 0x02, 0.5)
	elseif (n == 2)	then send_input(":IN.0", 0x08, 0.5)
	elseif (n == 3)	then send_input(":IN.1", 0x02, 0.5)
	elseif (n == 4)	then send_input(":IN.1", 0x08, 0.5)
	elseif (n == 5)	then send_input(":IN.2", 0x02, 0.5)
	elseif (n == 6)	then send_input(":IN.2", 0x08, 0.5)
	elseif (n == 7)	then send_input(":IN.3", 0x02, 0.5)
	elseif (n == 8)	then send_input(":IN.3", 0x08, 0.5)
	elseif (n == 9)	then send_input(":IN.2", 0x04, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x04, 0.5) -- LEV
	local n = tonumber(interface.level)
	interface.setdigit(n)
	send_input(":IN.0", 0x04, 0.5) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	send_input(":RESET", 0x01, 0.5) -- RES
	emu.wait(1)
	send_input(":IN.0", 0x01, 0.5) -- CL
	machine.video.throttled = throttled_state
	interface.cur_level = 3
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.2", 0x01, 0.5) -- POS
		for i = 1, 14 do
			send_input(":IN.0", 0x04, 0.5) -- ENT
		end
		machine.video.throttled = throttled_state
		return (":board")
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
					send_input(":IN.0", 0x04, 0.5) -- ENT
				end
			end
		end
		if mode == 1 then
			interface.setdigit(0) -- White
		else
			interface.setdigit(9) -- Black
		end
		send_input(":IN.0", 0x04, 0.5) -- ENT
		send_input(":IN.0", 0x01, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":IN.3", 0x04, 0.5) -- MEM
	else
		send_input(":IN.0", 0x01, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.0", 0x04, 0.5) -- ENT
end

function interface.is_selected(x, y)
	local led_name = (y - 1) .. "." .. (x - 1)
	local led_state = machine.devices[":"]:output(led_name)
	return led_state and led_state:get() ~= 0
end

function interface.select_piece(x, y, event)
	if (event == "get_castling" or event == "en_passant" or event == "capture") then
		emu.wait(1)
	end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "3", "0", "9" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 0 or level > 9) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x01, 0.5)	-- INFO
	send_input(":IN.0", 0x02, 0.5)	-- 1
	send_input(":IN.3", 0x01, 0.5)	-- 0
	
	-- Resolve modern output proxies securely
	local d3_state = machine.devices[":"]:output("digit3")
	local d2_state = machine.devices[":"]:output("digit2")
	local d0_state = machine.devices[":"]:output("digit0")
	
	local d3 = d3_state and d3_state:get() or 0
	local d2 = d2_state and d2_state:get() or 0
	local d0 = 0
	
	if ((d3 & 0x7f) == 0x73 and (d2 & 0x7f) == 0x50) then	-- display shows 'Pr'
		d0 = d0_state and d0_state:get() or 0
	end
	
	send_input(":IN.1", 0x01, 0.5)	-- INFO
	machine.video.throttled = throttled_state
	
	local filtered_d0 = d0 & 0x7f
	if     (filtered_d0 == 0x5e) then return "q"
	elseif (filtered_d0 == 0x31) then return "r"
	elseif (filtered_d0 == 0x38) then return "b"
	elseif (filtered_d0 == 0x6d) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.2", 0x08, 0.5)
	elseif (piece == "r") then send_input(":IN.2", 0x02, 0.5)
	elseif (piece == "b") then send_input(":IN.1", 0x08, 0.5)
	elseif (piece == "n") then send_input(":IN.1", 0x02, 0.5)
	end
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		send_input(":IN.0", 0x04, 0.5) -- ENT
	end
end

-- Helper function to harvest display segments cleanly over a given timeframe (in frames)
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
		send_input(":IN.1", 0x01, 0.2) -- Info
		emu.wait(0.2)
		raw_pv = read_validated_display(true)
		interface.pv = raw_pv
		
		-- =================================================================
		-- STEP 2: COLLECT THE CENTIPAWN SCORE (CP)
		-- =================================================================
		send_input(":IN.0", 0x02, 0.2) -- Button '1'
		emu.wait(0.2)
		raw_score = read_validated_display(true)
		interface.score = raw_score:gsub(" ", "")
		-- Safe fallback if the score was stripped down to an empty string
		if interface.score == "" then interface.score = "0" end
		
		-- =================================================================
		-- STEP 3: COLLECT THE CURRENT DEPTH
		-- =================================================================
		send_input(":IN.1", 0x02, 0.2) -- Button '3'
		emu.wait(0.2)
		raw_depth = read_validated_display(false)
		interface.depth = raw_depth:gsub(" ", "")
		if interface.depth == "" then interface.depth = "0" end
		
		-- Reset layout screen state to default game board view
		send_input(":IN.0", 0x01, 0.2) -- CL
		emu.wait(0.1)
		
		machine.video.throttled = throttled_state
		
		-- Final double check to ensure NO values are nil before merging strings
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

