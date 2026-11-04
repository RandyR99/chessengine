interface = {}
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 1
interface.cur_level = nil

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	send_input(":IN.0", 0x08, 0.5) -- Set Level
	-- the level is shown by the number of lit rank LEDs
	local k = 8
	while k > 1 and output_value("2." .. tostring(k - 1)) == 0 do
		k = k - 1
	end
	k = (interface.level - k + 8) % 8
	for i=1,k do
		send_input(":IN.0", 0x08, 0.5) -- Set Level
	end
	send_input(":IN.0", 0x01, 0.5) -- Go
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(0.5)

	interface.cur_level = ""
	interface.setlevel()
end

local function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x02, 0.5) -- K
	elseif (n == 2) then send_input(":IN.0", 0x04, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x20, 0.5) -- R
	elseif (n == 4) then send_input(":IN.0", 0x08, 0.5) -- B
	elseif (n == 5) then send_input(":IN.0", 0x10, 0.5) -- N
	elseif (n == 6) then send_input(":IN.0", 0x40, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x20, 0.5) -- Set Up
		emu.wait(0.5)
		sb_clear_board(":board")
		return ("")
	else
		-- board RAM at 0x80, a8 first
		local mem = machine.devices[":maincpu"].spaces["program"]
		local fig = {0x20,0x22,0x24,0x23,0x25,0x21,0x00,0x11,0x15,0x13,0x14,0x12,0x10}
		local adr = 0x0080
		local z
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				mem:write_u8(adr,fig[p+7])
				adr=adr+1
				if p~=0 then
					if p>0 then
						z=6-p
					else
						z=12+p
					end
					send_input(":board:SPAWN", 0x01<<z, 0.09)
					sb_move_piece(":board", x, 9-y)
					emu.wait(0.5)
				end
			end
		end
		send_input(":IN.0", 0x01, 0.5) -- Go
		emu.wait(0.5)
		if mode==-1 then
			send_input(":IN.0", 0x80, 0.5) -- Black/White
			emu.wait(0.5)
		end
	end
end

-- White (0.0) or Black (0.1) LED; the LEDs blank briefly now and then
local WHITE_LED = "0.0"
local BLACK_LED = "0.1"
local function white_led()
	for i=1,20 do
		if output_value(WHITE_LED) ~= 0 then return true end
		if output_value(BLACK_LED) ~= 0 then return false end
		emu.wait(0.05)
	end
	return true
end

-- Game history is replayed in Set Up mode: every move removes the piece from
-- its FROM square and enters it again on the TO square.
local edit_mode = false
local edit_piece = 0
local edit_stm = 1

local function setup_color(p)
	-- the colour LED shows the colour of the pieces to enter
	if (p > 0) ~= white_led() then
		send_input(":IN.0", 0x80, 0.5) -- Black/White
	end
end

local function put_piece(x, y, p)
	setup_color(p)
	setpiece(math.abs(p))
	sb_press_square(":board", 1, x, y)
end

function interface.edit_game(start)
	if start then
		send_input(":IN.0", 0x20, 0.5) -- Set Up
		emu.wait(0.5)
		edit_mode = true
	else
		edit_mode = false
		send_input(":IN.0", 0x01, 0.5) -- Go
		emu.wait(0.5)
		-- the colour LED shows the side to move
		if (edit_stm > 0) ~= white_led() then
			send_input(":IN.0", 0x80, 0.5) -- Black/White
		end
		emu.wait(1) -- a Go right after this is ignored
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 0.5) -- Go
	emu.wait(0.5)
end

-- The board needs a square held for more than 350 ms (MAME driver set_delay),
-- so all squares are pressed for 1 s.

function interface.is_selected(x, y)
	local xval = output_value("1." .. tostring(x - 1)) ~= 0
	local yval = output_value("2." .. tostring(y - 1)) ~= 0
	return xval and yval
end

-- The machine always promotes the player's pawn to a queen, so a player
-- underpromotion is entered in Set Up mode instead.
local get_sq = nil
local under_piece = nil
local under_done = false

local function underpromote(x, y)
	local sign = (y == 8) and 1 or -1
	local ids = { r=3, b=4, n=5 }
	-- Set Up is ignored while the pawn is lifted: put it back first
	sb_press_square(":board", 1, get_sq.x, get_sq.y)
	send_input(":IN.0", 0x20, 0.5) -- Set Up
	emu.wait(0.5)
	sb_press_square(":board", 1, get_sq.x, get_sq.y) -- remove the pawn
	if get_piece_id(x, y) ~= 0 then
		sb_press_square(":board", 1, x, y) -- remove the captured piece
	end
	put_piece(x, y, sign * ids[under_piece])
	send_input(":IN.0", 0x01, 0.5) -- Go
	emu.wait(0.5)
	if (sign < 0) ~= white_led() then
		send_input(":IN.0", 0x80, 0.5) -- Black/White
	end
	emu.wait(1) -- a Go right after this is ignored
	send_input(":IN.0", 0x01, 1) -- Go
	under_piece = nil
	under_done = true
end

function interface.promote_special(piece)
	if not edit_mode and piece ~= "q" then
		under_piece = piece
	end
end

function interface.select_piece(x, y, event)
	if not edit_mode then
		if event:sub(1,3) == "get" then
			get_sq = { x = x, y = y }
		end
		if under_piece ~= nil then
			if event:sub(1,3) == "put" then
				underpromote(x, y)
			end
			return
		end
		if (event == "get_castling" or event == "put_castling") then
			sb_move_piece(":board", x, y)
		else
			sb_select_piece(":board", 1, x, y, event)
		end
	elseif event:sub(1,3) == "get" then
		edit_piece = get_piece_id(x, y)
		sb_press_square(":board", 1, x, y) -- remove
	elseif event == "capture" or event == "en_passant" then
		sb_press_square(":board", 1, x, y) -- remove
	elseif event:sub(1,3) == "put" then
		if event == "put" then
			edit_stm = edit_piece > 0 and -1 or 1
		end
		-- a promoting pawn is entered by promote()
		if not (math.abs(edit_piece) == 6 and (y == 1 or y == 8)) then
			put_piece(x, y, edit_piece)
		end
	end
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "8"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level == nil or level < 1 or level > 8) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	if edit_mode then
		local ids = { q=2, r=3, b=4, n=5 }
		put_piece(x, y, (edit_piece > 0 and 1 or -1) * ids[piece:lower()])
		return
	end
	if under_done then
		under_done = false
		return
	end
	promotion_error(piece)
	sb_promote(":board", x, y, "q")
end

return interface
