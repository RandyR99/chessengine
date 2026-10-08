interface = {}

interface.invert = false
interface.level = "a2"
interface.cur_level = nil
interface.pv = ""
interface.depth = "0"
interface.score = "0.00"

function interface.get_module()
	if machine.system.name == "montec4" then
		return "Mephisto Monte Carlo IV"
	elseif machine.system.name == "montec4le" then
		return "Mephisto Monte Carlo IV LE"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ed Schröder"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	if (x > 6) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local y = interface.level:sub(2, 2)
	send_input(":KEY.0", 0x20, 1) -- LEV
	emu.wait(0.5)
	sb_press_square(":board:board", 1, x, y)
	emu.wait(0.5)
	send_input(":KEY.0", 0x10, 1) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board:board")
	emu.wait(2)
	machine.video.throttled = throttled_state
	interface.cur_level = "a2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY.0", 0x02, 0.5) -- POS
		send_input(":KEY.0", 0x40, 0.5) -- ENT
		machine.video.throttled = throttled_state
		return (":board:board")
	else
		-- The Monte Carlo IV enters POS mode defaulting to a White Pawn brush
		local brush_type = 6   -- 1=K, 2=Q, 3=R, 4=B, 5=N, 6=P
		local brush_color = 1  -- 1=White, -1=Black
		
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					local target_type = math.abs(p)
					local target_color = (p > 0) and 1 or -1
					
					-- Key mask layout map: Pawn=0x01, Knight=0x02, Bishop=0x04, Rook=0x08, Queen=0x10, King=0x20
					local key_mask = 0x01 << (6 - target_type)
					
					if brush_type ~= target_type then
						-- Switch brush type. The computer maintains the PREVIOUS brush color!
						send_input(":KEY.1", key_mask, 0.5)
						brush_type = target_type
						
						-- Check if the retained brush color matches our target color
						if brush_color ~= target_color then
							send_input(":KEY.1", key_mask, 0.5) -- Double tap to toggle color state
							brush_color = target_color
						end
					else
						-- We are already on the correct piece type, check if we need a color change
						if brush_color ~= target_color then
							send_input(":KEY.1", key_mask, 0.5) -- Tap to switch color state
							brush_color = target_color
						end
					end
					
					-- Commit the verified piece onto the sensor board square grid
					sb_press_square(":board:board", 0.5, x, 9 - y)
				end
			end
		end
		
		-- 3. VERIFY ACTIVE SIDE TO MOVE USING REALS OVER HARDWARE INDICATOR LEDS (3.3 vs 2.3)
		local root = machine.devices[":"]
		emu.wait(0.2) -- Let the hardware outputs settle from the final piece press
		
		local target_matched = false
		local white_led = root:output("3.3")
		local black_led = root:output("2.3")
		local white_is_green = white_led and white_led:get() ~= 0 or false
		local black_is_green = black_led and black_led:get() ~= 0 or false
		
		if mode == 1 and white_is_green then
			target_matched = true
		elseif mode == -1 and black_is_green then
			target_matched = true
		end
		
		-- If the turn LED doesn't match our required FEN turn setting, tap the Pawn button to flip it
		if not target_matched then
			send_input(":KEY.1", 0x01, 0.5) -- Taps Pawn (0x01) to cycle color register
			emu.wait(0.3)
			
			white_is_green = white_led and white_led:get() ~= 0 or false
			black_is_green = black_led and black_led:get() ~= 0 or false
			
			local check_match = false
			if mode == 1 and white_is_green then check_match = true
			elseif mode == -1 and black_is_green then check_match = true
			end
			
			-- Tap a second time if the first cycle command didn't register a clean flip
			if not check_match then
				send_input(":KEY.1", 0x01, 0.5)
				emu.wait(0.3)
			end
		end
		
		send_input(":KEY.0", 0x10, 0.5) -- CL (Saves the board parameters and exits menu safely)
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY.0", 0x04, 0.5) -- MEM
	else
		send_input(":KEY.0", 0x10, 0.5) -- CL
	end
	emu.wait(0.5)
end

-- TARGET TRICK ADDITION: Automatically forces calculation state manually on go
function interface.start_play(init)
	if (init and interface.invert == true) then
		sb_rotate_board(":board:board")
	else
		interface.invert = false
	end
	send_input(":KEY.0", 0x40, 1) -- ENT
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
	
	local led_node = root:output("led" .. tostring((y - 1) * 8 + (x - 1)))
	return led_node and led_node:get() ~= 0
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_select_piece(":board:board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "a2" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		interface.level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		interface.level = value
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
	
	local d2_val, d3_val = 0, 0
	
	-- Scan both potential data slots on Upper and Lower displays for 'Pr'
	if (d0 == 0x73 and d1 == 0x50) then	-- upper display shows 'Pr'
		local p2 = root:output("digit2")
		local p3 = root:output("digit3")
		d2_val = p2 and (p2:get() & 0x7f) or 0
		d3_val = p3 and (p3:get() & 0x7f) or 0
	elseif (d4 == 0x73 and d5 == 0x50) then	-- lower display shows 'Pr'
		local p6 = root:output("digit6")
		local p7 = root:output("digit7")
		d2_val = p6 and (p6:get() & 0x7f) or 0
		d3_val = p7 and (p7:get() & 0x7f) or 0
	end
	
	-- We look for the active character drawn on the secondary digit positions
	local target_digit = (d3_val ~= 0) and d3_val or d2_val
	
	-- EXACT MANUAL SEGMENT MATCHING LAYOUT (BASE-10 DECIMAL)
	if     (target_digit == 94)  then return "q" -- Queen: segments bcdeg
	elseif (target_digit == 120) then return "r" -- Rook: segments defg (lowercase 't' shape)
	elseif (target_digit == 56)  then return "b" -- Bishop: segments def but not g
	elseif (target_digit == 109) then return "n" -- Knight: segments acdfg
	end
	
	return 'q' -- Safety fallback
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board:board", x, y, piece)
	if	   (piece == "q") then send_input(":KEY.1", 0x10, 1)
	elseif (piece == "r") then send_input(":KEY.1", 0x08, 1)
	elseif (piece == "b") then send_input(":KEY.1", 0x04, 1)
	elseif (piece == "n") then send_input(":KEY.1", 0x02, 1)
	end
end

function interface.show_info(on)
	if on then
		local root = machine.devices[":"]

		-- DUAL-GATED ESCAPE SCANNER: Abort instantly if any chessboard LED is lit to protect moves
		for idx = 0, 63 do
			local led_check = root:output("led" .. tostring(idx))
			if led_check and led_check:get() ~= 0 then
				return nil
			end
		end

		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":KEY.0", 0x08, 0.2) -- INFO
		emu.wait(0.1)
		
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
		local d6 = p5 and (p5:get() & 0x7f) or 0
		local d7 = p6 and (p6:get() & 0x7f) or 0
		local d8 = p7 and (p7:get() & 0x7f) or 0
		
		interface.pv = digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4)
		send_input(":KEY.1", 0x01, 0.2) -- 1
		emu.wait(0.1)
		
		d1 = p2 and (p2:get() & 0x7f) or 0
		d2 = p3 and (p3:get() & 0x7f) or 0
		d3 = p4 and (p4:get() & 0x7f) or 0
		d4 = p5 and (p5:get() & 0x7f) or 0
		d5 = p6 and (p6:get() & 0x7f) or 0
		d6 = p7 and (p7:get() & 0x7f) or 0
		
		interface.depth = digit_ascii(d1) .. digit_ascii(d2):gsub(" ","")
		interface.score = digit_ascii(d3) .. digit_ascii(d4) .. digit_ascii(d5) .. digit_ascii(d6):gsub(" ","")
		
		for idx = 0, 63 do
			local led_check = root:output("led" .. tostring(idx))
			if led_check and led_check:get() ~= 0 then
				machine.video.throttled = throttled_state
				return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
			end
		end

		send_input(":KEY.0", 0x10, 0.2) -- CL
		emu.wait(0.05)

		machine.video.throttled = throttled_state
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

