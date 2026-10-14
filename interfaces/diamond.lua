interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

local fix_AT_level_bug = true

local rom = machine.devices[":maincpu"].spaces["program"]
if rom:read_u8(0x7534) == 0x79 then -- patched ROM
	fix_AT_level_bug = false
end

interface.level = "a1"
interface.cur_level = nil
local throttled = true

function getdigit(n)
	local map = {{"s0.1","s1.1","s2.1","s3.0","s2.0","s0.0","s1.0"},
		     {"s0.3","s1.3","s2.3","s3.2","s2.2","s0.2","s1.2"},
		     {"s0.5","s1.5","s2.5","s3.4","s2.4","s0.4","s1.4"},
		     {"s0.7","s1.7","s2.7","s3.6","s2.6","s0.6","s1.6"}}
	local dig = 0x00
	for i=1,7 do
		if (output_value(map[n][i]) ~= 0) then
			dig = dig | (1 << (i-1))
		end
	end
	return dig
end

function setdigit(n,z)
	local map = {{"s0.1","s1.1","s2.1","s3.0","s2.0","s0.0","s1.0"},
		     {"s0.3","s1.3","s2.3","s3.2","s2.2","s0.2","s1.2"},
		     {"s0.5","s1.5","s2.5","s3.4","s2.4","s0.4","s1.4"},
		     {"s0.7","s1.7","s2.7","s3.6","s2.6","s0.6","s1.6"}}
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
		if z>d then send_input(":IN.1", 0x02, 0.3) -- Trace Forward
		else send_input(":IN.1", 0x01, 0.3) -- Take Back
		end
	end
end

function fixlevel(level)
	local n
	if fix_AT_level_bug and string.find(level,"b%d") then
		for i=1,2 do
			n = string.find(level,"b1%s%d%d:%d%d:%d%d")
			if n ~= nil then
				 local tmp = level:sub(n,n+10)
				 level = level:gsub(tmp,"a1 01/"..tmp:sub(4,11))
			end
		end
		for i=1,2 do
			n = string.find(level,"b%d")
			if n ~= nil then
				 local ms = {"00:02","00:05","00:10","00:15","00:30","01:00","02:00","03:00"}
				 local tmp = level:sub(n,n+1)
				 level = level:gsub(tmp,"a1 01/00:"..ms[tonumber(tmp:sub(2,2))])
			end
		end
		machine:popmessage("AT level bug fixed!")
	end
	return level
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local level = fixlevel(interface.level)
	level = level:gsub(":","")
	local cols_idx = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8}
	local x0 = 0
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
				send_input(":IN.2", 0x02, 0.5) -- Verify/Setup
				setdigit(3,tonumber(level:sub(1,1)))
				send_input(":IN.2", 0x02, 0.5) -- Verify/Setup
				setdigit(4,tonumber(level:sub(2,2)))
				level = level:sub(4)
			end
			for i=1,4 do
				send_input(":IN.2", 0x02, 0.5) -- Verify/Setup
				setdigit(i,tonumber(level:sub(i,i)))
			end
			for i=3,4 do
				send_input(":IN.2", 0x02, 0.5) -- Verify/Setup
				setdigit(i,tonumber(level:sub(i+2,i+2)))
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
		emu.wait(1)
		if output_value("s3.7") ~= 0 then
			return "Diamond bug: Position with Black in check is not accepted in Setup!"
		end
		if mode<0 then
			send_input(":IN.2", 0x01, 0.5) -- Color
		end
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x40, 0.5) -- Sound
		send_input(":IN.0", 0x40, 0.5) -- Clear
	end
end

function interface.edit_game()
	send_input(":IN.1", 0x80, 0.5) -- Referee
	send_input(":IN.1", 0x80, 0.5) -- Referee
	emu.wait(1)
end

function interface.start_play()
	send_input(":IN.0", 0x01, 0.5) -- Go
end

function interface.is_selected(x, y)
	local xval = output_value("1." .. tostring(8 - x)) ~= 0
	local yval = output_value("0." .. tostring(y - 1)) ~= 0
	return xval and yval
end

-- The board needs a square held for more than 250 ms (MAME driver
-- set_delay) and the machine misses short presses while it is busy.
function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
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
		local l0 = "[a-g][1-8]"
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
	local dig
	repeat
		dig = getdigit(1)
		if     dig == 0x67 then return "q"
		elseif dig == 0x50 then return "r"
		elseif dig == 0x7c then return "b"
		elseif dig == 0x54 then return "n"
		end
		emu.wait(0.25)
	until false
end

function interface.promote(x, y, piece)
	if     (piece == "q") then send_input(":IN.2", 0x08, 0.5)
	elseif (piece == "r") then send_input(":IN.2", 0x10, 0.5)
	elseif (piece == "b") then send_input(":IN.2", 0x20, 0.5)
	elseif (piece == "n") then send_input(":IN.2", 0x40, 0.5)
	end
	sb_promote(":board", x, y, piece)
end

return interface
