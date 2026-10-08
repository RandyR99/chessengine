interface = {}

interface.level = 1
interface.cur_level = nil

function interface.get_module()
	return "Fidelity Eldorado"
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.cur_level = interface.level
	local level = interface.level
	
	local root = machine.devices[":"]
	repeat
		send_input(":IN.0", 0x08, 0.6) -- LEVEL
		emu.wait(0.2)
		local check_node = root:output("1." .. tostring(level - 1))
		local check_val = check_node and check_node:get() or 0
	until check_val ~= 0
	
	send_input(":IN.0", 0x40, 0.6) -- CLEAR
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	send_input(":IN.0", 0x80, 0.6) -- NEW GAME
	emu.wait(0.6)
	send_input(":IN.0", 0x40, 0.6) -- CLEAR
	emu.wait(0.6)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		return (":board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		
		-- TARGET INTERNAL DATA SPACE:
		local ram = machine.devices[':maincpu'].spaces['data']
		send_input(":IN.0", 0x20, 0.6) -- PROBLEM MODE
		emu.wait(0.5)
		
		if ram then
			-- WIPE CONTAMINATION: Clear the 32-byte memory block cleanly first
			for clear_idx = 0, 31 do
				ram:write_u8(0x0020 + clear_idx, 0x00)
			end
			
			-- FIXED GEOMETRIC MAP MATRIX:
			-- Loops sequentially from Rank 1 (0x0020) up to Rank 8 (0x003C)
			local addr_offset = 0
			for y = 1, 8 do
				-- Step through files in pairs (A+B, C+D, E+F, G+H) to construct the 4-bit byte splits
				for x_pair = 1, 8, 2 do
					local p1 = get_piece_id(x_pair, y)
					local p2 = get_piece_id(x_pair + 1, y)
					
					-- Convert standard master framework piece IDs to Ron Nelson's exact microcode tokens
					local function get_nybble(p)
						if p == 0 then return 0x00 end
						local n = math.abs(p)
						-- Master Framework IDs: King=1, Queen=2, Rook=3, Bishop=4, Knight=5, Pawn=6
						-- Eldorado Hardware IDs: Pawn=1, Knight=2, Bishop=3, Rook=4, Queen=5, King=6
						if     n == 1 then n = 6  -- King
						elseif n == 2 then n = 5  -- Queen
						elseif n == 3 then n = 4  -- Rook
						elseif n == 4 then n = 3  -- Bishop
						elseif n == 5 then n = 2  -- Knight
						elseif n == 6 then n = 1  -- Pawn
						end
						-- Handle Black pieces using negative 4-bit two's complement conversion
						if p < 0 then
							n = (16 - n) & 0x0F
						end
						return n
					end
					
					local nybble_left = get_nybble(p1)
					local nybble_right = get_nybble(p2)
					
					-- Pack both nybbles into a single 8-bit RAM cell byte (Left=File A, Right=File B)
					local final_byte = (nybble_left << 4) | nybble_right
					
					ram:write_u8(0x0020 + addr_offset, final_byte)
					addr_offset = addr_offset + 1
				end
			end
			
			-- 2. Aligned side-to-move turn color trackers
			if mode == -1 then
				ram:write_u8(0x0003, 0xff)
			end
		end
		
		send_input(":IN.0", 0x40, 0.6) -- CLEAR
		machine.video.throttled = throttled_state
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 0.6) -- REVERSE (0x01)
end

function interface.stop_play()
	send_input(":IN.0", 0x02, 0.6) -- MOVE (0x02)
end

function interface.is_selected(x, y)
	local root = machine.devices[":"]
	if not root then return false end
	
	-- Eldorado UI Layout uses 0.x and 1.y node tags for matrix coordinate validation
	local x_node = root:output("0." .. tostring(x - 1))
	local y_node = root:output("1." .. tostring(y - 1))
	
	local xval = x_node and x_node:get() or 0
	local yval = y_node and y_node:get() or 0
	
	return xval ~= 0 and yval ~= 0
end

function interface.select_piece(x, y, event)
	if (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 1, x, y, event)
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "8" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 8) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	sb_promote(":board", x, y, "q")
end

return interface

