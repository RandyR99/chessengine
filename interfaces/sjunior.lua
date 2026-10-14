interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.turn = true
interface.level = "c1"
interface.cur_level = nil
interface.edit = false
local throttled = true

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = {a=1, b=2, c=3, d=4}
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	send_input(":IN.0", 0x10000, 0.5) -- Level
	interface.send_pos(x)
	interface.send_pos(y)
	send_input(":IN.0", 0x01000, 0.5) -- Enter
end

function interface.setup_machine()
	sb_reset_board(":board")
	interface.turn = true
	interface.edit = false
	send_input(":IN.0", 0x04000, 0.5) -- New Game
	emu.wait(1)

	interface.cur_level = "g1"
	interface.setlevel()
end

function interface.start_play()
	interface.turn = false
	send_input(":IN.0", 0x08000, 0.5) -- Move
end

function clrpiece(x,y)
	send_input(":IN.0", 0x00800, 0.5) -- Clear Entry
	interface.send_pos(x)
	interface.send_pos(y)
	send_input(":IN.0", 0x01000, 0.5) -- Enter
end

function setcastling(c)
	local y=1
	local n=2
	if c==-1 then
		y=8
		n=1
	end
	if get_piece_id(5,y)~=c then
		for i=1,n do
			clrpiece(5,y)
		end
	else
		if get_piece_id(1,y)~=3*c then
			for i=1,n do
				clrpiece(1,y)
			end
		end
		if get_piece_id(8,y)~=3*c then
			for i=1,n do
				clrpiece(8,y)
			end
		end
	end

end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x02000, 0.5) -- Sound
		send_input(":IN.0", 0x00200, 0.5) -- Setup Position
		return (":board")
	else
		setcastling(1)
		setcastling(-1)
		if mode==-1 then
			send_input(":IN.0", 0x00020, 0.5) -- Black
		end
		local fig = {0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x00,0x06,0x05,0x04,0x03,0x02,0x01}
		local ram = machine.devices[":maincpu"].spaces["data"]
		local adr = 0x40 -- board, rank by rank from a1
		for x=1,8 do
			for y=1,8 do
				local p=get_piece_id(x,y)
				local z=fig[p+7]
				ram:write_u8(adr+8*(y-1)+x-1,z)
			end
		end
		send_input(":IN.0", 0x00200, 0.5) -- Setup Position
		send_input(":IN.0", 0x02000, 0.5) -- Sound
	end
end

function interface.edit_game(on)
	interface.edit = on
	local tmp = interface.level:sub(1,1)
	if     tmp == "c" then tmp = "a"
	elseif tmp == "d" then tmp = "b"
	elseif tmp == "a" then tmp = "c"
	elseif tmp == "b" then tmp = "d"
	end
	interface.level = tmp..interface.level:sub(2,2)
	throttled = machine.video.throttled
	machine.video.throttled = false
	interface.setlevel()
	machine.video.throttled = throttled
end

function getdigit(n)
	local map = {{"0.0","0.12","0.20","0.4","0.16","0.8", "0.24"},
		     {"0.1","0.13","0.21","0.5","0.17","0.9", "0.25"},
		     {"0.2","0.14","0.22","0.6","0.18","0.10","0.26"},
		     {"0.3","0.15","0.23","0.7","0.19","0.11","0.27"}}
	local dig = 0x00
	for i=1,7 do
		if (output_value(map[n][i]) ~= 0) then
			dig = dig | (1 << (i-1))
		end
	end
	return dig
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d1 = getdigit(1)
	local d2 = getdigit(2)
	local d3 = getdigit(3)
	local d4 = getdigit(4)
	return (xval[x] == d1 and yval[y] == d2) or (xval[x] == d3 and yval[y] == d4)
end

function interface.send_pos(p)
	if     (p == 1) then send_input(":IN.0", 0x00010, 0.5)
	elseif (p == 2) then send_input(":IN.0", 0x00008, 0.5)
	elseif (p == 3) then send_input(":IN.0", 0x00004, 0.5)
	elseif (p == 4) then send_input(":IN.0", 0x00002, 0.5)
	elseif (p == 5) then send_input(":IN.0", 0x00100, 0.5)
	elseif (p == 6) then send_input(":IN.0", 0x00080, 0.5)
	elseif (p == 7) then send_input(":IN.0", 0x00040, 0.5)
	elseif (p == 8) then send_input(":IN.0", 0x00020, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn or interface.edit) then
			interface.send_pos(x)
			interface.send_pos(y)
		end

		if (event == "put") then
			if (interface.turn or interface.edit) then
				send_input(":IN.0", 0x01000, 0.5) -- Enter
			end
			interface.turn = not interface.turn
		end
	end
end

function interface.get_options()
	return {{"string", "Level", "c1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if level:match("^[cd][1-8]$") then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
end

return interface
