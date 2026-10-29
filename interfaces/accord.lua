interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = "a1"
interface.cur_level = nil

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	send_input(":IN.0", 0x08, 0.5) -- Set Level
	sb_press_square(":board", 0.5, cols_idx[level:sub(1,1)], tonumber(level:sub(2,2)))
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
		local mem = machine.devices[":maincpu"].spaces["program"]
		send_input(":IN.0", 0x20, 0.5) -- Set Up
		emu.wait(0.5)
		for i=0,31 do
			mem:write_u8(0x40 + i, 0x00)
		end
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.0", 0x80, 0.5) -- White/Black
					end
					if math.abs(p)~=math.abs(piece) then
						setpiece(math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		send_input(":IN.0", 0x01, 0.5) -- Go
		if mode<0 then
			send_input(":IN.0", 0x80, 0.5) -- White/Black
		end
	end
end

-- Game history is replayed in Set Up mode: every move removes the piece from
-- its FROM square and enters it again on the TO square.
local edit_mode = false
local edit_piece = 0
local edit_stm = 1

-- White (0.0) or Black (0.1) LED; all LEDs blank briefly now and then
local function white_led()
	for i=1,20 do
		if output_value("0.0") ~= 0 then return true end
		if output_value("0.1") ~= 0 then return false end
		emu.wait(0.05)
	end
	return true
end

local function setup_color(p)
	-- the colour LED shows the colour of the pieces to enter
	if (p > 0) ~= white_led() then
		send_input(":IN.0", 0x80, 0.5) -- White/Black
	end
end

local function put_piece(x, y, p)
	setup_color(p)
	setpiece(math.abs(p))
	sb_press_square(":board", 0.5, x, y)
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
			send_input(":IN.0", 0x80, 0.5) -- White/Black
		end
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 0.5) -- Go
	emu.wait(0.5)
end

function interface.is_selected(x, y)
	local xval = output_value("2." .. tostring(x - 1)) ~= 0
	local yval = output_value("1." .. tostring(y - 1)) ~= 0
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
	sb_press_square(":board", 0.5, get_sq.x, get_sq.y)
	send_input(":IN.0", 0x20, 0.5) -- Set Up
	emu.wait(0.5)
	sb_press_square(":board", 0.5, get_sq.x, get_sq.y) -- remove the pawn
	if get_piece_id(x, y) ~= 0 then
		sb_press_square(":board", 0.5, x, y) -- remove the captured piece
	end
	put_piece(x, y, sign * ids[under_piece])
	send_input(":IN.0", 0x01, 0.5) -- Go
	emu.wait(0.5)
	if (sign < 0) ~= white_led() then
		send_input(":IN.0", 0x80, 0.5) -- White/Black
	end
	send_input(":IN.0", 0x01, 0.5) -- Go
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
		sb_select_piece(":board", 0.5, x, y, event)
	elseif event:sub(1,3) == "get" then
		edit_piece = get_piece_id(x, y)
		sb_press_square(":board", 0.5, x, y) -- remove
	elseif event == "capture" or event == "en_passant" then
		sb_press_square(":board", 0.5, x, y) -- remove
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
	return { { "string", "Level", "a1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if level:match("^[a-c][1-8]$") then
			interface.level = level
			interface.setlevel()
		end
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
