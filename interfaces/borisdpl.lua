interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.turn = true
interface.color = "B"
interface.level = "000000"
interface.cur_level = nil
interface.set = false

function interface.get_module()
	return "Boris Diplomat"
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
	send_input(":IN.3", 0x04, 0.5) -- SET
	emu.wait(0.5)
	send_input(":IN.3", 0x08, 0.5) -- CE
	emu.wait(0.5)
	for i = 1, interface.level:len() do
		local n = tonumber(interface.level:sub(i,i))
		if n == 0 then
			send_input(":IN.0", 0x01, 0.5)
		elseif n <= 3 then
			send_input(":IN.1", 0x01 << (n - 1), 0.5)
		elseif n <= 6 then
			send_input(":IN.2", 0x01 << (n - 4), 0.5)
		elseif n <= 9 then
			send_input(":IN.3", 0x01 << (n - 7), 0.5)
		end
	end
	send_input(":IN.0", 0x08, 0.5) -- ENTER
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	interface.turn = true
	interface.color = "B"
	interface.set = false
	send_input(":RESET", 0x01, 0.5) -- RESET
	emu.wait(1)
	interface.cur_level = "000000"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":RESET", 0x01, 0.5) -- RESET
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local piece = 7
		for y = 1, 8 do
			send_input(":IN.1", 0x08, 0.5) -- RANK
			send_input(":IN.3", 0x08, 0.5) -- CE
			for x = 1, 8 do
				local p = get_piece_id(x, y)
				if p == 0 then
					send_input(":IN.0", 0x02, 0.5) -- [-]
				else
					if p * piece < 0 then
						send_input(":IN.0", 0x04, 0.5) -- B/W
					end
					emu.wait(0.5)
					interface.send_pos(7 - math.abs(p))
					piece = p
				end
			end
		end
		if mode * piece < 0 then
			send_input(":IN.0", 0x04, 0.5) -- B/W
		end
		if mode == 1 then
			interface.color = "B"
		else
			interface.color = "W"
		end
		send_input(":IN.0", 0x08, 0.5) -- ENTER
		interface.set = true
		machine.video.throttled = throttled_state
	end
end

function interface.start_play(init)
	-- New game, or the machine moves first after a position setup: move the hyphen
	-- (the player's side) away from the side to move, so ENTER makes the machine move
	if (init or interface.set) then
		send_input(":IN.0", 0x04, 0.5) -- B/W
		interface.set = false
	end
	if (interface.color == "W") then
		interface.color = "B"
	else
		interface.color = "W"
	end
	interface.turn = false
	send_input(":IN.0", 0x08, 0.5) -- ENTER
	emu.wait(0.25)
end

function interface.stop_play()
end

-- Driver save item m_ram_address; looked up once, as device.items walks every save item
local ram_address = nil

function interface.is_selected_int(x, y)
	if ram_address == nil then
		ram_address = emu.item(machine.devices[':maincpu'].owner.items['0/m_ram_address'])
	end
	if (ram_address:read() ~= 0x0f) then
		emu.wait(0.5)
		if (ram_address:read() ~= 0x0f) then
			return false
		end
	end
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local root = machine.devices[":"]
	local function digit(n)
		local node = root:output("digit" .. n)
		return node and node:get() or 0
	end
	local d0 = digit(0)
	local d1 = digit(1)
	local d2 = digit(2)
	local d3 = digit(3)
	local d4 = digit(4)
	return (d2 == 0x01 or interface.color == "W") and (d2 == 0x08 or interface.color == "B") and ((xval[x] == d0 and yval[y] == d1) or (xval[x] == d3 and yval[y] == d4))
end

function interface.is_selected(x, y)
	if (interface.is_selected_int(x, y)) then
		emu.wait(0.5)
		return interface.is_selected_int(x, y)
	end
	return false
end

function interface.send_pos(p)
	if	   (p == 1) then send_input(":IN.1", 0x01, 0.5)
	elseif (p == 2)	then send_input(":IN.1", 0x02, 0.5)
	elseif (p == 3)	then send_input(":IN.1", 0x04, 0.5)
	elseif (p == 4)	then send_input(":IN.2", 0x01, 0.5)
	elseif (p == 5)	then send_input(":IN.2", 0x02, 0.5)
	elseif (p == 6)	then send_input(":IN.2", 0x04, 0.5)
	elseif (p == 7)	then send_input(":IN.3", 0x01, 0.5)
	elseif (p == 8)	then send_input(":IN.3", 0x02, 0.5)
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
				send_input(":IN.0", 0x08, 0.5) -- ENTER
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
	-- Level is the timer interval as hhmmss; shorter values are padded with leading zeros
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
