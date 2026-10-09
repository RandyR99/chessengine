local interface = {}

interface.level = "a1"
interface.cur_level = nil
interface.turn = true
interface.capt = 0
interface.edit = false

-- INITIAL BOOT STATE TRACKER FLAG:
interface.initial_boot = true

local f0 = "00"
local f1 = "--"
local f2 = "--"

function interface.get_module()
	return "Fidelity Chesster Phantom"
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

-- True when the arm is idle and every square holds its start-position piece
-- (sensorboard ids: 1-6 = white P N B R Q K, 7-12 = black P N B R Q K)
local function board_at_start()
	local root = machine.devices[":"]
	local hand = root:output("cpu_hand")
	if hand and hand:get() ~= 0 then
		return false
	end
	local files = "abcdefgh"
	local back_rank = { 4, 2, 3, 5, 6, 3, 2, 4 }
	for y = 1, 8 do
		for x = 1, 8 do
			local expected = 0
			if     (y == 1) then expected = back_rank[x]
			elseif (y == 2) then expected = 1
			elseif (y == 7) then expected = 7
			elseif (y == 8) then expected = back_rank[x] + 6
			end
			local node = root:output("piece_" .. files:sub(x, x) .. tostring(y))
			local val = node and node:get() or 0
			if (val ~= expected) then
				return false
			end
		end
	end
	return true
end

function interface.setup_machine()
	-- Only snap the sensorboard to the start position on first boot. Afterwards the
	-- Phantom rearranges the pieces itself on NEW; resetting the sensorboard first
	-- makes the arm drop pieces onto occupied squares ("Collision at ..!").
	if interface.initial_boot then
		sb_reset_board(":board:board")
	end
	interface.turn = true
	interface.capt = 0
	interface.edit = false
	f0 = "00"
	f1 = "--"
	f2 = "--"
	
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if interface.initial_boot then
		-- Power-on is already a new game. Let the self-test and centering finish first,
		-- as keys pressed during it are ignored.
		emu.wait(40)
		interface.initial_boot = false
		interface.setlevel()
	else
		-- SHIFT + NEW. Chesster Phantom misses a key pressed too soon after SHIFT, and after
		-- NEW it asks for confirmation (Shift light stays on), so answer YES until it goes out.
		local shift_led = machine.devices[":"]:output("0.8")
		send_input(":IN.0", 0x100, 0.5) -- SHIFT
		emu.wait(0.5)
		send_input(":IN.0", 0x004, 0.5) -- NEW / LEVEL
		local tries = 0
		while shift_led:get() ~= 0 and tries < 5 do
			emu.wait(1)
			send_input(":IN.0", 0x020, 0.5) -- YES
			tries = tries + 1
		end
		emu.wait(0.5)
		interface.setlevel()

		-- Run unthrottled until the arm has restored the start position
		local waited = 0
		repeat
			emu.wait(0.5)
			waited = waited + 0.5
		until board_at_start() or waited >= 300
		emu.wait(1.5)
	end
	machine.video.throttled = throttled_state
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
		emu.wait(0.5)
		send_input(":IN.0", 0x001, 1) -- PROBLEM
		send_input(":IN.0", 0x020, 1) -- YES (clear the board)
		
		emu.wait(0.5)
		
		local files = {"a", "b", "c", "d", "e", "f", "g", "h"}
		local waited = 0
		repeat
			emu.wait(0.1)
			waited = waited + 0.1
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
		until (active_pieces_left == 0) or waited >= 300

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
	send_input(":IN.0", 0x002, 0.5) -- OPTION
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
		ram:write_u8(0x087a, ram:read_u8(0x087a) | 0x01) -- Ponder OFF
	end
	send_input(":IN.0", 0x040, 1) -- MOVE
end

function interface.stop_play()
	send_input(":IN.0", 0x040, 1) -- MOVE
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

	-- 'n x' (mate in x moves) needs CLEAR before the move is shown. Only clear it when a
	-- number is on the display, so the checkmate display ('-n', no number) stays up.
	local function digit(n)
		local node = root:output("digit" .. n)
		return (node and node:get() or 0) & 0x7f  -- 0x80 = dot segment
	end
	local numerals = { [0x3f] = true, [0x06] = true, [0x5b] = true, [0x4f] = true, [0x66] = true,
		[0x6d] = true, [0x7d] = true, [0x07] = true, [0x7f] = true, [0x6f] = true, [0x67] = true }

	if (digit(2) == 0x54 and (numerals[digit(3)] or numerals[digit(4)])) then
		send_input(":IN.0", 0x080, 0.5) -- CLEAR
	end
	
	if (ram:read_u8(0x1000) == 0xff) then
		return false
	elseif (f0 ~= "00" and getf(ram:read_u8(0x1001)) == f0) then
		f1 = getf(ram:read_u8(0x1000)) -- Source square
		f2 = getf(ram:read_u8(0x00fb)) -- Destination square
		f0 = "00"
		ram:write_u8(0x087a, ram:read_u8(0x087a) & 0xfe) -- Ponder ON
	end
	if (f0 == "00") then
		local z = tostring(10 * x + y)
		return (z == f1 or z == f2)
	end
	return false
end

-- Sensorboard piece id on any square, including the border spaces (columns 9-12)
local function piece_at(x, y)
	local node = machine.devices[":"]:output("piece_" .. ("abcdefghijkl"):sub(x, x) .. tostring(y))
	return node and node:get() or 0
end

-- Border spaces for a sensorboard piece id (1-6 = white P N B R Q K, 7-12 = black).
-- Columns: white 11 outer / 12 inner, black 10 outer / 9 inner.
-- Rows: 8 = Q (outer) and K (inner), 7 = R, 6 = B, 5 = N, 4-1 = pawns.
local function border_slots(id)
	local white = id <= 6
	local t = white and id or id - 6
	local outer = white and 11 or 10
	local inner = white and 12 or 9
	if t == 6 then return { { inner, 8 } } end
	if t == 5 then return { { outer, 8 } } end
	if t >= 2 then return { { outer, t + 3 }, { inner, t + 3 } } end
	local slots = {}
	for row = 4, 1, -1 do
		slots[#slots + 1] = { outer, row }
		slots[#slots + 1] = { inner, row }
	end
	return slots
end

-- First border space for this piece id that is empty (occupied = false)
-- or that holds this piece (occupied = true)
local function find_slot(id, occupied)
	for _, s in ipairs(border_slots(id)) do
		local v = piece_at(s[1], s[2])
		if (occupied and v == id) or (not occupied and v == 0) then
			return s
		end
	end
	return nil
end

-- Put a piece that left the board (init.lua id: 1-6 = K Q R B N P, negative = black)
-- on its own border space, pressing the space as the manual asks
function removepiece(p)
	local id = 7 - math.abs(p)
	if (p < 0) then
		id = id + 6
	end
	local slot = find_slot(id, false) or border_slots(id)[1]
	send_input(":board:board:SPAWN", 0x01 << (id - 1), 1)
	sb_move_piece(":board:board", slot[1], slot[2])
	sb_press_square(":board:board", 1, slot[1], slot[2])
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
			local waited = 0
			repeat
				emu.wait(0.5)
				waited = waited + 0.5
				local dot_val = dot_node and dot_node:get() or 0
			until dot_val ~= 0x00 or waited >= 30
			f0 = tostring(x) .. tostring(y)
			if ram then
				ram:write_u8(0x087a, ram:read_u8(0x087a) | 0x01) -- Ponder OFF
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
	-- Wait for the arm to drop the pawn on the promotion square before verifying
	local root = machine.devices[":"]
	local hand = root:output("cpu_hand")
	local square = root:output("piece_" .. ("abcdefgh"):sub(x, x) .. tostring(y))
	local waited = 0
	repeat
		emu.wait(0.5)
		waited = waited + 0.5
	until (hand:get() == 0 and square:get() ~= 0) or waited >= 15
	emu.wait(1)

	-- VERIFY + square lights the LED of the piece the machine promoted to
	send_input(":IN.0", 0x001, 1) -- VERIFY
	sb_press_square(":board:board", 1, x, y)
	local p = promotion_led() or "q"

	send_input(":IN.0", 0x080, 1) -- CLEAR
	return p:upper()
end

-- Piece shown by the promotion LEDs (0.3 Q, 0.4 R, 0.5 B, 0.6 N), or nil if none is lit
function promotion_led()
	local root = machine.devices[":"]
	local leds = { { "0.3", "q" }, { "0.4", "r" }, { "0.5", "b" }, { "0.6", "n" } }
	for _, led in ipairs(leds) do
		local node = root:output(led[1])
		if node and node:get() ~= 0 then
			return led[2]
		end
	end
	return nil
end

function interface.get_promotion(x, y)
	-- The promotion LEDs only light in VERIFY mode, so let init.lua call
	-- test_promotion() once the move is complete
	return nil
end

function interface.promote(x, y, piece)
	-- Uppercase = the machine's own promotion: the arm has already swapped the pawn
	-- for the new piece from storage, so there is nothing left to do here
	if piece == piece:upper() then
		return
	end

	-- Lowercase = promotion in the opponent's move: make the swap on the sensorboard

	local root = machine.devices[":"]
	if not root then return end

	-- Arm the isolation thread shield
	interface.promotion_active = true
	local original_throttle = machine.video.throttled
	machine.video.throttled = true

	-- Steps D-F of the manual's pawn promotion (A-C were done by select_piece)
	local ids = { n = 2, b = 3, r = 4, q = 5 }
	local id = ids[piece] or 5
	if (y == 1) then
		id = id + 6  -- black promotes on rank 1
	end
	local src = find_slot(id, true)

	if src then
		-- D: pick up the replacement piece from its border space
		sb_select_piece(":board:board", 1, src[1], src[2], "get")
		emu.wait(0.5)
		-- E: put it on the promotion square (replacing the pawn on the sensorboard)
		sb_select_piece(":board:board", 1, x, y, "put")
		emu.wait(0.5)
		-- F: the pawn goes to its own border space
		removepiece((y == 1) and -6 or 6)
	else
		-- No replacement available: press its empty border space and leave the pawn on the
		-- square. The Phantom remembers it as promoted (a "crowned" pawn in the manual) and
		-- returns it to a pawn space on NEW, so the sensorboard must keep showing a pawn.
		local slot = border_slots(id)[1]
		sb_press_square(":board:board", 1, slot[1], slot[2])
	end
	emu.wait(0.5)

	machine.video.throttled = original_throttle
	interface.promotion_active = false
end

return interface

