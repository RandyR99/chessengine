local interface = {}

interface.opt_clear_announcements = true
interface.level = "a1"
interface.cur_level = nil

-- Status flag splits cold boot from runtime resets
interface.is_initialized = false

function interface.get_module()
	if machine.system.name == "feas" then
		return "Fidelity Elite A/S"
	elseif machine.system.name == "feasbu" then
		return "Fidelity Elite A/S Budapest"
	elseif machine.system.name == "feasbua" then
		return "Fidelity Elite A/S Budapest v2"
	elseif machine.system.name == "feasgla" then
		return "Fidelity Elite A/S Glasgow"
	elseif machine.system.name == "feasglaa" then
		return "Fidelity Elite A/S Glasgow v2"
	elseif machine.system.name == "feasglab" then
		return "Fidelity Elite A/S Glasgow v3"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setdigit(n,d)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local lcd_num = { 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67 }
	local led = n
	if (led == 1) then
		led = 0
	end
	
	local root = machine.devices[":"]
	while true do
		local digit_node = root:output("digit" .. led)
		local digit_val = digit_node and digit_node:get() or 0
		if digit_val == lcd_num[d + 1] then
			break
		end
		send_input(":IN.0", 0x10 << n, 0.25)  -- ST / TB / LV
	end
	machine.video.throttled = throttled_state
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
	send_input(":IN.0", 0x80, 0.5)  -- LV
	sb_press_square(":board", 1, x, y)
	local num = level:sub(4)
	if (num ~= "" and num:len() <= 2) then
		if (num:len() == 1) then
			num = "0" .. num
		end
		for i = 1, 2 do
			interface.setdigit(i + 1, num:sub(i,i))
		end
	else
		local k = 1
		while (num ~= "") do
			local d = num:sub(1,1)
			if (d == " ") then
				sb_press_square(":board", 1, x, y)
				k = 1
			elseif (d == "/") then
				sb_press_square(":board", 1, x, y)
				k = 2
			elseif (d ~= ":") then
				interface.setdigit(k,d)
				k = k + 1
			end
			num = num:sub(2)
		end
	end
	emu.wait(0.5)
	send_input(":IN.1", 0x02, 0.5) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	-- Cache master framework throttle profiles safely before accelerating
	local original_throttle_state = machine.video.throttled
	
	-- Force the video throttle configuration to False to run all macros unthrottled
	machine.video.throttled = false
	local root = machine.devices[":"]
	
	-- =========================================================================
	-- 0. CHECKMATE / ANNOUNCEMENT INTERCEPT SHIELD:
	-- If a checkmate has just occurred, the background loop will have lit up the 
	-- perimeter LEDs, deadlocking the panel keys. Forcefully pulse CL right here 
	-- to break the ROM out of its loop and wide open the keyboard matrix lines!
	-- =========================================================================
	if root then
		local edge_lit = true
		for i = 0, 7 do
			local node = root:output(tostring(i) .. ".15")
			if not node or node:get() == 0 then
				edge_lit = false
				break
			end
		end
		
		if edge_lit then
			-- Pulse Clear forcefully to break the checkmate loop deadlock
			send_input(":IN.1", 0x02, 0.5) -- CL
			emu.wait(0.5)
		end
	end
	-- =========================================================================
	
	interface.score = "000"
	interface.depth = "0"
	
	-- 1. HARDWARE BRANCHING GATE: COLD BOOT VS RUNTIME RESET
	if not interface.is_initialized then
		interface.is_initialized = true
		
		-- Locks throttling ON for exactly 5 real seconds so you can hear the full verbal introduction!
		machine.video.throttled = true
		emu.wait(5.0) -- Power-up voice synthesizer delay
		machine.video.throttled = false

		send_input(":IN.0", 0x02, 0.4) -- SPEAKER
		emu.wait(0.2)
		sb_press_square(":board", 0.4, 8, 8) -- Voice Off (Square H8)
		emu.wait(0.2)
		send_input(":IN.1", 0x02, 0.4) -- CL
		emu.wait(0.2)
		
		sb_reset_board(":board")
		emu.wait(1.0)
		
		send_input(":IN.0", 0x01, 0.4)  -- GC
		emu.wait(0.2)
		sb_press_square(":board", 0.4, 4, 8)  -- D8 (Factory Format)
		emu.wait(0.2)
		send_input(":IN.1", 0x02, 0.4) -- CL
		emu.wait(1.0)
		
		interface.cur_level = "reset"
		interface.level = "a1"
		interface.setlevel()
	else
		-- 2. RUNTIME UCINEWGAME RESET INTERCEPT TIMELINE
		send_input(":IN.0", 0x02, 0.4) -- SPEAKER
		emu.wait(0.2)
		sb_press_square(":board", 0.4, 8, 8) -- Voice Off (Square H8)
		emu.wait(0.2)
		send_input(":IN.1", 0x02, 0.4) -- CL
		emu.wait(0.2)
		
		local is_player_turn = true
		if root then
			local initial_ym = root:output("8.14") and root:output("8.14"):get() or 0
			
			for slice = 1, 15 do
				emu.wait(0.1)
				local current_ym = root:output("8.14") and root:output("8.14"):get() or 0
				if current_ym ~= initial_ym then
					is_player_turn = false
					break
				end
			end
			
			-- Force stop mid-calculation lookahead prior to the warm clear pass
			if not is_player_turn then
				send_input(":IN.1", 0x04, 0.5) -- RV
				emu.wait(0.2)
				send_input(":IN.1", 0x02, 0.4) -- CL
				emu.wait(0.2)
			end
		end
		
		sb_reset_board(":board")
		emu.wait(1.0)
		
		send_input(":IN.0", 0x01, 0.4)        -- GC
		emu.wait(0.2)
		sb_press_square(":board", 0.4, 4, 6)  -- D6 (Warm Reset Clear)
		emu.wait(0.2)
		send_input(":IN.1", 0x02, 0.4)       -- CL
		emu.wait(1.0)
	end

	-- 3. SCORE & DEPTH TOGGLE INTERCEPT MATRIX
	send_input(":IN.0", 0x01, 0.4)        -- GC
	emu.wait(0.3)
	
	-- Verify Display Stats Rotation (Option E1 -> Node 4.15)
	local e1_led = root:output("4.15") and root:output("4.15"):get() or 0
	if e1_led == 0 then
		sb_press_square(":board", 0.4, 5, 1)  -- Only press E1 if it's currently dark!
		emu.wait(0.2)
	end
	
	-- Verify Depth Multiplier Tracking (Option E3 -> Node 4.13)
	local e3_led = root:output("4.13") and root:output("4.13"):get() or 0
	if e3_led == 0 then
		sb_press_square(":board", 0.4, 5, 3)  -- Only press E3 if it's currently dark!
		emu.wait(0.2)
	end
	
	send_input(":IN.1", 0x02, 0.4)       -- CL
	emu.wait(0.3)

	-- 4. RESTORE SPEAKER VOICE SPEECH AUDIO
	send_input(":IN.0", 0x02, 0.4) -- SPEAKER
	emu.wait(0.2)
	sb_press_square(":board", 0.4, 7, 8) -- Voice On (Square G8)
	emu.wait(0.2)
	send_input(":IN.1", 0x02, 0.4) -- CL
	emu.wait(0.2)
	
	-- Return master engine back to standard speed profile configurations
	machine.video.throttled = original_throttle_state
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x02, 0.5) -- SPEAKER
		sb_press_square(":board", 1, 8, 8) -- Voice off
		send_input(":IN.1", 0x02, 0.5) -- CL
		send_input(":IN.0", 0x01, 0.5) -- GC
		sb_press_square(":board", 1, 4, 7) -- Clear board
		send_input(":IN.1", 0x02, 0.5) -- CL
		send_input(":IN.0", 0x04, 0.5) -- PB
		sb_clear_board(":board")
		machine.video.throttled = throttled_state
		return ("")
	else
		local piece = 7
		local z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.0", 0x01 << (math.abs(p) + 1), 0.5)
					end
					if p > 0 then
						z = 6 - p
					else
						z = 12 + p
					end
					send_input(":board:SPAWN", 0x01 << z, 0.09)
					sb_select_piece(":board", 1, x, 9 - y, "put")
					if p < 0 then
						sb_select_piece(":board", 1, x, 9 - y, "get")
						sb_select_piece(":board", 1, x, 9 - y, "put")
					end
					piece = p
				end
			end
		end
		send_input(":IN.1", 0x02, 0.5) -- CL
		if mode == -1 then
			send_input(":IN.0", 0x01, 0.5) -- GC
			sb_press_square(":board", 1, 4, 5) -- Change color
			send_input(":IN.1", 0x02, 0.5) -- CL
		end
		send_input(":IN.0", 0x02, 0.5) -- SPEAKER
		sb_press_square(":board", 1, 7, 8) -- Voice on
		send_input(":IN.1", 0x02, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.0", 0x01, 0.5) -- GAME CONTROL
	sb_press_square(":board", 1, 5, 6)
	send_input(":IN.1", 0x02, 0.5) -- CL
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.1", 0x04, 1) -- RV
end

function interface.clear_announcements()
	local root = machine.devices[":"]
	if not root then return end
	
	local all_lit = true
	for i = 0, 7 do
		local node = root:output(tostring(i) .. ".15")
		if not node or node:get() == 0 then
			all_lit = false
			break
		end
	end
	
	if all_lit then
		send_input(":IN.1", 0x02, 1) -- CL
	end
end

interface.signal_latch = {}

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end
	
	local root = machine.devices[":"]
	if not root then return false end
	
	-- Map the linear coordinate address tags matching the A/S hardware orientation
	local file_idx = x - 1
	local rank_idx = 16 - y
	local node_tag = tostring(file_idx) .. "." .. tostring(rank_idx)
	local led_node = root:output(node_tag)
	
	-- Read and return the raw, real-time hardware state natively with zero latching overhead
	return led_node and led_node:get() ~= 0
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
		local level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^a[1-8]$") or level:match("^b[1-7]$") or level:match("^b[4-6]%s%d%d?$") or level:match("^b%s%d:%d%d$") or level:match("^b2%s%d:%d%d%s%d:%d%d$") or level:match("^b3%s%d:%d%d/%d%d$") or level:match("^b3%s%d:%d%d/%d%d%s%d:%d%d/%d%d$") or level:match("^b3%s%d:%d%d/%d%d%s%d:%d%d/%d%d%s%d:%d%d$")) then
			interface.level = level
			interface.setlevel()
		end
	end
	if (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function interface.get_promotion_led()
	local root = machine.devices[":"]
	if not root then return nil end
	
	local q_node = root:output("8.9")
	local r_node = root:output("8.10")
	local b_node = root:output("8.11")
	local n_node = root:output("8.12")
	
	if     (q_node and q_node:get() ~= 0) then return 'q'
	elseif (r_node and r_node:get() ~= 0) then return 'r'
	elseif (b_node and b_node:get() ~= 0) then return 'b'
	elseif (n_node and n_node:get() ~= 0) then return 'n'
	end
	return nil
end

function interface.get_promotion(x, y)
	if (interface.opt_clear_announcements) then
		interface.clear_announcements()
	end
	interface.select_piece(x, y, "")
	local new_type = nil
	for i = 1, 5 do
		emu.wait(0.25)
		new_type = interface.get_promotion_led()
		if (new_type ~= nil) then
			break
		end
	end
	interface.select_piece(x, y, "")
	return new_type
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x08, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x20, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x40, 1)
	end
end

function interface.show_info(on)
	if not on then return "" end
	local root = machine.devices[":"]
	if not root then return "" end

	-- Target the true physical layout address tags for the central colons
	local upper_dot = root:output("0.7") and root:output("0.7"):get() or 0
	local lower_dot = root:output("1.7") and root:output("1.7"):get() or 0

	-- 1. CLOCK ROTATION GUARD:
	-- If the upper colon dot is lit, the display is completely frozen on the time clock.
	-- Skip parsing to protect our score cache variables, but continue streaming data!
	if upper_dot ~= 0 and lower_dot == 0 then
		return "info score cp " .. interface.score .. " depth " .. interface.depth
	end

	-- 2. Read the 4 raw physical display digit values natively
	local d1 = root:output("digit1") and root:output("digit1"):get() or 0
	local d2 = root:output("digit0") and root:output("digit0"):get() or 0
	local d3 = root:output("digit2") and root:output("digit2"):get() or 0
	local d4 = root:output("digit3") and root:output("digit3"):get() or 0

	-- Convert active layout digit nodes to clean ascii characters
	local ch1 = digit_ascii(d1):trim()
	local ch2 = digit_ascii(d2):trim()
	local ch3 = digit_ascii(d3):trim()
	local ch4 = digit_ascii(d4):trim()

	-- 3. CHARACTER SHIFT SPLIT STATE ENGINE
	if ch3 == "" and ch4 ~= "" then
		-- SIGNATURE A: DEPTH FRAME ACTIVE ('xx yy' layout with empty space at digit 3)
		local raw_hex_char = ch4
		if raw_hex_char:match("^[0-9A-Fb-d]$") then
			local depth_val = tonumber(raw_hex_char, 16)
			
			if raw_hex_char == "b" then depth_val = 11
			elseif raw_hex_char == "d" then depth_val = 13
			end
			
			if depth_val and depth_val > 0 then
				interface.depth = tostring(depth_val)
			end
		end
	elseif ch3 ~= "" then
		-- SIGNATURE B: SPLIT BASE-10 SCORE FRAME ACTIVE
		-- Fill any empty leading spaces with clean zeros to normalize parsing
		local hex1 = (ch1 ~= "" and ch1 or "0")
		local hex2 = (ch2 ~= "" and ch2 or "0")
		local hex3 = (ch3 ~= "" and ch3 or "0")
		local hex4 = (ch4 ~= "" and ch4 or "0")
		
		local upper_pair_str = hex1 .. hex2
		local lower_pair_str = hex3 .. hex4
		
		-- Decode both halves as hexadecimal to safely catch characters like '0F' into decimal 15
		if upper_pair_str:match("^[0-9A-Fa-f]+$") and lower_pair_str:match("^[0-9A-Fa-f]+$") then
			local upper_val = tonumber(upper_pair_str, 16) or 0
			local lower_val = tonumber(lower_pair_str, 16) or 0
			
			-- Execute your exact Base-10 shift equation (Upper * 100 + Lower)
			local score_num = (upper_val * 100) + lower_val
			
			-- If the hardware lower dot (1.7) is active, player has the advantage (negative score)
			if lower_dot ~= 0 then
				interface.score = "-" .. tostring(score_num)
			else
				interface.score = tostring(score_num)
			end
		end
	end

	return "info score cp " .. interface.score .. " depth " .. interface.depth
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
	elseif digit == 119 then return "A"
	elseif digit == 124 then return "b"
	elseif digit ==  57 then return "C"
	elseif digit ==  94 then return "d"
	elseif digit == 121 then return "E"
	elseif digit == 113 then return "F"
	elseif digit == 123 then return "F"
	end
	return " "
end

function string:trim()
	return self:match("^%s*(.-)%s*$")
end

return interface

