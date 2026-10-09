interface = {}

interface.turn = true
interface.color = "B"
interface.level = "000000"
interface.cur_level = nil

function interface.get_module()
	if machine.system.name == "boris" then
		return "Boris"
	elseif machine.system.name == "borisa" then
		return "Boris v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "David Lindsay"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local s = "000000"
	local level = s:sub(1, 6 - interface.level:len()) .. interface.level
	send_input(":IN.0", 0x04, 0.5) -- SET
	emu.wait(0.5)
	send_input(":IN.0", 0x08, 0.5) -- CE
	emu.wait(0.5)
	for i = 1, 6 do
		local n = tonumber(level:sub(i,i))
		if n == 0 then
			send_input(":IN.3", 0x01, 0.5)
		elseif n <= 3 then
			send_input(":IN.2", 0x01 << (n - 1), 0.5)
		elseif n <= 6 then
			send_input(":IN.1", 0x01 << (n - 4), 0.5)
		elseif n <= 9 then
			send_input(":IN.0", 0x01 << (n - 7), 0.5)
		end
	end
	send_input(":IN.3", 0x08, 0.5) -- ENTER
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	interface.turn = true
	interface.color = "B"
	interface.set = false
	if (ioport.ports[":RESET"]:read() == 0x01) then
		send_input(":RESET", 0x01, 0.5) -- RESET
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(12)
	machine.video.throttled = throttled_state
	interface.cur_level = "000000"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		if (machine.ioport.ports[":RESET"]:read() == 0x01) then
			send_input(":RESET", 0x01, 0.5) -- RESET
		end
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local piece = 7
		for y = 1, 8 do
			send_input(":IN.2", 0x08, 0.5) -- RANK
			send_input(":IN.0", 0x08, 0.5) -- CE
			for x = 1, 8 do
				local p = get_piece_id(x, y)
				if p == 0 then
					send_input(":IN.3", 0x02, 0.5) -- [-]
				else
					if p * piece < 0 then
						send_input(":IN.3", 0x04, 0.5) -- B/W
					end
					emu.wait(0.5)
					interface.send_pos(7 - math.abs(p))
					piece = p
				end
			end
		end
		if mode * piece > 0 then
			send_input(":IN.3", 0x04, 0.5) -- B/W
		end
		if mode == 1 then
			interface.color = "B"
		else
			interface.color = "W"
		end
		send_input(":IN.3", 0x08, 0.5) -- ENTER
		interface.set = true
		machine.video.throttled = throttled_state
	end
end

function interface.start_play(init)
	if (init) then
		send_input(":IN.3", 0x04, 0.5) -- B/W
		interface.set = false
	end
	if (interface.color == "W") then
		interface.color = "B"
	else
		interface.color = "W"
	end
	interface.turn = false
	send_input(":IN.3", 0x08, 0.5) -- ENTER
	emu.wait(0.25)
end

function interface.stop_play()
end

function interface.is_selected_int(x, y)
	local xval = { 0x3cf, 0x0e3f, 0x00f3, 0x0c3f, 0x01f3, 0x01c3, 0x02fb, 0x03cc }
	local yval = { 0xc31, 0x0377, 0x023f, 0x038c, 0x03bb, 0x03fb, 0x4803, 0x03ff }
	local root = machine.devices[":"]
	local function digit(n)
		local node = root:output("digit" .. n)
		return node and node:get() or 0
	end
	local d0 = digit(7)
	local d1 = digit(6)
	local d2 = digit(5)
	local d3 = digit(4)
	local d4 = digit(3)
	return (d2 == 0x0003 or interface.color == "W") and (d2 == 0x0030 or interface.color == "B") and ((xval[x] == d0 and yval[y] == d1) or (xval[x] == d3 and yval[y] == d4))
end

function interface.is_selected(x, y)
	if (interface.is_selected_int(x, y)) then
		emu.wait(0.3)
		return interface.is_selected_int(x, y)
	end
	return false
end

function interface.send_pos(p)
	if	   (p == 1) then send_input(":IN.2", 0x01, 0.5)
	elseif (p == 2)	then send_input(":IN.2", 0x02, 0.5)
	elseif (p == 3)	then send_input(":IN.2", 0x04, 0.5)
	elseif (p == 4)	then send_input(":IN.1", 0x01, 0.5)
	elseif (p == 5)	then send_input(":IN.1", 0x02, 0.5)
	elseif (p == 6)	then send_input(":IN.1", 0x04, 0.5)
	elseif (p == 7)	then send_input(":IN.0", 0x01, 0.5)
	elseif (p == 8)	then send_input(":IN.0", 0x02, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn) then
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "put") then
			if (interface.turn) then
				send_input(":IN.3", 0x08, 0.5) -- ENTER
				emu.wait(0.25)
				interface.set = false
			end
			interface.turn = not interface.turn
		end
	end
end

function interface.get_options()
	return {
		{ "string", "Level", "000000" },  -- timer interval hhmmss
	}
end

function interface.set_option(name, value)
	-- Level is Boris's timer interval as hhmmss; shorter values are padded with leading zeros
	local level = value:match("^%s*(%d+)%s*$")
	if (name == "level" and level and level:len() <= 6) then
		interface.level = string.rep("0", 6 - level:len()) .. level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	-- TODO
end

return interface
