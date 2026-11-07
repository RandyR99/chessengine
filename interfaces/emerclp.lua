interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = "TR 1"
interface.cur_level = nil
local promcode = 0
local throttled = true

function getdigit(n)
	local map = {{"s0.2","s1.2","s3.2","s3.0","s2.0","s1.0","s2.1"},
		     {"s0.3","s1.4","s3.4","s3.3","s2.3","s1.3","s2.4"},
		     {"s0.6","s1.7","s3.7","s3.6","s2.6","s1.6","s2.7"},
		     {"s0.8","s1.9","s3.9","s3.8","s2.8","s1.8","s2.9"},
		     {"s0.11","s1.12","s3.12","s3.11","s2.11","s1.11","s2.12"},
		     {"s0.13","s1.14","s3.14","s3.13","s2.13","s1.13","s2.14"}}
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
	interface.cur_level = interface.level
	local level = interface.level
	local lev = level:sub(1,2)
	local x, y, p, p0
	if string.find("TR AT FT SD",lev) then
		if     lev == "TR" then x = 1
		elseif lev == "AT" then x = 3
		elseif lev == "FT" then x = 5
		elseif lev == "SD" then x = 7
		end
		p = 1
	elseif string.find("FD AN EA BE IN FN",lev) then
		if     lev == "FD" then x = 1
		elseif lev == "AN" then x = 2
		elseif lev == "EA" then x = 3
		elseif lev == "BE" then x = 4
		elseif lev == "IN" then x = 5
		elseif lev == "FN" then x = 6
		end
		p = 2
	end
	y = tonumber(level:sub(4))
	if y > 8 then
		x = x + 1
		y = y - 8
	end
	send_input(":IN.1", 0x20, 0.5) -- Set Level
	emu.wait(1)
	local d3=getdigit(3)
	local d4=getdigit(4)
	if (d3==0x78 and d4==0x50) or (d3==0x77 and d4==0x78)
	or (d3==0x71 and d4==0x78) or (d3==0x6d and d4==0x5e) then
		p0 = 1
	else
		p0 = 2
	end
	if p ~= p0 then
		send_input(":IN.1", 0x20, 0.5) -- Set Level
	end
	sb_press_square(":board", 0.5, x, y)
	send_input(":IN.1", 0x01, 0.5) -- Go
end

function interface.setup_machine()
	sb_reset_board(":board")
	promcode = 0
--	send_input(":IN.1", 0x80, 0.5) -- New Game
	emu.wait(2)

	interface.cur_level = "TR 1"
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x04, 0.5) -- K
	elseif (n == 2) then send_input(":IN.0", 0x08, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x10, 0.5) -- R
	elseif (n == 4) then send_input(":IN.0", 0x20, 0.5) -- B
	elseif (n == 5) then send_input(":IN.0", 0x40, 0.5) -- N
	elseif (n == 6) then send_input(":IN.0", 0x80, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x40, 0.5) -- Sound
		send_input(":IN.0", 0x40, 0.5) -- Sound
		send_input(":IN.0", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x04, 0.5) -- Verify/Set Up
		send_input(":IN.1", 0x04, 0.5) -- Verify/Set Up
		send_input(":IN.1", 0x40, 0.5) -- Clear
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.0", 0x01, 0.5) -- Change Color
					end
					if math.abs(p)~=math.abs(piece) then
						setpiece(math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		send_input(":IN.1", 0x01, 0.5) -- Go
		send_input(":IN.0", 0x40, 0.5) -- Sound
		send_input(":IN.0", 0x40, 0.5) -- Sound
		send_input(":IN.0", 0x40, 0.5) -- Sound
		if mode*piece<0 then
			send_input(":IN.0", 0x01, 0.5) -- Change Color
		else
			send_input(":IN.1", 0x40, 0.5) -- Clear
		end
	end
end

function interface.edit_game()
	send_input(":IN.0", 0x80, 0.5) -- Referee
	send_input(":IN.0", 0x80, 0.5) -- Referee
	emu.wait(1)
end

function interface.start_play()
	send_input(":IN.1", 0x01, 0.5) -- Go
end

function interface.is_selected(x, y)
	local xval = output_value("1." .. tostring(8 - x)) ~= 0
	local yval = output_value("0." .. tostring(y - 1)) ~= 0
	return xval and yval
end

-- Right after it has shown its own move the machine sometimes ignores the
-- next square, so a lifted piece is pressed again until its LEDs light up.
local function lifted(x, y)
	for i = 1, 10 do
		if interface.is_selected(x, y) then
			return true
		end
		emu.wait(0.1)
	end
	return false
end

local function put_down(x, y)
	for i = 1, 10 do
		if not interface.is_selected(x, y) then
			return true
		end
		emu.wait(0.1)
	end
	return false
end

local from_sq = nil

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
	if event == "get" then
		from_sq = { x = x, y = y }
		for i = 1, 3 do
			if lifted(x, y) then
				break
			end
			sb_select_piece(":board", 1, x, y, event)
		end
	elseif event == "put" and from_sq ~= nil then
		-- the FROM square stays lit if the TO square was ignored
		for i = 1, 3 do
			if put_down(from_sq.x, from_sq.y) then
				break
			end
			sb_select_piece(":board", 1, x, y, event)
		end
		from_sq = nil
	end
end

function interface.get_options()
	return { { "string", "Level", "TR 1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:upper():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		local lev = level:sub(1,2)
		local num = tonumber(level:sub(4))
		if num == nil then
			return
		end
		if (string.find("TR AT FT SD",lev) and num >= 1 and num <= 16)
		or (string.find("FD AN EA BE IN FN",lev) and num >= 1 and num <= 8) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	sb_press_square(":board", 0.5, x, y)
	promcode = 1
	local p = nil
	repeat
		if     output_value("s0.7") ~= 0 then p = "q"
		elseif output_value("s0.9") ~= 0 then p = "r"
		elseif output_value("s0.12") ~= 0 then p = "b"
		elseif output_value("s0.14") ~= 0 then p = "n"
		end
		if p == nil then
			emu.wait(0.25)
		end
	until p ~= nil
	return p
end

function interface.promote(x, y, piece)
	if promcode == 0 then
		if     (piece == "q") then send_input(":IN.0", 0x08, 0.5)
		elseif (piece == "r") then send_input(":IN.0", 0x10, 0.5)
		elseif (piece == "b") then send_input(":IN.0", 0x20, 0.5)
		elseif (piece == "n") then send_input(":IN.0", 0x40, 0.5)
		end
	end
	promcode = 0
	sb_promote(":board", x, y, piece)
end

-- the machine rotates its search info on the LCD without key presses (manual 18, INFO key: "The rotating displays"),
-- the same pages as the Sapphire II: 3 moves, score, depth, moves left, time
local lcd = load_interface("novag_lcd")
interface.info_every = 0.5
interface.show_info = lcd.reader(lcd.digits6)

return interface
