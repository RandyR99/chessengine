interface = {}

interface.invert = false
interface.level = "a2"
interface.cur_level = nil
interface.ignore_late_go = true -- replies on its own once the player's move is on the board
interface.pv = ""
interface.depth = "0"
interface.score = "0.00"

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end


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
		emu.wait(0.2) -- Let the hardware outputs settle from the final piece press
		
		local target_matched = false
		local white_is_green = output_value("3.3") ~= 0
		local black_is_green = output_value("2.3") ~= 0
		
		if mode == 1 and white_is_green then
			target_matched = true
		elseif mode == -1 and black_is_green then
			target_matched = true
		end
		
		-- If the turn LED doesn't match our required FEN turn setting, tap the Pawn button to flip it
		if not target_matched then
			send_input(":KEY.1", 0x01, 0.5) -- Taps Pawn (0x01) to cycle color register
			emu.wait(0.3)
			white_is_green = output_value("3.3") ~= 0
			black_is_green = output_value("2.3") ~= 0
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
	local d1_val = output_value("digit1")
	local d5_val = output_value("digit5")
	
	if (d1_val & 0x80 ~= 0 and d5_val & 0x80 ~= 0) then
		return false
	end
	
	return output_value("led" .. ((y - 1) * 8 + (x - 1))) ~= 0
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
	local d0 = output_value("digit0") & 0x7f
	local d1 = output_value("digit1") & 0x7f
	local d4 = output_value("digit4") & 0x7f
	local d5 = output_value("digit5") & 0x7f
	
	local d2_val, d3_val = 0, 0
	
	-- Scan both potential data slots on Upper and Lower displays for 'Pr'
	if (d0 == 0x73 and d1 == 0x50) then	-- upper display shows 'Pr'
		d2_val = output_value("digit2") & 0x7f
		d3_val = output_value("digit3") & 0x7f
	elseif (d4 == 0x73 and d5 == 0x50) then	-- lower display shows 'Pr'
		d2_val = output_value("digit6") & 0x7f
		d3_val = output_value("digit7") & 0x7f
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

-- the main line, evaluation and depth in RAM, read like on mega4 (same program family, same addresses)
local mega4 = load_interface("mega4")
mega4.digit_table = 0xe953 -- the evaluation's digit table (same RAM layout as mega4)
interface.show_info = mega4.show_info
interface.info_every = 1 -- show_info only reads RAM

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

