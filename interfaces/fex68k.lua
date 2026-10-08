interface = {}

interface.opt_clear_announcements = true
interface.level = "a1"
interface.cur_level = nil
interface.score = "000"
interface.depth = "0"
interface.pv = ""

interface.info_tick = 0

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
	send_input(":IN.0", 0x08, 1)  -- LEVEL (0x08)
	emu.wait(0.5)
	sb_press_square(":board", 1, x, y)
	emu.wait(0.5)
	send_input(":IN.0", 0x80, 1)  -- CLEAR (0x80)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	interface.score = "000"
	interface.depth = "0"
	interface.pv = ""
	interface.info_tick = 0
	
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = "a1"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x04, 0.5) -- OPTIONS (0x04)
		sb_press_square(":board", 0.5, 7, 1) -- Clear board (g1)
		send_input(":IN.0", 0x80, 0.5) -- CLEAR (0x80)
		emu.wait(0.5)
		send_input(":IN.0", 0x80, 0.5) -- CLEAR
		send_input(":IN.0", 0x04, 0.5) -- OPTIONS
		send_input(":IN.0", 0x02, 0.5) -- VERIFY (0x02)
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
		
		-- =========================================================================
		-- SENSORY BUFFER COOLDOWN CUSHION:
		-- Yields for 0.5 emulated seconds unthrottled to let the 16-bit 68000 CPU 
		-- fully scan, register, and lock onto all 64 square updates completely!
		-- =========================================================================
		emu.wait(0.5)
		
		-- Force throttling ON to normalize panel keyboard matrix stability
		machine.video.throttled = true
		
		send_input(":IN.0", 0x80, 0.6) -- CLEAR (Exit Board Setup Mode cleanly)
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

if machine.system.name ~= "fex68k" then
	function interface.edit_game(on)
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":IN.0", 0x04, 0.5) -- OPTIONS
		sb_press_square(":board", 1, 3, 1)
		send_input(":IN.0", 0x80, 0.5) -- CLEAR
		emu.wait(0.5)
		machine.video.throttled = throttled_state
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x40, 1) -- MOVE (0x40)
end

function interface.clear_announcements()
	local root = machine.devices[":"]
	local d0_node = root:output("digit0")
	local d2_node = root:output("digit2")
	local d4_node = root:output("digit4")
	local d6_node = root:output("digit6")

	local d0 = d0_node and d0_node:get() or 0
	local d2 = d2_node and d2_node:get() or 0
	local d4 = d4_node and d4_node:get() or 0
	local d6 = d6_node and d6_node:get() or 0

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

	local root = machine.devices[":"]
	if not root then return false end
	
	local file_idx = x - 1
	local rank_idx = 16 - y
	local node_tag = tostring(file_idx) .. "." .. tostring(rank_idx)
	local led_node = root:output(node_tag)
	
	if (y == 1) then
		-- Clean Debounce loop for all Rank 1 squares (including d1/e1) 
		-- to filter out multiplex noise without blinding the castling rights!
		local safety_counter = 0
		for i = 1, 5 do
			local led_idx_val = led_node and led_node:get() or 0
			if led_idx_val == 0 then
				return false
			end
			emu.wait(0.01)
			
			safety_counter = safety_counter + 1
			if safety_counter > 10 then break end
		end
		return true
	else
		-- Modern real-time node polling for ranks 2-8
		return led_node and led_node:get() == 1
	end
end

function interface.select_piece(x, y, event)
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
		local root_dev = machine.devices[":"]
		local promote_counter = 0
		local rank_idx = x - 1
		local file_idx = 16 - y
		local node_tag = tostring(rank_idx) .. "." .. tostring(file_idx)
		
		for i = 1, 5 do
			local check_node = root_dev:output(node_tag)
			local check_val = check_node and check_node:get() or 0
			if check_val ~= 0 then
				send_input(":IN.0", 0x80, 0.5) -- CLEAR (0x80)
				return true
			end
			emu.wait(0.1)
			
			promote_counter = promote_counter + 1
			if promote_counter > 10 then break end
		end
		return false
	end
	
	if (interface.opt_clear_announcements) then
		interface.clear_announcements()
	end
	
	send_input(":IN.0", 0x02, 0.5) -- VERIFY (0x02)
	
	send_input(":IN.0", 0x04, 0.5) -- Queen (0x04)
	if board_led(x, y) then return "Q" end
	
	send_input(":IN.0", 0x08, 0.5) -- Rook (0x08)
	if board_led(x, y) then return "R" end
	
	send_input(":IN.0", 0x10, 0.5) -- Bishop (0x10)
	if board_led(x, y) then return "B" end
	
	send_input(":IN.0", 0x20, 0.5) -- Knight (0x20)
	if board_led(x, y) then return "N" end
	
	send_input(":IN.0", 0x80, 0.5) -- CLEAR (0x80)
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
	if not on or on == false then
		return ""
	end
	
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local root = machine.devices[":"]
	
	interface.info_tick = interface.info_tick + 1
	local step = interface.info_tick % 3
	
	sb_press_square(":board", 0.5, 2, 1) -- Press b1 down
	emu.wait(0.2)
	
	sb_press_square(":board", 0.5, 1, 1) -- Press a1 down
	emu.wait(1)
		
	local d3 = root:output("digit2") and root:output("digit2"):get() or 0
	local d4 = root:output("digit0") and root:output("digit0"):get() or 0
	local check_depth = (digit_ascii(d3) .. digit_ascii(d4)):gsub("%s", "")
	
	if check_depth:match("^%d+$") and check_depth ~= "0" then
		local cur_d = tonumber(check_depth)
		local prev_d = tonumber(interface.depth) or 0
		
		if check_depth:len() <= 2 and (prev_d == 0 or (cur_d <= prev_d + 1 and cur_d >= prev_d)) then
			interface.depth = check_depth
		end
	end
		
	sb_press_square(":board", 0.5, 3, 1) -- Press c1 down
	emu.wait(0.2)
	
	sb_press_square(":board", 0.5, 2, 1) -- Press b1 down
	emu.wait(1)
		
	local d2 = root:output("digit4") and root:output("digit4"):get() or 0
	local d3_sc = root:output("digit2") and root:output("digit2"):get() or 0
	local d4_sc = root:output("digit0") and root:output("digit0"):get() or 0
	
	local dot1 = root:output("4.7") and root:output("4.7"):get() or 0
	local dot2 = root:output("6.7") and root:output("6.7"):get() or 0
	local is_clock_frame = (dot1 ~= 0 and dot2 ~= 0)
	
	if not is_clock_frame then
		local check_score = (digit_ascii(d2) .. digit_ascii(d3_sc) .. digit_ascii(d4_sc)):gsub("%s", "")
		if check_score:match("^[0-9%-%.]+$") and check_score ~= "" then
			interface.score = check_score
		end
	end
		
	sb_press_square(":board", 0.5, 5, 1) -- Press e1 down
	emu.wait(0.2)
	
	sb_press_square(":board", 0.5, 3, 1) -- Press c1 down
	emu.wait(1)
	
	local d1 = root:output("digit6") and root:output("digit6"):get() or 0
	local d2_pv = root:output("digit4") and root:output("digit4"):get() or 0
	local d3_pv = root:output("digit2") and root:output("digit2"):get() or 0
	local d4_pv = root:output("digit0") and root:output("digit0"):get() or 0
	
	local chr1 = digit_ascii(d1):lower()
	local chr2 = digit_ascii(d2_pv):lower()
	local chr3 = digit_ascii(d3_pv):lower()
	local chr4 = digit_ascii(d4_pv):lower()
	
	if chr1:match("^[a-h]$") and chr2:match("^[1-8]$") and chr3:match("^[a-h]$") and chr4:match("^[1-8]$") then
		interface.pv = chr1 .. chr2 .. chr3 .. chr4
	end
	
	sb_press_square(":board", 0.5, 5, 1) -- Standalone exit tap
	emu.wait(1)
	
	machine.video.throttled = throttled_state
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

