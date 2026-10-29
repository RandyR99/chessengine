interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.opt_clear_announcements = true
interface.level = "a1"
interface.cur_level = nil
interface.score = "000"
interface.depth = "0"
interface.pv = ""

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "fex68k" then
		return "Fidelity Excel 68000"
	elseif machine.system.name == "fex68ka" then
		return "Fidelity Excel 68000 v2"
	elseif machine.system.name == "fex68kb" then
		return "Fidelity Excel 68000 v3"
	elseif machine.system.name == "fex68km2" then
		return "Fidelity Excel Mach II"
	elseif machine.system.name == "fex68km2a" then
		return "Fidelity Excel Mach II v2"
	elseif machine.system.name == "fex68km3" then
		return "Fidelity Excel Mach III"
	elseif machine.system.name == "fex68km3a" then
		return "Fidelity Excel Mach III v2"
	elseif machine.system.name == "fex68km3b" then
		return "Fidelity Excel Mach III v3"
	elseif machine.system.name == "fex68km4" then
		return "Fidelity Excel Mach IV v1"
	elseif machine.system.name == "fex68km4a" then
		return "Fidelity Excel Mach IV v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = interface.level:sub(2, 2)
	send_input(":IN.0", 0x08, 1)  -- LEVEL
	emu.wait(0.5)
	sb_press_square(":board", 1, x, y)
	emu.wait(0.5)
	send_input(":IN.0", 0x80, 1)  -- CLEAR
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	interface.score = "000"
	interface.depth = "0"
	interface.pv = ""
	
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = "a1"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x04, 0.5) -- OPTIONS
		sb_press_square(":board", 0.5, 7, 1) -- Clear board (g1)
		send_input(":IN.0", 0x80, 0.5) -- CLEAR
		emu.wait(0.5)
		send_input(":IN.0", 0x80, 0.5) -- CLEAR
		send_input(":IN.0", 0x04, 0.5) -- OPTIONS
		send_input(":IN.0", 0x02, 0.5) -- VERIFY
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						local n = math.abs(p)
						if     n == 1 then send_input(":IN.0", 0x02, 0.5) -- King
						elseif n == 2 then send_input(":IN.0", 0x04, 0.5) -- Queen
						elseif n == 3 then send_input(":IN.0", 0x08, 0.5) -- Rook
						elseif n == 4 then send_input(":IN.0", 0x10, 0.5) -- Bishop
						elseif n == 5 then send_input(":IN.0", 0x20, 0.5) -- Knight
						elseif n == 6 then send_input(":IN.0", 0x40, 0.5) -- Pawn
						end
						emu.wait(0.4)
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					if p < 0 then
						sb_press_square(":board", 0.5, x, 9 - y)
					end
					piece = p
				end
			end
		end
		emu.wait(0.5) -- let the 68000 register the last square
		machine.video.throttled = true
		send_input(":IN.0", 0x80, 0.6) -- CLEAR: leave board setup
		emu.wait(0.6)
		
		if mode == -1 then
			send_input(":IN.0", 0x04, 0.5) -- OPTIONS
			sb_press_square(":board", 0.5, 5, 1) -- Change color (e1)
			send_input(":IN.0", 0x80, 0.5) -- CLEAR
			emu.wait(0.5)
		end
	end
	machine.video.throttled = throttled_state
end

-- the first Excel 68000 set cannot replay a history in Monitor Mode
if machine.system.name ~= "fex68k" then
	function interface.edit_game(on)
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		interface.editing = on
		send_input(":IN.0", 0x04, 0.5) -- OPTIONS
		sb_press_square(":board", 1, 3, 1)
		send_input(":IN.0", 0x80, 0.5) -- CLEAR
		emu.wait(0.5)
		machine.video.throttled = throttled_state
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x40, 1) -- MOVE
end

function interface.clear_announcements()
	local d0 = output_value("digit0")
	local d2 = output_value("digit2")
	local d4 = output_value("digit4")
	local d6 = output_value("digit6")

	if ((d4 == 0x37 and d0 ~= 0x00) or
	   (d6 == 0x5e and d4 == 0x50 and d0 == 0x4f) or
	   (d6 == 0x5e and d4 == 0x50 and d2 == 0x6d and d0 == 0x3f)) then
		send_input(":IN.0", 0x80, 1) -- CLEAR
	end
end

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end
	local led = tostring(x - 1) .. "." .. tostring(16 - y)
	-- the first line of LEDs is also used for announcements, so be sure that the LED does not flash
	if (y == 1) then
		for i = 1, 5 do
			if (output_value(led) == 0) then
				return false
			end
			emu.wait(0.15)
		end
		return true
	end
	return output_value(led) ~= 0
end

function interface.select_piece(x, y, event)
	if interface.editing then
		emu.wait(1) -- in Monitor Mode Mach III misses a fast lift/put (Qd8-h4+ in chk_h)
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
		interface.level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		interface.setlevel()
	end
	if (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function interface.test_promotion(x, y)
	local function board_led(x, y)
		for i = 1, 5 do
			if (output_value(tostring(x - 1) .. "." .. tostring(16 - y)) ~= 0) then
				send_input(":IN.0", 0x80, 0.5) -- CLEAR
				return true
			end
			emu.wait(0.1)
		end
		return false
	end
	
	if (interface.opt_clear_announcements) then
		interface.clear_announcements()
	end
	
	send_input(":IN.0", 0x02, 0.5) -- VERIFY
	
	send_input(":IN.0", 0x04, 0.5) -- Queen
	if board_led(x, y) then return "Q" end
	
	send_input(":IN.0", 0x08, 0.5) -- Rook
	if board_led(x, y) then return "R" end
	
	send_input(":IN.0", 0x10, 0.5) -- Bishop
	if board_led(x, y) then return "B" end
	
	send_input(":IN.0", 0x20, 0.5) -- Knight
	if board_led(x, y) then return "N" end
	
	send_input(":IN.0", 0x80, 0.5) -- CLEAR
	return "Q"
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	emu.wait(1)
	if     (piece == "q") then send_input(":IN.0", 0x04, 1) -- Queen
	elseif (piece == "r") then send_input(":IN.0", 0x08, 1) -- Rook
	elseif (piece == "b") then send_input(":IN.0", 0x10, 1) -- Bishop
	elseif (piece == "n") then send_input(":IN.0", 0x20, 1) -- Knight
	end
end

function interface.show_info(on)
	-- read only: pressing squares to cycle the display while the machine thinks lights
	-- first-rank LEDs that the move detection takes for the machine's move
	if (not on) then
		return ""
	end
	local d1 = output_value("digit6")
	local d2 = output_value("digit4")
	local d3 = output_value("digit2")
	local d4 = output_value("digit0")
	if (output_value("6.7") == 0) then
		if (digit_ascii(d1):match("^[a-h]$")) then
			interface.pv = digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4)
		else
			local depth = (digit_ascii(d3) .. digit_ascii(d4)):gsub(" ", "")
			if (depth:match("^%d+$")) then
				interface.depth = depth
			end
		end
	else
		local score = (digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4)):gsub(" ", "")
		if (score:match("^%-?%d+$")) then
			interface.score = score
		end
	end
	return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
end

function digit_ascii(digit)
	if     digit == nil then return " "
	elseif digit ==   0 then return " "
	elseif digit ==  63 then return "0"
	elseif digit ==   6 then return "1"
	elseif digit ==  91 then return "2"
	elseif digit ==  79 then return "3"
	elseif digit == 102 then return "4"
	elseif digit == 109 then return "5"
	elseif digit == 111 then return "5"
	elseif digit == 125 then return "6"
	elseif digit ==   7 then return "7"
	elseif digit == 127 then return "8"
	elseif digit == 103 then return "9"
	elseif digit == 119 then return "a"
	elseif digit == 124 then return "b"
	elseif digit ==  57 then return "c"
	elseif digit ==  94 then return "d"
	elseif digit == 121 then return "e"
	elseif digit == 113 then return "f"
	elseif digit == 123 then return "f"
	elseif digit ==  61 then return "g"
	elseif digit == 118 then return "h"
	end
	return " "
end

return interface

