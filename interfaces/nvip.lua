interface = {}

interface.turn = true
interface.level = 1
interface.cur_level = nil
local ram = emu.item(machine.devices[':maincpu'].items['0/:nvram'])
local adr1 = 0x31b
local adr2 = 0x38b
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

function getdigit1()
	local map = {"s0.1","s1.1","s2.1","s3.0","s2.0","s0.0","s1.0"}
	local dig = 0x00
	for i=1,7 do
		if (output:get_value(map[i]) ~= 0) then
			dig = dig | (1 << (i-1))
		end
	end
	return dig
end

function interface.is_selected(x, y)
	if interface.edit then
		return false
	end
	if x==1 and y==1 then
		if getdigit1() == 0x00 then
			send_input(":IN.0", 0x08, 0.6) -- Clear
		end
	end
	local von = ram:read(adr1+count)
	local bis = ram:read(adr2+count)
	local d1 = (von&0x07) + 1
	local d2 = 8 - ((von&0x70)>>4)
	local d3 = (bis&0x07) + 1
	local d4 = 8 - ((bis&0x70)>>4)
	return (x == d1 and y == d2) or (x == d3 and y == d4)
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if interface.turn then
			send_input(":IN.2", 0x01<<(x-1), 0.6)
			send_input(":IN.2", 0x01<<(y-1), 0.6)
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
	send_input(":IN.0", 0x20, 0.6) -- Verify/Setup
	send_input(":IN.2", 0x01<<(x-1), 0.6)
	send_input(":IN.2", 0x01<<(y-1), 0.6)
	emu.wait(0.6)
	local dig = getdigit1()
	send_input(":IN.0", 0x01, 0.6) -- Go
	if     (dig == 0x67) then return 'q'
	elseif (dig == 0x50) then return 'r'
	elseif (dig == 0x7c) then return 'b'
	elseif (dig == 0x54) then return 'n'
	end
end

function interface.promote(x, y, piece)
--	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.1", 0x40, 1)
	elseif (piece == "r") then send_input(":IN.1", 0x20, 1)
	elseif (piece == "b") then send_input(":IN.1", 0x10, 1)
	elseif (piece == "n") then send_input(":IN.1", 0x08, 1)
	end
end

return interface
