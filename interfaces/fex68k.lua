interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.opt_clear_announcements = true
interface.level = "a1"
interface.cur_level = nil
interface.info_every = 1 -- show_info only reads the display

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

-- the display options (manual p. 15-16: B1 depth, C1 score, E1 first move of the main line, A1 move time off) can
-- only be switched on while the machine thinks, and stay on until pressed again (also after NEW GAME): set them in a
-- short search of a problem position without book moves (kings and a pawn), then start a new game
function interface.display_options()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x04, 0.5) -- OPTIONS
	sb_press_square(":board", 0.5, 7, 1) -- Clear board (g1)
	send_input(":IN.0", 0x80, 0.5) -- CLEAR
	emu.wait(0.5)
	send_input(":IN.0", 0x80, 0.5) -- CLEAR
	send_input(":IN.0", 0x04, 0.5) -- OPTIONS
	send_input(":IN.0", 0x02, 0.5) -- VERIFY: problem mode
	send_input(":IN.0", 0x02, 0.5) -- King
	emu.wait(0.4)
	sb_press_square(":board", 0.5, 5, 1) -- white e1
	sb_press_square(":board", 0.5, 5, 8) -- black e8 (second press: black)
	sb_press_square(":board", 0.5, 5, 8)
	send_input(":IN.0", 0x40, 0.5) -- Pawn
	emu.wait(0.4)
	sb_press_square(":board", 0.5, 4, 2) -- white d2
	emu.wait(0.5)
	send_input(":IN.0", 0x80, 0.6) -- CLEAR: leave board setup
	emu.wait(0.6)
	send_input(":IN.0", 0x40, 0.5) -- MOVE
	emu.wait(1.5)
	sb_press_square(":board", 0.5, 2, 1) -- B1 depth
	sb_press_square(":board", 0.5, 3, 1) -- C1 score
	sb_press_square(":board", 0.5, 5, 1) -- E1 main line
	sb_press_square(":board", 0.5, 1, 1) -- A1 move time off (only possible with another option on)
	emu.wait(1)
	send_input(":IN.0", 0x01, 1) -- NEW GAME
	emu.wait(1)
	send_input(":IN.0", 0x80, 1) -- CLEAR: fex68km4a starts its RAM test ("512") again with NEW GAME
	emu.wait(1)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.display_options()
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

-- with the display options set by display_options() the display (digit6 digit4 digit2 digit0) rotates every second
-- while the machine thinks: the first move of the main line ("b8c6"), the score in centipawns for the machine (" 035"
-- = 0.35, "-001"; its point lights dot 6.7) and the moves examined followed by the ply depth ("16 5")
local segment_digit = { [0x3f] = 0, [0x06] = 1, [0x5b] = 2, [0x4f] = 3, [0x66] = 4, [0x6d] = 5, [0x7d] = 6, [0x07] = 7,
	[0x7f] = 8, [0x67] = 9, [0x6f] = 9 }
local segment_file = { [0x77] = "a", [0x7c] = "b", [0x39] = "c", [0x5e] = "d", [0x79] = "e", [0x71] = "f", [0x3d] = "g", [0x76] = "h" }
local info = {}

function interface.show_info(on)
	if not on then
		info = {}
		return nil
	end
	local v = { output_value("digit6") & 0x7f, output_value("digit4") & 0x7f, output_value("digit2") & 0x7f, output_value("digit0") & 0x7f }
	local d = { segment_digit[v[1]], segment_digit[v[2]], segment_digit[v[3]], segment_digit[v[4]] }
	if output_value("4.7") ~= 0 then
		-- the move time (colon: dots 4.7-7.7), shown although A1 was pressed
	elseif segment_file[v[1]] and d[2] and segment_file[v[3]] and d[4] then
		info.pv = { segment_file[v[1]] .. d[2] .. segment_file[v[3]] .. d[4] }
	elseif v[3] == 0 and d[4] then
		if d[4] > 0 then -- ply 0 shows before the first iteration
			info.depth = d[4]
		end
	elseif output_value("6.7") ~= 0 and d[2] and d[3] and d[4] and (v[1] == 0 or v[1] == 0x40 or d[1]) then
		local score = (d[1] or 0) * 1000 + d[2] * 100 + d[3] * 10 + d[4]
		info.score = v[1] == 0x40 and -score or score
	end
	return { score = info.score, depth = info.depth, pv = info.pv }
end

return interface

