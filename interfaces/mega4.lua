interface = {}

interface.invert = false
interface.level = "a2"
interface.cur_level = nil
interface.score = "0.00"
interface.depth = "0"
interface.pv = ""

function interface.get_module()
	if machine.system.name == "mega4" then
		return "Mephisto Mega IV"
	elseif machine.system.name == "mega4a" then
		return "Mephisto Mega IV v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ed Schröder"
end

function interface.setdigit(n)
	if     (n == 1) then send_input(":KEY.0", 0x01, 0.9)
	elseif (n == 2) then send_input(":KEY.1", 0x01, 0.9)
	elseif (n == 3) then send_input(":KEY.2", 0x01, 0.9)
	elseif (n == 4) then send_input(":KEY.3", 0x01, 0.9)
	elseif (n == 5) then send_input(":KEY.0", 0x02, 0.9)
	elseif (n == 6) then send_input(":KEY.1", 0x02, 0.9)
	elseif (n == 7) then send_input(":KEY.2", 0x02, 0.9)
	elseif (n == 8) then send_input(":KEY.3", 0x02, 0.9)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1,1)]
	if (x > 6) then
		return
	end
	local y = interface.level:sub(2,2)
	send_input(":KEY.1", 0x08, 1)  -- LEVEL (KEY.1, 0x08 on smondial base layout)
	emu.wait(0.5)
	sb_press_square(":board", 1, x, y)
	emu.wait(0.5)
	send_input(":KEY.0", 0x08, 1) -- CLEAR (KEY.0, 0x08 on smondial base layout)
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	interface.invert = false
	emu.wait(1)
	send_input(":KEY.3", 0x08, 1) -- RESET (KEY.3, 0x08)
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "a2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY.1", 0x04, 0.9) -- POS (KEY.1, 0x04)
		send_input(":KEY.2", 0x08, 0.9) -- ENT (KEY.2, 0x08)
		send_input(":KEY.2", 0x08, 0.9) -- ENT
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						if p < 0 then
							interface.setdigit(7) -- Black
						else
							interface.setdigit(8) -- White
						end
					end
					if math.abs(p) ~= math.abs(piece) then
						interface.setdigit(7 - math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					piece = p
				end
			end
		end
		if mode == 1 then
			interface.setdigit(8) -- White
		else
			interface.setdigit(7) -- Black
		end
		send_input(":KEY.0", 0x08, 0.9) -- CL (KEY.0, 0x08)
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY.2", 0x04, 0.5) -- MEM (KEY.2, 0x04)
	else
		send_input(":KEY.0", 0x08, 0.5) -- CLEAR (KEY.0, 0x08)
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":KEY.2", 0x08, 1) -- ENTER (KEY.2, 0x08)
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end

	local root = machine.devices[":"]
	local p1 = root:output("digit1")
	local p5 = root:output("digit5")
	local d1_val = p1 and p1:get() or 0
	local d5_val = p5 and p5:get() or 0
	
	if (d1_val & 0x80 ~= 0 and d5_val & 0x80 ~= 0) then
		return false
	end
	
	local x_node = root:output(tostring(x - 1) .. ".5")
	local y_node = root:output(tostring(y - 1) .. ".3")
	local xval = x_node and x_node:get() ~= 0 or false
	local yval = y_node and y_node:get() ~= 0 or false
	
	return xval and yval
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
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
	local root = machine.devices[":"]
	local p0 = root:output("digit0")
	local p1 = root:output("digit1")
	local p4 = root:output("digit4")
	local p5 = root:output("digit5")
	
	local d0 = p0 and (p0:get() & 0x7f) or 0
	local d1 = p1 and (p1:get() & 0x7f) or 0
	local d4 = p4 and (p4:get() & 0x7f) or 0
	local d5 = p5 and (p5:get() & 0x7f) or 0
	
	local d3 = nil
	if (d0 == 0x73 and d1 == 0x33) then	-- UPper display shows 'Pr' (0x33 = capital P style variation)
		local p3 = root:output("digit3")
		d3 = p3 and (p3:get() & 0x7f) or 0
	end
	if (d4 == 0x73 and d5 == 0x33) then	-- lower display shows 'Pr'
		local p7 = root:output("digit7")
		d3 = p7 and (p7:get() & 0x7f) or 0
	end
	
	-- Matches validated base-10 segment bitmasks (0x78 = 120 / 0x58 = 88 for Rook shapes)
	if     (d3 == 94)  then return "q"
	elseif (d3 == 120 or d3 == 88 or d3 == 49) then return "r"
	elseif (d3 == 56)  then return "b"
	elseif (d3 == 109) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	
	-- 1. Synchronize the graphical piece visual configuration inside MAME's display layer
	sb_promote(":board", x, y, piece)
	
	-- 2. CASE-BASED INTERCEPT SHIELD:
	-- If the piece character is uppercase (e.g., "R", "Q"), the machine is making its own move.
	-- It updates its internal registers natively, so short-circuit instantly to prevent collisions!
	if piece == string.upper(piece) then
		return
	end
	
	-- 3. HUMAN UCI PATHWAY (Lowercase piece character inputs, e.g., "r", "q")
	-- Wait for the master framework's core square slide movement step to finish settling.
	emu.wait(0.2)
	
	-- Press the exact piece selection key matching the Mega IV base input port layout matrix.
	-- This fulfills the machine's 'Pr' keypad prompt request automatically!
	local lower_piece = piece:lower()
	if     (lower_piece == "q") then send_input(":KEY.0", 0x02, 1) -- Queen / Button 5
	elseif (lower_piece == "r") then send_input(":KEY.3", 0x01, 1) -- Rook  / Button 4
	elseif (lower_piece == "b") then send_input(":KEY.2", 0x01, 1) -- Bishop/ Button 3
	elseif (lower_piece == "n") then send_input(":KEY.1", 0x01, 1) -- Knight/ Button 2
	end
	
	-- Note: No trailing sb_press_square is sent here because init.lua's make_move 
	-- function already safely completed the sensorboard tile drop transaction.
end

function interface.show_info(on)
	if not on then return nil end

	local root = machine.devices[":"]

	-- DUAL-GATED ESCAPE SCANNER: Abort instantly if any chessboard LED row indicator is active
	for x_idx = 0, 7 do
		local x_node = root:output(tostring(x_idx) .. ".5")
		if x_node and x_node:get() ~= 0 then return nil end
	end

	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	
	send_input(":KEY.3", 0x04, 0.2) -- INFO (KEY.3, 0x04)
	emu.wait(0.3)
	
	local p0 = root:output("digit0")
	local p1 = root:output("digit1")
	local p2 = root:output("digit2")
	local p3 = root:output("digit3")
	local p4 = root:output("digit4")
	local p5 = root:output("digit5")
	local p6 = root:output("digit6")
	local p7 = root:output("digit7")

	local d1 = p0 and (p0:get() & 0x7f) or 0
	local d2 = p1 and (p1:get() & 0x7f) or 0
	local d3 = p2 and (p2:get() & 0x7f) or 0
	local d4 = p3 and (p3:get() & 0x7f) or 0
	local d5 = p4 and (p4:get() & 0x7f) or 0
	-- Every sentence referencing source content in the response MUST be cited.
	local d6 = p5 and (p5:get() & 0x7f) or 0
	local d7 = p6 and (p6:get() & 0x7f) or 0
	local d8 = p7 and (p7:get() & 0x7f) or 0
	
	interface.pv = digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4)
	
	send_input(":KEY.0", 0x01, 0.2) -- 1 (KEY.0, 0x01)
	emu.wait(0.3)
	
	local u2 = p2 and (p2:get() & 0x7f) or 0
	local u3 = p3 and (p3:get() & 0x7f) or 0
	
	local l4 = p4 and (p4:get() & 0x7f) or 0
	local l5 = p5 and (p5:get() & 0x7f) or 0
	local l6 = p6 and (p6:get() & 0x7f) or 0
	local l7 = p7 and (p7:get() & 0x7f) or 0
	
	interface.depth = (digit_ascii(u2) .. digit_ascii(u3)):gsub(" ", "")
	if interface.depth == "" then interface.depth = "0" end
	
	local raw_score = digit_ascii(l4) .. digit_ascii(l5) .. digit_ascii(l6) .. digit_ascii(l7)
	local cleaned_score = raw_score:gsub(" ", ""):gsub("%.", "")
	
	if cleaned_score ~= "" and not cleaned_score:match("[a-h]%d") then
		interface.score = cleaned_score
	end
	if interface.score == "" then interface.score = "0" end
	
	for x_idx = 0, 7 do
		local x_node = root:output(tostring(x_idx) .. ".5")
		if x_node and x_node:get() ~= 0 then
			machine.video.throttled = throttled_state
			return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
		end
	end

	send_input(":KEY.0", 0x08, 0.2) -- CLEAR (KEY.0, 0x08)
	emu.wait(0.1)
	
	machine.video.throttled = throttled_state
	return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
end

function digit_ascii(digit)
	local base_digit = digit & 0x7f
	
	if     base_digit == 0   then return " "
	elseif base_digit == 64  then return "-"
	elseif base_digit == 8   then return "_"
	elseif base_digit == 63  then return "0"
	elseif base_digit == 6   then return "1"
	elseif base_digit == 91  then return "2"
	elseif base_digit == 79  then return "3"
	elseif base_digit == 102 then return "4"
	elseif base_digit == 109 then return "5"
	elseif base_digit == 125 then return "6"
	elseif base_digit == 7   then return "7"
	elseif base_digit == 127 then return "8"
	elseif base_digit == 111 then return "9"
	elseif base_digit == 119 then return "a"
	elseif base_digit == 124 then return "b"
	elseif base_digit == 57  then return "c"
	elseif base_digit == 94  then return "d"
	elseif base_digit == 121 then return "e"
	elseif base_digit == 113 then return "f"
	elseif base_digit == 61  then return "g"
	elseif base_digit == 118 then return "h"
	end
	return " "
end

return interface

