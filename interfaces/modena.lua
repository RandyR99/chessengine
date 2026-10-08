interface = {}

interface.level = "a2"
interface.cur_level = nil
interface.depth = "0"
interface.score = "0"
interface.pv = ""

function interface.get_module()
	if machine.system.name == "modena" then
		return "Mephisto Modena"
	elseif machine.system.name == "modenaa" then
		return "Mephisto Modena v2"
	elseif machine.system.name == "modenab" then
		return "Mephisto Modena v3"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Frans Morsch"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1,1)]
	if (x > 5) then
		return
	end
	local y = interface.level:sub(2,2)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY", 0x10, 1)  -- LEVEL
	emu.wait(0.5)
	sb_press_square(":board", 1, x, y)
	emu.wait(0.5)
	send_input(":KEY", 0x80, 1) -- CLEAR
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(1)
	ioport.ports[":KEY"]:field(0x80):set_value(1)
	ioport.ports[":KEY"]:field(0x40):set_value(1)
	emu.wait(0.5)
	ioport.ports[":KEY"]:field(0x40):set_value(0)
	ioport.ports[":KEY"]:field(0x80):set_value(0)
	emu.wait(2)
	machine.video.throttled = throttled_state
	interface.cur_level = "a2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY", 0x08, 0.5) -- POS
		send_input(":KEY", 0x40, 0.5) -- ENT
		send_input(":KEY", 0x40, 0.5) -- ENT
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":KEY", 0x01 << (6 - math.abs(p)), 0.5)
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					if p < 0 then
						sb_press_square(":board", 0.5, x, 9 - y)
					end
					piece = p
				end
			end
		end
		send_input(":KEY", 0x80, 0.5) -- CL
		if mode == -1 then
			send_input(":KEY", 0x40, 0.5) -- ENT
		end
		send_input(":KEY", 0x80, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY", 0x04, 0.5) -- MEMORY
	else
		send_input(":KEY", 0x80, 0.5) -- CLEAR
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY", 0x80, 1) -- CLEAR
	send_input(":KEY", 0x40, 1) -- ENTER
	machine.video.throttled = throttled_state
end

-- Fast passive multi-frame segment harvester (no emu.wait)
local function gather_display_segments(cycles)
	local r3, r2, r1, r0 = 0, 0, 0, 0
	local root = machine.devices[":"]
	for i = 1, cycles do
		local p3 = root:output("digit3")
		local p2 = root:output("digit2")
		local p1 = root:output("digit1")
		local p0 = root:output("digit0")
		
		r3 = r3 | (p3 and p3:get() or 0)
		r2 = r2 | (p2 and p2:get() or 0)
		r1 = r1 | (p1 and p1:get() or 0)
		r0 = r0 | (p0 and p0:get() or 0)
	end
	return r3 & 0x7f, r2 & 0x7f, r1 & 0x7f, r0 & 0x7f
end

-- Reads the display strings repeatedly over 2 seconds, requiring 2 identical consecutive reads
local function read_validated_display(digit_mode)
	local previous_read = nil
	local fallback_empty = (digit_mode == "full") and "    " or "  "
	
	for sample = 1, 20 do
		-- OPTIMIZED: Reduced inner frame cycle count from 60 down to 10 to clear thread choke
		local d1, d2, d3, d4 = gather_display_segments(10)
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

function interface.is_selected(x, y)
	local xvals = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yvals = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	
	local d0, d1, d2, d3 = gather_display_segments(5)
	
	local root = machine.devices[":"]
	local x_node = root:output("1." .. tostring(x - 1))
	local y_node = root:output("2." .. tostring(y - 1))
	local xval = x_node and x_node:get() ~= 0 or false
	local yval = y_node and y_node:get() ~= 0 or false
	
	return (xvals[x] == d0 and yvals[y] == d1) or (xvals[x] == d2 and yvals[y] == d3) or (xval and yval)
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "a2" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		interface.level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local d0, d1, _, d3 = gather_display_segments(10)
	if (d0 == 0x73 and d1 == 0x50) then	-- display shows 'Pr'
		if     (d3 == 0x5e) then return "q"
		elseif (d3 == 0x31) then return "r"
		elseif (d3 == 0x38) then return "b"
		elseif (d3 == 0x6d) then return "n"
		end
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":KEY", 0x10, 1)
	elseif (piece == "r") then send_input(":KEY", 0x08, 1)
	elseif (piece == "b") then send_input(":KEY", 0x04, 1)
	elseif (piece == "n") then send_input(":KEY", 0x02, 1)
	elseif (piece == "Q" or piece == "R" or piece == "B" or piece == "N") then
		sb_press_square(":board", 1, x, y)
	end
end

function interface.show_info(on)
	if on then
		send_input(":KEY", 0x80, 0.3) -- CLEAR
		emu.wait(0.1)
		send_input(":KEY", 0x02, 0.3) -- INFO
		emu.wait(0.2)
		interface.pv = read_validated_display("full")
		
		send_input(":KEY", 0x02, 0.3) -- INFO (Second Press)
		emu.wait(0.2)
		local raw_score = read_validated_display("full")
		interface.score = raw_score:gsub(" ", "")
		
		send_input(":KEY", 0x40, 0.3) -- ENTER
		emu.wait(0.2)
		local raw_depth = read_validated_display()
		interface.depth = raw_depth:gsub(" ", "")
		
		emu.wait(0.05)
		send_input(":KEY", 0x80, 0.3) -- CLEAR
		
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
	return " "
end

return interface

