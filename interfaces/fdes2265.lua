interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board
interface.info_every = 1 -- show_info only reads the display

interface.opt_clear_announcements = true
interface.level = "a1"
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

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

local function rotating_display()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	
	send_input(":IN.0", 0x20, 1) -- option
	send_input(":IN.0", 0x20, 1) -- option
	
	local b2_val = output_value("1.1")
	if b2_val == 0 then
		sb_press_square(":board", 1, 2, 2)  -- b2
		emu.wait(0.5)
	end
	
	local c2_val = output_value("1.2")
	if c2_val == 0 then
		sb_press_square(":board", 1, 3, 2)  -- c2
		emu.wait(0.5)
	end
	
	local e2_val = output_value("1.4")
	if e2_val == 0 then
		sb_press_square(":board", 1, 5, 2)  -- e2
		emu.wait(0.5)
	end
	
	local a2_val = output_value("1.0")
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
	rotating_display()
	
	-- sound off
	throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x20, 1) -- OPTION
	
	local b1_val = output_value("1.1")
	if b1_val == 0 then
		sb_press_square(":board", 1, 2, 1)  -- b1
		emu.wait(0.5)
	end
	
	send_input(":IN.0", 0x01, 1) -- CLEAR
	send_input(":IN.0", 0x01, 1) -- CLEAR
	machine.video.throttled = throttled_state
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
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	local d4 = output_value("digit4")
	local d5 = output_value("digit5")
	-- clear announcements to continue the game
	if (((d3 == 0x54 or d3 == 0x37) and d5 ~= 0x00) or					-- '?M?x' forced checkmate found in X moves
	   (d2 == 0x5e and d3 == 0x50 and d5 == 0x4f) or					-- 'dr?3' threefold repetition
	   (d2 == 0x5e and d3 == 0x50 and d4 == 0x6d and d5 == 0x3f)) then	-- 'dr50' fifty-move rule
		send_input(":IN.0", 0x01, 1)
	end
end

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end
	return output_value("0." .. tostring(y - 1)) ~= 0 and output_value("1." .. tostring(x - 1)) ~= 0
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
		for n=1,8 do
			send_input(port, code, 0.5)
			for i=1,4 do
				if (output_value("0." .. tostring(y - 1)) ~= 0 and output_value("1." .. tostring(x - 1)) ~= 0) then
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


-- rotating display (set in setup_machine: B2 depth, C2 score, E2 first move of the main line, A2 time off; Mach IV
-- manual 3.8-3.16) changes every second while the machine thinks: the move ("d7d5"), the score in centipawns for
-- the machine (dot after the second character, output 3.7; "-9.99" is its limit) and the moves examined followed by
-- the ply depth ("12 6")
local segment_digit = { [0x3f] = 0, [0x06] = 1, [0x5b] = 2, [0x4f] = 3, [0x66] = 4, [0x6d] = 5, [0x7d] = 6, [0x07] = 7,
	[0x7f] = 8, [0x67] = 9, [0x6f] = 9 }
local segment_file = { [0x77] = "a", [0x7c] = "b", [0x39] = "c", [0x5e] = "d", [0x79] = "e", [0x71] = "f", [0x3d] = "g", [0x76] = "h" }

function interface.show_info(on)
	if not on then
		interface.score = nil
		interface.depth = nil
		interface.pv = nil
		return nil
	end
	local v = {}
	for i = 1, 4 do
		v[i] = output_value("digit" .. (i + 1)) & 0x7f
	end
	local d = { segment_digit[v[1]], segment_digit[v[2]], segment_digit[v[3]], segment_digit[v[4]] }
	if output_value("3.7") ~= 0 then
		if d[2] and d[3] and d[4] and (v[1] == 0 or v[1] == 0x40 or d[1]) then
			local score = (d[1] or 0) * 1000 + d[2] * 100 + d[3] * 10 + d[4]
			interface.score = v[1] == 0x40 and -score or score
		end
	elseif segment_file[v[1]] and d[2] and segment_file[v[3]] and d[4] then
		interface.pv = { segment_file[v[1]] .. d[2] .. segment_file[v[3]] .. d[4] }
	elseif v[3] == 0 and d[4] and d[4] > 0 then -- ply 0 shows before the first iteration
		interface.depth = d[4]
	elseif d[3] and d[4] then
		interface.depth = d[3] * 10 + d[4]
	end
	return { score = interface.score, depth = interface.depth, pv = interface.pv }
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

