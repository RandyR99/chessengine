interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.invert = false
interface.level = "1"
interface.cur_level = nil
local promcode = 0

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local lev1 = string.find("012345678ABCDEFGH",interface.cur_level)
	local lev2 = string.find("012345678ABCDEFGH",interface.level)
	interface.cur_level = interface.level
	local n = (lev2 - lev1 + 17) % 17
	for i=0,n do
		send_input(":IN.1", 0x40, 0.5) -- Level
	end
	send_input(":IN.1", 0x04, 0.5) -- Set Up
	send_input(":IN.1", 0x04, 0.5) -- Set Up
end

function interface.setup_machine()
	sb_reset_board(":board")
	interface.invert = false
	promcode = 0
	emu.wait(11) -- the machine ignores the board until about 9.5 s after power-on
--	send_input(":IN.1", 0x01, 1)	-- New Game

	interface.cur_level = "1"
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x10, 0.5) -- K
	elseif (n == 2) then send_input(":IN.1", 0x10, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x08, 0.5) -- R
	elseif (n == 4) then send_input(":IN.0", 0x04, 0.5) -- B
	elseif (n == 5) then send_input(":IN.0", 0x02, 0.5) -- N
	elseif (n == 6) then send_input(":IN.0", 0x01, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x04, 1)	-- Set Up
		send_input(":IN.1", 0x01, 1)	-- New Game
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.0", 0x20, 0.5) -- Color
					end
					if math.abs(p)~=math.abs(piece) then
						setpiece(math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		emu.wait(0.5)
		if mode*piece<0 then
			send_input(":IN.0", 0x20, 0.5) -- Color
		end
		send_input(":IN.1", 0x04, 1)	-- Set Up
	end
end

function interface.edit_game(enable)
	-- a Multi Move press right after boot can be missed (the machine then plays the
	-- replayed moves itself): press until its led (3.5) shows the wanted mode
	local want = (enable ~= false)
	for i = 1, 5 do
		if ((output_value("3.5") ~= 0) == want) then
			break
		end
		send_input(":IN.1", 0x20, 1) -- Multi Move
		emu.wait(0.5)
	end
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":IN.1", 0x08, 1)	-- Play
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local xval = output_value("1." .. tostring(x + 7)) ~= 0 or output_value("2." .. tostring(x + 7)) ~= 0
	local yval = output_value("1." .. tostring(8 - y)) ~= 0 or output_value("2." .. tostring(8 - y)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	emu.wait(0.75)
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return { { "string", "Level", "1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = string.upper(value:match("^%s*(.-)%s*$"):gsub("%s%s+"," ")) -- trim
		if level:match("^[0-8]$") or level:match("^[A-H]$") then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	if promcode == 0 then
		promcode = 1
		return nil
	end
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	for i=2,5 do
		setpiece(i)
		emu.wait(0.5)
		if not interface.is_selected(x, y) then
			return ("kqrbnp"):sub(i,i)
		end
	end
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board", x, y, piece)
	if promcode == 1 then
		promcode = 0
	else
		if     (piece == "q") then send_input(":IN.1", 0x10, 0.5)
		elseif (piece == "r") then send_input(":IN.0", 0x08, 0.5)
		elseif (piece == "b") then send_input(":IN.0", 0x04, 0.5)
		elseif (piece == "n") then send_input(":IN.0", 0x02, 0.5)
		end
	end
end

return interface
