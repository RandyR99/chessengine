interface = {}

interface.level = "a1"
interface.cur_level = nil
local promcode = 0
local throttled = true

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
			if (output:get_value(map[n][i]) ~= 0) then
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
		if z>d then send_input(":IN.1", 0x02, 0.25) -- Trace Forward
		else send_input(":IN.1", 0x01, 0.25) -- Take Back
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
	local x
	local y
	local z = level:len()
	if z > 5 then
		throttled = machine.video.throttled
		machine.video.throttled = false
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x40, 0.5) -- Sound
	end
	send_input(":IN.0", 0x20, 0.5) -- Set Level
	repeat
		x = cols_idx[level:sub(1, 1)]
		y = tonumber(level:sub(2, 2))
		sb_press_square(":board", 0.5, x, y)
		level = level:sub(4)
		if level:match("^%d%d") then
			if x == 1 then
				send_input(":IN.2", 0x02, 0.25) -- Verify/Setup
				setdigit(5,tonumber(level:sub(1,1)))
				send_input(":IN.2", 0x02, 0.25) -- Verify/Setup
				setdigit(6,tonumber(level:sub(2,2)))
				level = level:sub(4)
			end
			for i=1,6 do
				send_input(":IN.2", 0x02, 0.25) -- Verify/Setup
				setdigit(i,tonumber(level:sub(i,i)))
			end
			send_input(":IN.0", 0x01, 0.5) -- Go
			level = level:sub(8)
		end
		if level ~= "" then
			send_input(":IN.2", 0x01, 0.5) -- Color
		end
	until level == ""
	send_input(":IN.0", 0x01, 0.5) -- Go
	if z > 5 then
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x40, 0.5) -- Sound
		machine.video.throttled = throttled
		send_input(":IN.0", 0x40, 0.5) -- Clear
	end
end

function interface.setup_machine()
	sb_reset_board(":board")
	promcode = 0
--	send_input(":IN.0", 0x80, 0.5) -- New Game
	emu.wait(1)

	interface.cur_level = "a1"
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.2", 0x04, 0.5) -- K
	elseif (n == 2) then send_input(":IN.2", 0x08, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.2", 0x10, 0.5) -- R
	elseif (n == 4) then send_input(":IN.2", 0x20, 0.5) -- B
	elseif (n == 5) then send_input(":IN.2", 0x40, 0.5) -- N
	elseif (n == 6) then send_input(":IN.2", 0x80, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.2", 0x02, 0.5) -- Verify/Setup
		send_input(":IN.2", 0x02, 0.5) -- Verify/Setup
		send_input(":IN.0", 0x40, 0.5) -- Clear Board
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.2", 0x01, 0.5) -- Color
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
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x40, 0.5) -- Sound
		if mode*piece<0 then
			send_input(":IN.2", 0x01, 0.5) -- Color
		else
			send_input(":IN.0", 0x40, 0.5) -- Clear
		end
	end
end

function interface.edit_game()
	send_input(":IN.1", 0x80, 0.5) -- Referee
	send_input(":IN.1", 0x80, 0.5) -- Referee
	emu.wait(1)
end

function interface.start_play(init)
	send_input(":IN.0", 0x01, 0.5) -- Go
end

function interface.is_selected(x, y)
	local xval = output:get_indexed_value("1.", 8 - x) ~= 0
	local yval = output:get_indexed_value("0.", y - 1) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return { { "string", "Level", "a1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		level = level:gsub("tr","a1")
		level = level:gsub("at","b1")
		level = level:gsub("sd","c1")
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
		if     output:get_value("s0.7") ~= 0 then p = "q"
		elseif output:get_value("s0.9") ~= 0 then p = "r"
		elseif output:get_value("s0.12") ~= 0 then p = "b"
		elseif output:get_value("s0.14") ~= 0 then p = "n"
		end
		if p == nil then
			emu.wait(0.25)
		end
	until p ~= nil
	return p
end

function interface.promote(x, y, piece)
	if promcode == 0 then
		if     (piece == "q") then send_input(":IN.2", 0x08, 0.5)
		elseif (piece == "r") then send_input(":IN.2", 0x10, 0.5)
		elseif (piece == "b") then send_input(":IN.2", 0x20, 0.5)
		elseif (piece == "n") then send_input(":IN.2", 0x40, 0.5)
		end
	end
	promcode = 0
	sb_promote(":board", x, y, piece)
end

return interface
