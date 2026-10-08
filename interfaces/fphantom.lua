local interface = {}

interface.level = "a1"
interface.cur_level = nil
interface.turn = true
interface.capt = 0
interface.edit = false
local getprom = false

-- INITIAL BOOT STATE TRACKER FLAG:
interface.initial_boot = true

local f0 = "00"
local f1 = "--"
local f2 = "--"

function interface.get_module()
	return "Fidelity Phantom"
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function getf(code)
	if (code == 0xff) then
		return "--"
	end
	local x = code % 16
	local y = (code - x) / 16
	return tostring(x+1) .. tostring(y+1):sub(1,1)
end

function interface.setlevel()
	interface.cur_level = interface.level
	
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	
	send_input(":IN.0", 0x004, 0.5) -- LEVEL
	sb_press_square(":board:board", 0.5, x, y)
	send_input(":IN.0", 0x080, 0.5) -- CLEAR
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	interface.turn = true
	interface.capt = 0
	interface.edit = false
	getprom = false
	f0 = "00"
	f1 = "--"
	f2 = "--"
	
	send_input(":IN.0", 0x100, 0.5) -- SHIFT
	send_input(":IN.0", 0x004, 0.5) -- NEW / LEVEL
	emu.wait(0.5)

	interface.setlevel()
	
	if interface.initial_boot then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		emu.wait(40)
		machine.video.throttled = throttled_state
		interface.initial_boot = false
	else
		emu.wait(1.5)
	end
end

-- FIXED: Realigned columns strictly to your MAME XML inputmask designations
function selectpiece(p, n)
	local q = math.abs(p)
	local x = 11      -- White major piece default column (Rook, Bishop, Knight)
	local y = 8
	local z = 1
	if p < 0 then
		x = 10    -- Black major piece default column (Rook, Bishop, Knight)
		z = -1
	end
	if q==1 then
		x=x+z
	elseif q==6 then
		if n<5 then
			y=n
		else
			x=x+z
			y=n-4
		end
	elseif q>2 then
		if n==2 then
			x=x+z
		end
		y=10-q
	end
	
	sb_select_piece(":board:board", 1, x, y, "get")
end

function interface.set_pos(mode)
	local root = machine.devices[":"]
	if not root then return end

	if mode == 0 then
		send_input(":IN.0", 0x100, 1) -- SHIFT
		send_input(":IN.0", 0x001, 1) -- PROBLEM
		send_input(":IN.0", 0x020, 1) -- ALTERNATE
		
		emu.wait(0.5)
		
		local files = {"a", "b", "c", "d", "e", "f", "g", "h"}
		repeat
			emu.wait(0.1)
			local active_pieces_left = 0
			
			for y = 1, 8 do
				for x = 1, 8 do
					local node_name = "piece_" .. files[x] .. tostring(y)
					local piece_node = root:output(node_name)
					local piece_val = piece_node and piece_node:get() or 0
					
					if piece_val ~= 0 then
						active_pieces_left = active_pieces_left + 1
					end
				end
			end
		until (active_pieces_left == 0)
		
		emu.wait(0.5)
		return ("")
	else
		local m = {0,0,0,0,0,0,0,0,0,0,0,0,0}
		local x0 = 0
		local y0 = 0
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					local n=m[p+7]+1
					m[p+7]=n
					selectpiece(p,n)
					sb_select_piece(":board:board", 1, x, 9-y, "put")
					if p==mode then
						x0 = x
						y0 = 9 - y
					end
				end
			end
		end
		sb_press_square(":board:board", 1, x0, y0)
		send_input(":IN.0", 0x080, 1) -- CLEAR
	end
end

function interface.edit_game(on)
	local cpu = machine.devices[":maincpu"]
	local ram = cpu and cpu.spaces["program"]
	
	local throttled_state = machine.video.throttled
	if not on then
		machine.video.throttled = false
		emu.wait(10)
	end
	send_input(":IN.0", 0x02, 0.5) -- OPTION
	sb_press_square(":board:board", 0.5, 3, 1)
	sb_press_square(":board:board", 0.5, 3, 1)
	send_input(":IN.0", 0x080, 0.5) -- CLEAR
	if not on then
		machine.video.throttled = throttled_state
	end
	interface.edit = on
	emu.wait(0.5)
	if ram then
		f1 = getf(ram:read_u8(0x1000))
	end
end

function interface.start_play(init)
	local cpu = machine.devices[":maincpu"]
	local ram = cpu and cpu.spaces["program"]

	interface.turn = false
	f0 = f1
	if ram then
		ram:write_u8(0x000f, ram:read_u8(0x000f) | 0x01) -- Ponder OFF
	end
	send_input(":IN.0", 0x20, 1) -- MOVE
end

function interface.stop_play()
	send_input(":IN.0", 0x20, 1) -- MOVE
end

function interface.is_selected(x, y)
	-- ISOLATION GUARD: Instantly dump background loops when a promotion macro executes
	if interface.promotion_active then
		return false
	end

	local cpu = machine.devices[":maincpu"]
	local ram = cpu and cpu.spaces["program"]
	if not ram then return false end

	local root = machine.devices[":"]
	if not root then return false end

	local d2_node = root:output("digit2")
	local d2_val = d2_node and d2_node:get() or 0

	if (d2_val == 0x54) then
		send_input(":IN.0", 0x080, 0.5) -- CLEAR
	end
	
	if (ram:read_u8(0x1000) == 0xff) then
		return false
	elseif (f0 ~= "00" and getf(ram:read_u8(0x1001)) == f0) then
		f1 = getf(ram:read_u8(0x1000)) -- Source square
		f2 = getf(ram:read_u8(0x00fb)) -- Destination square
		f0 = "00"
		ram:write_u8(0x000f, ram:read_u8(0x000f) & 0xfe) -- Ponder ON
	end
	if (f0 == "00") then
		local z = tostring(10 * x + y)
		return (z == f1 or z == f2)
	end
	return false
end

function removepiece(p)
	local z = 11  -- White outer strip column index (Col X1 / x=-20)
	if (p > 0) then
		send_input(":board:SPAWN", 0x01<<(6-p), 1)
	elseif (p < 0) then
		send_input(":board:SPAWN", 0x01<<(12+p), 1)
		z = 10    -- Black outer strip column index (Col X4 / x=90)
	end
	sb_move_piece(":board:board", z, 1)
	sb_press_square(":board:board", 1, z, 1)
end

function interface.select_piece(x, y, event)
	-- ISOLATION GUARD: Bypasses sensorboard callbacks during an automated promotion pass
	if interface.promotion_active then
		return
	end

	local root = machine.devices[":"]
	if not root then return end

	local d2_node = root:output("digit2")
	local dot_node = root:output("4.7")
	
	local cpu = machine.devices[":maincpu"]
	local ram = cpu and cpu.spaces["program"]

	if (interface.turn and not interface.edit and (event == "get_castling" or event == "put_castling" or event == "en_passant")) then
		return
	end
	emu.wait(1)
	
	local d2_val = d2_node and d2_node:get() or 0
	if (d2_val == 0x40) then -- castling & enpassant
		sb_select_piece(":board:board", 1, x, y, event)
		if     (y == 4) then removepiece(6)
		elseif (y == 5) then removepiece(-6)
		end
		return
	end
	if (interface.turn or interface.edit or event == "get_castling" or event == "put_castling" or event == "en_passant") then
		if (event == "get") then
			repeat
				emu.wait(0.5)
				local dot_val = dot_node and dot_node:get() or 0
			until dot_val ~= 0x00
			f0 = tostring(x) .. tostring(y)
			if ram then
				ram:write_u8(0x000f, ram:read_u8(0x000f) | 0x01) -- Ponder OFF
			end
		end
		sb_select_piece(":board:board", 1, x, y, event)
		if (interface.capt ~= 0) then -- capture
			removepiece(interface.capt)
			interface.capt = 0
		elseif (event == "capture") then
			interface.capt = get_piece_id(x, y)
		end
	end
	if (event == "put") then
		interface.turn = not interface.turn
	end
end

function interface.get_options()
	return { { "string", "Level", "a1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower()
		if (level:match("^[a-h][1-8]$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.test_promotion(x, y)
	local p
	emu.wait(10)
	send_input(":IN.0", 0x001, 1) -- VERIFY
	sb_press_square(":board:board", 1, x, y)

	local root = machine.devices[":"]
	if root then
		local q_node = root:output("0.3")
		local n_node = root:output("0.6")
		local b_node = root:output("0.5")
		local r_node = root:output("0.4")

		if     (q_node and q_node:get() ~= 0) then p = "Q"
		elseif (n_node and n_node:get() ~= 0) then p = "N"
		elseif (b_node and b_node:get() ~= 0) then p = "B"
		elseif (r_node and r_node:get() ~= 0) then p = "R"
		else p = "Q"
		end
	else
		p = "Q"
	end

	send_input(":IN.0", 0x080, 1) -- CLEAR
	return p
end

function interface.get_promotion(x, y)
	return "r"
end

function interface.promote(x, y, piece)
	if getprom then
		sb_promote(":board:board", x, y, piece)
		getprom = false
		return
	end
	
	local root = machine.devices[":"]
	if not root then return end

	-- Arm the isolation thread shield
	interface.promotion_active = true
	local original_throttle = machine.video.throttled
	machine.video.throttled = true

	local p_char = piece:lower()
	local z = 12  -- White major pieces column registry index (Col X2)
	local p = 7   
	
	if     (p_char == "n") then p = 5
	elseif (p_char == "b") then p = 6
	elseif (p_char == "r") then p = 7
	end
	
	if (y == 1) then
		z = 9     -- Black major pieces column registry index (Col X3)
	end
	
	local q_node = root:output("0.3")
	repeat
		emu.wait(0.5)
		local q_active = q_node and q_node:get() or 0
	until q_active ~= 0
	
	-- STEP 1: Lift the replacement Rook from the side panel storage slot
	sb_select_piece(":board:board", 1, z, p, "get")
	emu.wait(0.5)
	
	-- STEP 2: Place that piece onto the active promotion destination square (B8)
	sb_select_piece(":board:board", 1, x, y, "put")
	emu.wait(0.5)
	
	-- STEP 3: Spawn the original pawn and place it cleanly inside the outer strip row 1
	if (y == 1) then
		removepiece(-6) -- Black Pawn (Targets Col X1 / Row 1)
	else
		removepiece(6)  -- White Pawn (Targets Col X4 / Row 1)
	end
	emu.wait(0.5)
	
	machine.video.throttled = original_throttle
	interface.promotion_active = false
end

return interface

