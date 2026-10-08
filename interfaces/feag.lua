local interface = {}

interface.opt_clear_announcements = true
interface.level = "a1"
interface.cur_level = nil
interface.score = "000"
interface.depth = "0"

interface.signal_latch = {}

-- State parameter tracking hardware boot transitions
interface.is_initialized = false

function interface.get_module()
	if machine.system.name == "feag" then
		return "Fidelity Elite Avant Garde"
	elseif machine.system.name == "feag2100" then
		return "Fidelity Elite Avant Garde 2100"
	elseif machine.system.name == "feag2100a" then
		return "Fidelity Elite Avant Garde 2100 v2"
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
		if digit_val == lcd_num[d+1] then
			break
		end
		send_input(":IN.0", 0x20 >> n, 0.25)  -- ST / TB / LV
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
	
	-- PANEL ONLY LEVEL SELECTION:
	if interface.cur_level == "reset_forced" then
		send_input(":IN.0", 0x04, 0.5)  -- LV Button
		emu.wait(0.5)
		interface.setdigit(2, cols_idx[level:sub(1,1)])
		interface.setdigit(3, tonumber(level:sub(2,2)) or 1)
	else
		send_input(":IN.0", 0x04, 0.5)  -- LV
		sb_press_square(":board", 0.5, x, y)
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
					sb_press_square(":board", 0.5, x, y)
					k = 1
				elseif (d == "/") then
					sb_press_square(":board", 0.5, x, y)
					k = 2
				elseif (d ~= ":") then
					interface.setdigit(k,d)
					k = k + 1
				end
				num = num:sub(2)
			end
		end
	end
	emu.wait(0.5)
	send_input(":IN.1", 0x01, 0.5) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	-- Cache master framework throttle profiles safely before accelerating
	local original_throttle_state = machine.video.throttled
	
	-- Force the video throttle configuration to False immediately to run all macros unthrottled
	machine.video.throttled = false
	
	-- Clear out local script parameters
	interface.score = "000"
	interface.depth = "0"
	interface.signal_latch = {}
	local root = machine.devices[":"]
	
	-- 1. HARDWARE BRANCHING GATE: COLD BOOT VS RUNTIME RESET
	if not interface.is_initialized then
		interface.is_initialized = true
		emu.wait(2.0) -- Power-up settle padding
		
		send_input(":IN.0", 0x02, 0.4) -- OPTION
		emu.wait(0.3)
		
		-- Check base voice LED (Node 7.15 for H8)
		local boot_voice = root:output("7.15") and root:output("7.15"):get() or 0
		if boot_voice == 0 then
			sb_press_square(":board", 0.4, 8, 8) -- H8
			emu.wait(0.3)
		end
		
		-- Check expanded announcements LED (Node 6.15 for H7)
		local boot_info = root:output("6.15") and root:output("6.15"):get() or 0
		if boot_info == 0 then
			sb_press_square(":board", 0.4, 8, 7) -- H7
			emu.wait(0.3)
		end
		
		send_input(":IN.1", 0x01, 0.4) -- CL
		emu.wait(0.2)
		
		sb_reset_board(":board")
		emu.wait(0.5)
		
		send_input(":IN.1", 0x04, 0.6) -- Press New Game button directly
		emu.wait(1.0)
		
		interface.cur_level = "reset"
		interface.level = "a1"
		interface.setlevel()
	else
		-- RUNTIME UCINEWGAME RESET TIMELINE INTERCEPT
		emu.wait(2.0)
		
		-- AUDIO STEP A: CONDITIONAL TOGGLE VOICE SYNTHESIZER OFF
		send_input(":IN.0", 0x02, 0.4) -- OPTION
		emu.wait(0.3)
		local pre_reset_voice = root:output("7.15") and root:output("7.15"):get() or 0
		if pre_reset_voice ~= 0 then
			sb_press_square(":board", 0.4, 8, 8) -- H8
			emu.wait(0.3)
			send_input(":IN.1", 0x01, 0.4) -- CL
			emu.wait(0.2)
		else
			send_input(":IN.1", 0x01, 0.4) -- CL
			emu.wait(0.2)
		end
		
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
			
			if not is_player_turn then
				send_input(":IN.0", 0x01, 0.5) -- RV
				emu.wait(0.2)
				send_input(":IN.1", 0x01, 0.4) -- CL
				emu.wait(1.5) 
			end
		end
		
		sb_reset_board(":board")
		emu.wait(1.0)
		
		-- CORE HARDWARE NEW GAME RESET PASS
		send_input(":IN.1", 0x04, 0.6)  -- New Game
		emu.wait(1.0)
		
		-- RE-SYNCHRONIZE ACTIVE LEVEL PREFERENCES
		interface.cur_level = "reset_forced"
		interface.setlevel()
		emu.wait(0.5)
	end

	-- 2. GLOBAL SINGLE-PASS OPTION SYNCHRONIZER
	send_input(":IN.0", 0x02, 0.5) -- OPTION
	emu.wait(0.4)
	
	-- Verify Display Stats Rotation (Option E1 -> Node 0.12)
	local check_node = root:output("0.12") 
	local check_val = check_node and check_node:get() or 0
	if check_val == 0 then
		sb_press_square(":board", 0.4, 5, 1)  -- Press E1
		emu.wait(0.3)
	end
	
	-- Verify Base Voice Synthesizer (Option H8 -> Node 7.15)
	local voice_led = root:output("7.15") and root:output("7.15"):get() or 0
	if voice_led == 0 then
		sb_press_square(":board", 0.4, 7, 8) -- Toggle Voice On (G8)
		emu.wait(0.3)
	end
	
	-- Verify Expanded Announcements (Option H7 -> Node 6.15)
	local info_led = root:output("6.15") and root:output("6.15"):get() or 0
	if info_led == 0 then
		sb_press_square(":board", 0.4, 8, 7) -- Press H7 to force descriptions ON
		emu.wait(0.3)
	end
	
	-- Unified keyboard buffer flush
	send_input(":IN.1", 0x01, 0.4) -- CL
	emu.wait(0.3)
	
	-- Restore initial master framework speed profiles completely
	machine.video.throttled = original_throttle_state
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x02, 0.5) -- OPTION
		sb_press_square(":board", 0.5, 4, 7) -- Clear board
		send_input(":IN.1", 0x01, 0.5) -- CL
		send_input(":IN.0", 0x80, 0.5) -- PB
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
						send_input(":IN.0", 0x80 >> (math.abs(p) - 1), 0.5)
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
		
		-- SENSORY BUFFER COOLDOWN CUSHION:
		-- Yields for 0.5 emulated seconds unthrottled. This gives the fast-moving CPU 
		-- plenty of time to scan, register, and lock onto all 64 square updates completely!
		emu.wait(0.5)
		
		-- Force throttling ON to normalize panel keyboard matrix stability
		machine.video.throttled = true
		
		send_input(":IN.1", 0x01, 0.5) -- CL (Exit Board Setup Mode cleanly)
		emu.wait(0.4)
		
		if mode == -1 then
			-- Execute color change safely on a verified, fully scanned board state!
			send_input(":IN.0", 0x02, 0.5) -- OPTION
			emu.wait(0.4)
			sb_press_square(":board", 0.5, 4, 5) -- Change color (D5)
			emu.wait(0.4)
			send_input(":IN.1", 0x01, 0.5) -- CL
			emu.wait(0.5)
		end
	end
	machine.video.throttled = throttled_state
end

-- State parameter tracking whether the core is caught in a fast-forward history sweep
interface.in_edit_loop = false

function interface.edit_game(on)
	local throttled_state = machine.video.throttled
	
	if on then
		-- Entering history replay loop: Lock throttling OFF completely!
		interface.in_edit_loop = true
		machine.video.throttled = false
		
		send_input(":IN.0", 0x02, 0.4) -- OPTION
		emu.wait(0.2)
		sb_press_square(":board", 0.4, 5, 6) -- E6 (Board Setup Mode)
		emu.wait(0.2)
		send_input(":IN.1", 0x01, 0.4) -- CL
		emu.wait(0.3)
	else
		-- Exiting history replay loop: Execute menu closure unthrottled first
		machine.video.throttled = false
		send_input(":IN.0", 0x02, 0.4) -- OPTION
		emu.wait(0.2)
		sb_press_square(":board", 0.4, 5, 6) -- E6 (Exit Board Setup Mode)
		emu.wait(0.2)
		send_input(":IN.1", 0x01, 0.4) -- CL
		emu.wait(0.3)
		
		-- Setup complete: Safely release control back to your master framework throttle state
		interface.in_edit_loop = false
		machine.video.throttled = throttled_state
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 1) -- RV
end

function interface.clear_announcements()
	local root = machine.devices[":"]
	if not root then return end
	
	local all_lit = true
	for i = 8, 15 do
		local node = root:output("0." .. tostring(i))
		if not node or node:get() == 0 then
			all_lit = false
			break
		end
	end
	
	if all_lit then
		send_input(":IN.1", 0x01, 1) -- CL
	end
end

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end
	
	local root = machine.devices[":"]
	if not root then return false end
	
	-- Map the linear coordinate address tags matching your hardware orientation
	local y_idx = y - 1
	local x_idx = 7 + x
	local node_tag = tostring(y_idx) .. "." .. tostring(x_idx)
	local led_node = root:output(node_tag)
	
	-- Read and return the raw, real-time hardware line state natively
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
		if (level:match("^a[1-8]$") or level:match("^b[1-7]$") or level:match("^b[4-6]%s%d%d?$") or level:match("^b2%s%d:%d%d%s%d:%d%d$") or level:match("^b3%s%d:%d%d/%d%d$") or level:match("^b3%s%d:%d%d/%d%d%s%d:%d%d/%d%d$") or level:match("^b3%s%d:%d%d/%d%d%s%d:%d%d/%d%d%s%d:%d%d/%d%d$")) then
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
	
	local q_node = root:output("8.12")
	local r_node = root:output("8.11")
	local b_node = root:output("8.10")
	local n_node = root:output("8.9")
	
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
	if     (piece == "q") then send_input(":IN.0", 0x40, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x20, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x08, 1)
	end
end

function interface.show_info(on)
	if not on then return "" end
	local root = machine.devices[":"]
	if not root then return "" end

	-- Scan the central colons to identify the active running Time Clock panel
	local top_clock_active = (root:output("5.7") and root:output("5.7"):get() or 0) ~= 0
	local bot_clock_active = (root:output("0.7") and root:output("0.7"):get() or 0) ~= 0

	local d1, d2, d3, d4, adv_dot = 0, 0, 0, 0, 0

	if not top_clock_active and bot_clock_active then
		-- Bottom panel has the time colon -> Read Top Panel for stats
		d1 = root:output("digit6") and root:output("digit6"):get() or 0
		d2 = root:output("digit5") and root:output("digit5"):get() or 0
		d3 = root:output("digit7") and root:output("digit7"):get() or 0
		d4 = root:output("digit8") and root:output("digit8"):get() or 0
		adv_dot = root:output("6.7") and root:output("6.7"):get() or 0
	elseif bot_clock_active == false and top_clock_active then
		-- Top panel has the time colon -> Read Bottom Panel for stats
		d1 = root:output("digit1") and root:output("digit1"):get() or 0
		d2 = root:output("digit0") and root:output("digit0"):get() or 0
		d3 = root:output("digit2") and root:output("digit2"):get() or 0
		d4 = root:output("digit3") and root:output("digit3"):get() or 0
		adv_dot = root:output("1.7") and root:output("1.7"):get() or 0
	else
		return "info score cp " .. interface.score .. " depth " .. interface.depth
	end

	-- Convert active digits to ascii values
	local ch1 = digit_ascii(d1):trim()
	local ch2 = digit_ascii(d2):trim()
	local ch3 = digit_ascii(d3):trim()
	local ch4 = digit_ascii(d4):trim()

	-- DISCRETE SPACE LOGIC:
	-- If digit 3 (the third position from the left) is empty/dark, it is definitively a Depth frame!
	if ch3 == "" then
		local raw_hex_char = ch4
		if raw_hex_char:match("^[0-9A-Fb-d]$") and raw_hex_char ~= "" then
			local depth_val = tonumber(raw_hex_char, 16)
			
			-- Handle the Spracklen lowercase segment offsets safely:
			if raw_hex_char == "b" then depth_val = 11
			elseif raw_hex_char == "d" then depth_val = 13
			end
			
			if depth_val and depth_val > 0 then
				interface.depth = tostring(depth_val)
			end
		end
	else
		-- Score Frame Active -> Build decimal score string.
		local squeezed = (ch1 ~= "" and ch1 or "0") .. ch2 .. ch3 .. ch4
		if squeezed:match("^%d+$") then
			local score_num = tonumber(squeezed) or 0
			if adv_dot ~= 0 then
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

