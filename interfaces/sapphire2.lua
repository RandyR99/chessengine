interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.turn = true
interface.level = "a1"
interface.cur_level = nil
local ram = machine.memory.shares[":nvram"]
local adr = 0x6c90
local count = 0
interface.edit = false
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

function setdigit(n,z)
	local map = {{"s0.2","s1.2","s3.2","s3.0","s2.0","s1.0","s2.1"},
		     {"s0.3","s1.4","s3.4","s3.3","s2.3","s1.3","s2.4"},
		     {"s0.6","s1.7","s3.7","s3.6","s2.6","s1.6","s2.7"},
		     {"s0.8","s1.9","s3.9","s3.8","s2.8","s1.8","s2.9"},
		     {"s0.11","s1.12","s3.12","s3.11","s2.11","s1.11","s2.12"},
		     {"s0.13","s1.14","s3.14","s3.13","s2.13","s1.13","s2.14"}}
	local dig = 0x00
	repeat
		for i=1,7 do
			if (output_value(map[n][i]) ~= 0) then
				dig = dig | (1 << (i-1))
			end
		end
		if dig == 0x00 then
			emu.wait(0.5)
		end
	until dig ~= 0x00
	local lst = {0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f}
	local d = 0
	for i=0,9 do
		if dig == lst[i+1] then
			d = i
			break
		end
	end
	for i=1,math.abs(z-d) do
		if z>d then send_input(":IN.0", 0x40, 0.25) -- Right
		else send_input(":IN.1", 0x40, 0.25) -- Left
		end
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local level = interface.level:gsub(":","")
	local cols_idx = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8}
	local x0 = 0
	local x
	local y
	local z = level:len()
	if z > 2 then
		throttled = machine.video.throttled
		machine.video.throttled = false
		send_input(":IN.1", 0x10, 0.6) -- Sound
		send_input(":IN.1", 0x10, 0.6) -- Sound
		send_input(":IN.1", 0x10, 0.6) -- Sound
	end
	send_input(":IN.0", 0x08, 0.6) -- Level
	repeat
		emu.wait(1)
		local d3=getdigit(3)
		local d4=getdigit(4)
		if     d3==0x78 and d4==0x50 then x0 = 1
		elseif d3==0x77 and d4==0x78 then x0 = 2
		elseif d3==0x6d and d4==0x5e then x0 = 3
		elseif d3==0x71 and d4==0x5e then x0 = 4
		elseif d3==0x77 and d4==0x54 then x0 = 5
		elseif d3==0x79 and d4==0x77 then x0 = 6
		elseif d3==0x7c and d4==0x79 then x0 = 7
		elseif d3==0x04 and d4==0x54 then x0 = 8
		end
		x = cols_idx[level:sub(1, 1)]
		y = tonumber(level:sub(2, 2))

		for i=1,(x-x0+8)%8 do
			send_input(":IN.0", 0x08, 0.6) -- Level
		end
		send_input(":IN.2", 0x80>>(y-1), 0.6)
		level = level:sub(4)
		if level ~= "" and level:match("^%d%d") then
			if x == 1 then
				send_input(":IN.0", 0x20, 0.6) -- Ver/Set
				setdigit(5,tonumber(level:sub(1,1)))
				send_input(":IN.0", 0x20, 0.6) -- Ver/Set
				setdigit(6,tonumber(level:sub(2,2)))
				level = level:sub(4)
			end
			for i=1,6 do
				send_input(":IN.0", 0x20, 0.6) -- Ver/Set
				setdigit(i,tonumber(level:sub(i,i)))
			end
			send_input(":IN.0", 0x80, 0.6) -- Go
			level = level:sub(8)
		end
		if level ~= "" then
			send_input(":IN.1", 0x80, 0.6) -- Color
		end
	until level == ""
	send_input(":IN.0", 0x80, 0.6) -- Go
	if z > 2 then
		send_input(":IN.1", 0x10, 0.6) -- Sound
		send_input(":IN.1", 0x10, 0.6) -- Sound
		send_input(":IN.1", 0x10, 0.6) -- Sound
		machine.video.throttled = throttled
		send_input(":IN.0", 0x02, 0.6) -- C
	end
end

function interface.setup_machine()
	interface.turn = true
	interface.edit = false
	promcode = 0
--	sb_reset_board(":board")
--	send_input(":IN.0", 0x01, 0.6) -- NG
	count = 0
	emu.wait(1)

	interface.cur_level = "a1"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x10, 0.6) -- Sound
		send_input(":IN.1", 0x10, 0.6) -- Sound
		send_input(":IN.1", 0x10, 0.6) -- Sound
		send_input(":IN.0", 0x20, 0.6) -- Ver/Set
		send_input(":IN.0", 0x20, 0.6) -- Ver/Set
		send_input(":IN.0", 0x02, 0.6) -- CB
		return ("")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.1", 0x80, 0.6) -- Color
					end
					if math.abs(p)~=math.abs(piece) then
						send_input(":IN.1", 0x80>>(math.abs(p)+1), 0.6)
					end
					send_input(":IN.2", 0x80>>(x-1), 0.6)
					send_input(":IN.2", 0x80>>(8-y), 0.6)
					piece=p
				end
			end
		end
		-- the colour selected when leaving Set Up is the side to move
		if mode*piece<0 then
			send_input(":IN.1", 0x80, 0.6) -- Color
		end
		send_input(":IN.0", 0x80, 0.6) -- Go
		send_input(":IN.1", 0x10, 0.6) -- Sound
		send_input(":IN.1", 0x10, 0.6) -- Sound
		send_input(":IN.1", 0x10, 0.6) -- Sound
		send_input(":IN.0", 0x02, 0.6) -- C
	end
end

function interface.edit_game(on)
	send_input(":IN.1", 0x08, 0.6) -- Referee
	send_input(":IN.1", 0x08, 0.6) -- Referee
	interface.edit = on
	emu.wait(0.6)
end

function interface.start_play(init)
	interface.turn = false
	send_input(":IN.0", 0x80, 0.6) -- Go
end

function interface.is_selected(x, y)
	if interface.edit then
		return false
	end
	local von = ram:read_u8(adr+count+1)
	local bis = ram:read_u8(adr+count+0)
	local d3 = (von&0x07) + 1
	local d4 = 8 - ((von&0x70)>>4)
	local d5 = (bis&0x07) + 1
	local d6 = 8 - ((bis&0x70)>>4)
	return (x == d3 and y == d4) or (x == d5 and y == d6)
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if interface.turn then
			-- the Sapphire II sometimes misses a short coordinate key
			send_input(":IN.2", 0x80>>(x-1), 1)
			send_input(":IN.2", 0x80>>(y-1), 1)
		end
		if event == "put" then
			if not interface.edit then
				interface.turn = not interface.turn
			end
			count = count + 2
		end
	end
end

function interface.get_options()
	return { { "string", "Level", "TR 1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:upper():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		level = level:gsub("+","#")
		level = level:gsub("TR#","a1 ")
		level = level:gsub("AT#","b1 ")
		level = level:gsub("SD#","c1 ")
		level = level:gsub("TR ","a")
		level = level:gsub("AT ","b")
		level = level:gsub("SD ","c")
		level = level:gsub("FD ","d")
		level = level:gsub("AN ","e")
		level = level:gsub("EA ","f")
		level = level:gsub("BE ","g")
		level = level:gsub("IN ","h")
		local temp = level
		local nn = " [0-9][0-9]"
		local hms = "[01][0-9]:[0-5][0-9]:[0-5][0-9]"
		local l2 = "a[1-8]"..nn.."/"..hms
		local l1 = "[bc][1-8]".." "..hms
		local l0 = "[a-h][1-8]"
		if     temp:match("^"..l2) and tonumber(temp:sub(7,8))<18 then temp = temp:sub(15)
		elseif temp:match("^"..l1) and tonumber(temp:sub(4,5))<18 then temp = temp:sub(12)
		elseif temp:match("^"..l0) then temp = temp:sub(3)
		else return
		end
		if temp == ""
		or temp:match(" "..l2.."$") and tonumber(temp:sub(8,9))<18
		or temp:match(" "..l1.."$") and tonumber(temp:sub(5,6))<18
		or temp:match(" "..l0.."$") then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
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

-- The piece keys double as function keys (Rook = Referee). A piece key the
-- machine takes as a function only shows that function's status, and then
-- it asks for the piece again ("Pro"), so the key is pressed until the
-- prompt has gone.
local function promotion_prompt()
	for n = 1, 5 do
		if getdigit(n) == 0x73 and getdigit(n + 1) == 0x50 then
			return true
		end
	end
	return false
end

local function wait_prompt(t)
	for i = 1, t * 10 do
		if promotion_prompt() then
			return true
		end
		emu.wait(0.1)
	end
	return false
end

local function choose_piece(piece)
	local keys = { q = 0x10, r = 0x08, b = 0x04, n = 0x02 }
	if keys[piece] == nil then
		return
	end
	wait_prompt(4)
	for i = 1, 3 do
		send_input(":IN.1", keys[piece], 1)
		emu.wait(2.5) -- also lets a function status message time out
		if not wait_prompt(1.5) then
			return
		end
	end
end

function interface.promote(x, y, piece)
	if promcode == 0 then
		choose_piece(piece)
	end
	promcode = 0
--	sb_promote(":board", x, y, piece)
end


-- the machine rotates its search info on the LCD without key presses
local lcd = load_interface("novag_lcd")
interface.info_every = 0.5
interface.show_info = lcd.reader(lcd.digits6)

return interface
