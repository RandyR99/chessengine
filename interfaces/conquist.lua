interface = {}

interface.level = "3"
interface.cur_level = nil
local promcode = 0

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local lev1 = string.find("012345678ABCDEFGH",interface.cur_level)
	local lev2 = string.find("012345678ABCDEFGH",interface.level)
	interface.cur_level = interface.level
	local n = (lev2 - lev1 + 17) % 17
	for i=0,n do
		send_input(":IN.0", 0x40, 0.5) -- Level
	end
	send_input(":IN.1", 0x20, 0.5) -- Set Up
	send_input(":IN.1", 0x20, 0.5) -- Set Up
end

function interface.setup_machine()
	sb_reset_board(":board")
	promcode = 0
	emu.wait(5)
    send_input(":IN.0", 0x20, 1)	-- New Game

	interface.cur_level = "3"
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.1", 0x04, 0.5) -- K
	elseif (n == 2) then send_input(":IN.0", 0x04, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x10, 0.5) -- R
	elseif (n == 4) then send_input(":IN.1", 0x10, 0.5) -- B
	elseif (n == 5) then send_input(":IN.0", 0x08, 0.5) -- N
	elseif (n == 6) then send_input(":IN.1", 0x08, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x20, 1)	-- Set Up
		send_input(":IN.0", 0x20, 1)	-- New Game
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.0", 0x80, 0.5) -- Color
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
			send_input(":IN.0", 0x80, 0.5) -- Color
		end
		send_input(":IN.1", 0x20, 1)	-- Set Up
	end
end

function interface.edit_game()
	send_input(":IN.1", 0x01, 1) -- Non Auto
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.1", 0x02, 1)	-- Play
end

function interface.is_selected(x, y)
	local xc = {7,6,5,4,3,13,14,15}
	local yc = {8,9,10,11,12,2,1,0}
	local xval = output:get_value("1." .. tostring(xc[x])) ~= 0 or output:get_value("2." .. tostring(xc[x])) ~= 0
	local yval = output:get_value("1." .. tostring(yc[y])) ~= 0 or output:get_value("2." .. tostring(yc[y])) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	emu.wait(0.5)
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return { { "string", "Level", "3"}, }
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
	for i=2,5 do
		setpiece(i)
		emu.wait(0.5)
		if not interface.is_selected(x, y) then
			return ("kqrbnp"):sub(i,i)
		end
	end
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if promcode == 1 then
		promcode = 0
	else
		if     (piece == "q") then send_input(":IN.0", 0x04, 0.5)
		elseif (piece == "r") then send_input(":IN.0", 0x10, 0.5)
		elseif (piece == "b") then send_input(":IN.1", 0x10, 0.5)
		elseif (piece == "n") then send_input(":IN.0", 0x08, 0.5)
		end
	end
end

return interface
