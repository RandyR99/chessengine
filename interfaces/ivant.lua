interface = {}

interface.level = 6
interface.cur_level = nil
local promcode = 0
local throttled = true

function getdigit(n)
	local map = {{"s1.23","s1.9","s0.9","s0.10","s1.10","s0.23","s1.11"},
		     {"s1.19","s1.6","s0.6","s0.8","s1.8","s0.20","s1.20"},
		     {"s1.18","s1.3","s0.3","s0.4","s1.4","s0.18","s1.5"},
		     {"s1.14","s1.7","s0.7","s0.2","s1.2","s0.15","s1.15"},
		     {"s1.12","s1.0","s0.0","s0.1","s1.1","s0.13","s1.13"}}
	local dig = 0x00
	for i=1,7 do
		if (output:get_value(map[n][i]) ~= 0) then
			dig = dig | (1 << (i-1))
		end
	end
	return dig
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local cl = interface.cur_level % 100
	local nl = interface.level % 100
	throttled = machine.video.throttled
	machine.video.throttled = false
	emu.wait(0.5)
	interface.cur_level = interface.level
	send_input(":IN.1", 0x40, 1) -- Level
	local val = {0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f}
	local key
	local dig

	if (nl > cl and nl <= cl+50) or (nl < cl and nl <= cl-50) then
		key = 0x80
	else
		key = 0x01
	end
	local d5 = nl % 10
	local d4 = (nl - d5) / 10
	if nl == 0 then
		dig = 0x3f
	elseif nl < 10 then
		dig = 0x00
	else
		dig = val[d4 + 1]
	end
	emu.wait(0.5)
	ioport.ports[":IN.0"]:field(key):set_value(1) -- Right/Left on
	repeat
		emu.wait(0.25)
	until getdigit(4) == dig
	ioport.ports[":IN.0"]:field(key):set_value(0) -- Right/Left off

	dig = getdigit(5)
	for i=0,9 do
		if dig == val[i+1] then
			cl = i
			break
		end
	end
	local dl = d5 - cl
	if dl > 0 then
		key = 0x80
	else
		key = 0x01
	end
	emu.wait(0.5)
	for i=1,math.abs(dl) do
		send_input(":IN.0", key, 1) -- Right/Left
		emu.wait(0.5)
	end

	emu.wait(0.5)
	send_input(":IN.1", 0x10, 1) -- Clear
	machine.video.throttled = throttled
end

function interface.setup_machine()
	sb_reset_board(":board")
	promcode = 0
--	send_input(":IN.0", 0x10, 0.5) -- New Game
    emu.wait(10)
    send_input(":IN.1", 0x10, 0.5) -- Clear

	interface.cur_level = 6
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.1", 0x02, 0.5) -- K
	elseif (n == 2) then send_input(":IN.0", 0x04, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.1", 0x40, 0.5) -- R
	elseif (n == 4) then send_input(":IN.1", 0x04, 0.5) -- B
	elseif (n == 5) then send_input(":IN.1", 0x80, 0.5) -- N
	elseif (n == 6) then send_input(":IN.1", 0x20, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x02, 1) -- Set Up
		send_input(":IN.0", 0x08, 1) -- Option
		send_input(":IN.0", 0x08, 1) -- Option
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if math.abs(p)~=math.abs(piece) then
						setpiece(math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9-y)
					if p<0 then
						sb_press_square(":board", 0.5, x, 9-y)
					end
					piece=p
				end
			end
		end
		if mode<0 then
			send_input(":IN.0", 0x20, 1) -- Black/White
		end
		send_input(":IN.1", 0x10, 1) -- Clear
	end
end

function interface.edit_game()
	send_input(":IN.1", 0x04, 1) -- Multi Move
end

function interface.start_play(init)
	send_input(":IN.1", 0x20, 1) -- Move
	if init then
		emu.wait(0.5)
		send_input(":IN.0", 0x01, 0.5) -- No
	end
end

function interface.stop_play()
	send_input(":IN.1", 0x20, 1) -- Move
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d1 = getdigit(1)
	local d2 = getdigit(2)
	local d4 = getdigit(4)
	local d5 = getdigit(5)
	return (xval[x] == d1 and yval[y] == d2) or (xval[x] == d4 and yval[y] == d5)
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return { { "spin", "Level", "6", "1", "100"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 100) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	emu.wait(0.5)
	promcode = 1
	if     output:get_value("s0.14") ~= 0 then return "q"
	elseif output:get_value("s0.16") ~= 0 then return "r"
	elseif output:get_value("s0.17") ~= 0 then return "b"
	elseif output:get_value("s0.19") ~= 0 then return "n"
	end
end

function interface.promote(x, y, piece)
	emu.wait(0.5)
	if promcode == 0 then
		if     (piece == "q") then send_input(":IN.0", 0x04, 0.5)
		elseif (piece == "r") then send_input(":IN.1", 0x40, 0.5)
		elseif (piece == "b") then send_input(":IN.1", 0x04, 0.5)
		elseif (piece == "n") then send_input(":IN.1", 0x80, 0.5)
		end
	end
	promcode = 0
	sb_promote(":board", x, y, piece)
end

return interface
