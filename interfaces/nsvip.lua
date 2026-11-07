interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local prog = machine.system.name
interface.turn = true
interface.level = 1
interface.cur_level = nil
local mem = machine.devices[':maincpu'].spaces['program']
local ram_base = 0x2000 -- battery-backed RAM
local adr1 = 0x2a8
local adr2 = 0x367
if prog == "nsvipb" then
	adr1 = 0x2b4
	adr2 = 0x376
elseif prog == "nsvipc" then
	adr1 = 0x2a3
	adr2 = 0x36c
end
local count = 0
local maxcount = adr2-adr1-2
interface.edit = false

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local z0 = interface.cur_level
	local y0 = (z0 - 1) % 8 + 1
	local x0 = (z0 - y0) / 8
	local z1 = interface.level
	local y1 = (z1 - 1) % 8 + 1
	local x1 = (z1 - y1) / 8
	interface.cur_level = interface.level
	send_input(":IN.1", 0x04, 0.6) -- Set Level
	emu.wait(1)
	for i=1,(x1 - x0 + 6) % 6 do
		send_input(":IN.1", 0x04, 0.6) -- Set Level
	end
	if y1 ~= y0 then
		send_input(":IN.2", 0x01<<(y1-1), 0.6)
	end
	send_input(":IN.0", 0x01, 0.6) -- Go
end

function interface.setup_machine()
	interface.turn = true
	interface.edit = false
--	sb_reset_board(":board")
--	send_input(":IN.0", 0x80, 0.6) -- New Game
	count = 0
	emu.wait(1)

	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x40, 0.6) -- Sound
		send_input(":IN.0", 0x20, 0.6) -- Verify/Setup
		send_input(":IN.0", 0x20, 0.6) -- Verify/Setup
		send_input(":IN.0", 0x08, 0.6) -- Clear Board
		return ("")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.0", 0x10, 0.6) -- Color
					end
					if math.abs(p)~=math.abs(piece) then
						send_input(":IN.1", 0x80>>(math.abs(p)-1), 0.6)
					end
					send_input(":IN.2", 0x01<<(x-1), 0.6)
					send_input(":IN.2", 0x01<<(8-y), 0.6)
					piece=p
				end
			end
		end
		send_input(":IN.0", 0x01, 0.6) -- Go
		if mode<0 then
			send_input(":IN.0", 0x10, 0.6) -- Color
		end
		send_input(":IN.1", 0x40, 0.6) -- Sound
		send_input(":IN.0", 0x08, 0.6) -- Clear
	end
end

function interface.edit_game(on)
	send_input(":IN.1", 0x80, 0.6) -- Referee
	interface.edit = on
	emu.wait(0.6)
end

function interface.start_play(init)
	interface.turn = false
	send_input(":IN.0", 0x01, 0.6) -- Go
end

function interface.is_selected(x, y)
	if interface.edit then
		return false
	end
	local von = mem:read_u8(ram_base+adr1+count)
	local bis = mem:read_u8(ram_base+adr2+count)
	local d1 = (von&0x07) + 1
	local d2 = 8 - ((von&0x70)>>4)
	local d3 = (bis&0x07) + 1
	local d4 = 8 - ((bis&0x70)>>4)
	return (x == d1 and y == d2) or (x == d3 and y == d4)
end

-- true if the machine's move list holds the move at the current index
local function move_stored(m)
	local von = mem:read_u8(ram_base+adr1+m.idx)
	local bis = mem:read_u8(ram_base+adr2+m.idx)
	return (von&0x07)+1 == m.fx and 8-((von&0x70)>>4) == m.fy and (bis&0x07)+1 == m.tx and 8-((bis&0x70)>>4) == m.ty
end

local function key_square(x, y)
	send_input(":IN.2", 0x01<<(x-1), 0.6)
	send_input(":IN.2", 0x01<<(y-1), 0.6)
end

-- the machine sometimes misses a key: check the move list and enter the move again
local function verify_move(m, piece)
	if m.idx >= maxcount then return end
	for try = 1, 3 do
		local t = machine.time:as_double() + 1.5
		repeat
			if move_stored(m) then return end
			emu.wait(0.1)
		until machine.time:as_double() > t
		send_input(":IN.0", 0x08, 0.6) -- Clear
		key_square(m.fx, m.fy)
		key_square(m.tx, m.ty)
		if piece then interface.promote_key(piece) end
	end
end

local pending = nil
local from = nil

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if interface.turn then
			key_square(x, y)
			if event == "get" then
				from = { x = x, y = y }
			elseif event == "put" and from then
				local m = { fx = from.x, fy = from.y, tx = x, ty = y, idx = count }
				from = nil
				if math.abs(get_piece_id(m.fx, m.fy)) == 6 and (y == 8 or y == 1) then
					pending = m -- a promotion is stored after the piece key: check in promote()
				else
					verify_move(m)
				end
			end
		end
		if event == "put" then
			if not interface.edit then
				interface.turn = not interface.turn
			end
			if count < maxcount then
				count = count + 1
			end
		end
	end
end

function interface.get_options()
	return { { "string", "Level", "TR 1"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = value:upper():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		local n = tonumber(level)
		if (n ~= nil and n >= 1 and n <= 48) then
			level = n
		else
			local tmp = level:sub(1,2)
			if     (tmp == "TR") then tmp = 0
			elseif (tmp == "FT") then tmp = 1
			elseif (tmp == "SD") then tmp = 2
			elseif (tmp == "FD") then tmp = 3
			elseif (tmp == "AN") then tmp = 4
			elseif (tmp == "EA") then tmp = 5
			else
				return
			end
			n = tonumber(level:sub(3))
			if (n == nil or n < 1 or n > 8) then
				return
			end
			level = tmp * 8 + n
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	-- the LCD still shows the move (its first digit is the FROM file), so read the
	-- promoted piece from the 0x88 board in RAM (rank 8 first, piece type in the low nibble)
	local t = machine.time:as_double() + 2
	repeat
		local p = mem:read_u8(ram_base + (8 - y) * 16 + (x - 1)) & 0x0f
		if     (p == 4) then return 'q'
		elseif (p == 3) then return 'r'
		elseif (p == 2) then return 'b'
		elseif (p == 1) then return 'n'
		end
		emu.wait(0.1)
	until machine.time:as_double() > t
	return nil
end

-- player promotions come in lowercase; the machine's own (uppercase) need no key
function interface.promote_key(piece)
	if     (piece == "q") then send_input(":IN.1", 0x40, 1)
	elseif (piece == "r") then send_input(":IN.1", 0x20, 1)
	elseif (piece == "b") then send_input(":IN.1", 0x10, 1)
	elseif (piece == "n") then send_input(":IN.1", 0x08, 1)
	end
end

function interface.promote(x, y, piece)
--	sb_promote(":board", x, y, piece)
	interface.promote_key(piece)
	if pending then
		local m = pending
		pending = nil
		verify_move(m, piece)
	end
end

-- the main line from RAM, without key presses (the address moves with the ROM version)
local line_address = { nsvipb = 0x2700, nsvipc = 0x2704 }
interface.show_info = load_interface("vip_line").reader(line_address[prog] or 0x26f4)
interface.info_every = 1

return interface
