interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 6
interface.cur_level = nil
interface.turn = true
interface.capt = 0
interface.edit = false
local color = 1
local captprom = 0
local getprom = false
local throttled = true

function getdigit(n)
	local map = {{"s0.0","s0.21","s1.21","s1.22","s0.22","s1.0","s0.23"},
		     {"s0.4","s0.19","s1.19","s1.20","s0.20","s1.3","s0.3"},
		     {"s0.5","s0.16","s1.16","s1.17","s0.17","s1.5","s0.18"},
		     {"s0.9","s0.14","s1.14","s1.15","s0.15","s1.8","s0.8"},
		     {"s0.11","s0.12","s1.12","s1.13","s0.13","s1.10","s0.10"}}
	local dig = 0x00
	for i=1,7 do
		if (output_value(map[n][i]) ~= 0) then
			dig = dig | (1 << (i-1))
		end
	end
	return dig
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local cl = interface.cur_level % 100
	local nl = interface.level % 100
	throttled = machine.video.throttled
	machine.video.throttled = false
	emu.wait(0.5)
	interface.cur_level = interface.level
	send_input(":IN.0", 0x10, 1) -- Level
	local val = {0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f}
	local key
	local dig

	if (nl > cl and nl <= cl+50) or (nl < cl and nl <= cl-50) then
		key = 0x10
	else
		key = 0x20
	end
	local d5 = nl % 10
	local d4 = (nl - d5) / 10
	if nl == 0 then
		dig = 0x3f
	elseif nl < 10 then
		dig = 0x00
	else
		dig = val[d4 + 1]
	end
	emu.wait(0.5)
	ioport.ports[":IN.1"]:field(key):set_value(1) -- Right/Left on
	repeat
		emu.wait(0.25)
	until getdigit(4) == dig
	ioport.ports[":IN.1"]:field(key):set_value(0) -- Right/Left off

	dig = getdigit(5)
	for i=0,9 do
		if dig == val[i+1] then
			cl = i
			break
		end
	end
	local dl = d5 - cl
	if dl > 0 then
		key = 0x10
	else
		key = 0x20
	end
	emu.wait(0.5)
	for i=1,math.abs(dl) do
		send_input(":IN.1", key, 1) -- Right/Left
		emu.wait(0.5)
	end

	emu.wait(0.5)
	send_input(":IN.0", 0x08, 1) -- Clear
	machine.video.throttled = throttled
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	interface.turn = true
	interface.capt = 0
	interface.edit = false
	color = 1
	captprom = 0
	getprom = false
--	send_input(":IN.0", 0x80, 0.5) -- New Game
	repeat
		emu.wait(0.25)
	until getdigit(1) == 0x39

	interface.cur_level = 6
	interface.setlevel()
end

function interface.set_pos(mode)
	local border = {{ 1, 3, 4, 5, 6, 6, 6, 6 },
			{ 2, 3, 4, 5, 6, 6, 6, 6 },
			{-2,-3,-4,-5,-6,-6,-6,-6 },
			{-1,-3,-4,-5,-6,-6,-6,-6 }}

	local function setpiece(p,x,y)
		local x1,x2,z
		if p>0 then
			x1=9
			x2=10
			z=1
		else
			x1=12
			x2=11
			z=-1
		end
		for i=x1,x2,z do
			for j=1,8 do
				if border[i-8][j]==p then
					border[i-8][j]=0
					sb_select_piece(":board:board", 1, i, j, "get")
					sb_select_piece(":board:board", 1, x, y, "put")
					return
				end
			end
		end
	end

	if mode == 0 then
		send_input(":IN.0", 0x40, 1) -- Set Up
		send_input(":IN.1", 0x01, 1) -- Option
		send_input(":IN.1", 0x01, 1) -- Option
		sb_clear_board(":board:board")
		local p
		local z
		for x=9,12 do
			for y=1,8 do
				p=border[x-8][y]
				if p>0 then
					z=6-p
				else
					z=12+p
				end
				send_input(":board:board:SPAWN", 0x01<<z, 0.09)
				sb_move_piece(":board:board", x, y)
			end
		end
		return ("")
	else
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					setpiece(p,x,9-y)
				end
			end
		end

		if mode<0 then
			send_input(":IN.1", 0x20, 1) -- Black/White
			color = 0
		else
			color = 1
		end
		send_input(":IN.0", 0x08, 1) -- Clear
	end
end

function interface.edit_game(on)
	send_input(":IN.1", 0x10, 1) -- Multi Move
	interface.edit = on
	if not on then
		emu.wait(2) -- let it leave Multi Move before MOVE is pressed
	end
end

function interface.start_play()
	interface.turn = false
	send_input(":IN.0", 0x04, 1) -- Move
end

function interface.stop_play()
	send_input(":IN.0", 0x04, 1) -- Move
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d1 = getdigit(1)
	local d2 = getdigit(2)
	local d4 = getdigit(4)
	local d5 = getdigit(5)
	return (xval[x] == d1 and yval[y] == d2) or (xval[x] == d4 and yval[y] == d5)
end

-- Captured pieces have a fixed place in the border area (manual: "place it on
-- its symbol"), filled in the order the Mirage uses itself: outer column first
-- (white j = 10, black k = 11), then inner (white i = 9, black l = 12).
-- Rows: 1 = K/Q, 2 = R, 3 = B, 4 = N, 8-5 = pawns.
local function box_slots(p)
	local outer = (p > 0) and 10 or 11
	local inner = (p > 0) and 9 or 12
	local t = math.abs(p)
	if t == 1 then return { { inner, 1 } } end
	if t == 2 then return { { outer, 1 } } end
	if t <= 5 then return { { outer, t - 1 }, { inner, t - 1 } } end
	local slots = {}
	for y = 8, 5, -1 do
		slots[#slots + 1] = { outer, y }
		slots[#slots + 1] = { inner, y }
	end
	return slots
end

local function box_slot(p)
	-- first free place for piece p, read from the sensorboard state
	local root = machine.devices[":"]
	local function empty(x, y)
		local out = root:output("piece_" .. ("abcdefghijkl"):sub(x, x) .. tostring(y))
		return out == nil or out:get() == 0
	end
	for _, s in ipairs(box_slots(p)) do
		if empty(s[1], s[2]) then
			return s[1], s[2]
		end
	end
	local s = box_slots(p)[1]
	return s[1], s[2]
end

function removepiece(p)
	if (p == 0) then
		return
	end
	local x, y = box_slot(p)
	if (p > 0) then
		send_input(":board:board:SPAWN", 0x01<<(6-p), 1)
	else
		send_input(":board:board:SPAWN", 0x01<<(12+p), 1)
	end
	sb_move_piece(":board:board", x, y)
	sb_press_square(":board:board", 1, x, y)
	if interface.edit then
		-- wait until Multi Move shows PLAY again before the next move
		local waited = 0
		repeat
			emu.wait(0.25)
			waited = waited + 0.25
		until (getdigit(2) == 0x73 and getdigit(3) == 0x38) or waited >= 15
	end
end

function interface.select_piece(x, y, event)
	if (interface.turn and not interface.edit and (event == "get_castling" or event == "put_castling" or event == "en_passant")) then
		return
	end
	if (interface.turn or interface.edit or event == "get_castling" or event == "put_castling" or event == "en_passant") then
		if event == "get" and not interface.edit then
			repeat
				emu.wait(0.25)
			until output_value("s"..tostring(color)..".1") == 0
		end
		if event == "get" then
			interface.from = { x, y }
		end
		sb_select_piece(":board:board", 0.5, x, y, event)
		captprom = 0
		if (interface.capt ~= 0) then -- capture!
			local f = interface.from
			local pawn = f and math.abs(get_piece_id(f[1], f[2])) == 6
			if pawn and (y == 8 or y == 1) then
				-- capture with promotion: the Mirage asks for the promotion piece
				-- first and only then for the captured piece (see promote)
				captprom = interface.capt
			else
				removepiece(interface.capt)
			end
			interface.capt = 0
		elseif (event == "capture") then
			interface.capt = get_piece_id(x, y)
		elseif (event == "en_passant") then
			removepiece(get_piece_id(x, y))
		end
	end
	if (event == "put") then
		interface.turn = not interface.turn
		color = 1 - color
	end
end

function interface.get_options()
	return { { "spin", "Level", "6", "1", "100"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 100) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	getprom = true
	local p = "q"
	if     output_value("s1.9") ~= 0 then p = "q"
	elseif output_value("s1.7") ~= 0 then p = "r"
	elseif output_value("s1.6") ~= 0 then p = "b"
	elseif output_value("s1.4") ~= 0 then p = "n"
	end
	repeat
		emu.wait(0.25)
	until output_value("s"..tostring(color)..".1") == 1
	return p
end

function interface.promote(x, y, piece)
	if getprom then
		sb_promote(":board:board", x, y, piece)
		getprom = false
		return
	end
	if     (piece == "q") then send_input(":IN.0", 0x20, 0.5)
	elseif (piece == "r") then send_input(":IN.0", 0x10, 0.5)
	elseif (piece == "b") then send_input(":IN.0", 0x01, 0.5)
	elseif (piece == "n") then send_input(":IN.0", 0x02, 0.5)
	end
	if captprom ~= 0 then
		removepiece(captprom)
		captprom = 0
	end
	sb_promote(":board:board", x, y, piece)
end

return interface
