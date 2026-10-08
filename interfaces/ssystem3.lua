interface = {}

interface.turn = true
interface.color = "B"
interface.level = "10"
interface.cur_level = nil
interface.edit = 0

function interface.setdigit(n)
	if     (n == 0)	then	send_input(":IN.0", 0x08, 0.5)
	elseif (n == 1)	then	send_input(":IN.2", 0x08, 0.5)
	elseif (n == 2)	then	send_input(":IN.3", 0x08, 0.5)
	elseif (n == 3)	then	send_input(":IN.3", 0x04, 0.5)
	elseif (n == 4)	then	send_input(":IN.2", 0x04, 0.5)
	elseif (n == 5)	then	send_input(":IN.1", 0x04, 0.5)
	elseif (n == 6)	then	send_input(":IN.1", 0x02, 0.5)
	elseif (n == 7)	then	send_input(":IN.2", 0x02, 0.5)
	elseif (n == 8)	then	send_input(":IN.3", 0x02, 0.5)
	elseif (n == 9)	then	send_input(":IN.0", 0x02, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local s = "000000"
	local level = s:sub(1,6-interface.level:len()) .. interface.level
	send_input(":IN.1", 0x02, 0.5) -- 6/F/CLK
	emu.wait(0.5)
	send_input(":IN.0", 0x04, 0.5) -- Enter
	emu.wait(0.5)
	for i=1,6 do
		local n = tonumber(level:sub(i,i))
		interface.setdigit(n)
		if ((i % 2) == 0) then
			send_input(":IN.0", 0x04, 0.5) -- Enter
		end
	end
	emu.wait(0.5)
end

function interface.setup_machine()
	interface.turn = true
	interface.color = "B"
	emu.wait(2.5)
	send_input(":IN.2", 0x01, 0.5) -- New Game
	emu.wait(0.5)

	interface.cur_level = "10"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x02, 0.5) -- EP
		send_input(":IN.4", 0x01, 0.5) -- SOUND
		send_input(":IN.0", 0x04, 0.5) -- ENTER
		send_input(":IN.0", 0x08, 0.5) -- MD
		return ("")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						if p>0 then
							send_input(":IN.2", 0x08, 0.5) -- White
						else
							send_input(":IN.3", 0x02, 0.5) -- Black
						end
					end
					interface.send_pos(math.abs(p)+1)
					interface.send_pos(x)
					interface.send_pos(9-y)
					piece=p
				end
			end
		end
		send_input(":IN.0", 0x04, 0.5) -- ENTER
		if mode==1 then
			send_input(":IN.2", 0x08, 0.5) -- White
		else
			send_input(":IN.3", 0x02, 0.5) -- Black
		end
		send_input(":IN.4", 0x01, 0.5) -- SOUND
		send_input(":IN.0", 0x04, 0.5) -- ENTER
		if mode==1 then
			interface.color = "B"
		else
			interface.color = "W"
		end
	end
end

function interface.edit_game(on)
	if on then
		interface.edit = 1
		send_input(":IN.0", 0x08, 0.5) -- 0 / MD
		send_input(":IN.0", 0x04, 0.5) -- Enter
	else
		interface.edit = 0
		send_input(":IN.0", 0x04, 0.5) -- Enter
		if (interface.color == "W") then
			send_input(":IN.3", 0x02, 0.5) -- 8 / Black
		else
			send_input(":IN.2", 0x08, 0.5) -- 1 / White
		end
		send_input(":IN.0", 0x04, 0.5) -- Enter
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	if (interface.color == "W") then
		interface.color = "B"
	else
		interface.color = "W"
	end
	interface.turn = false
	send_input(":IN.0", 0x04, 0.5) -- Enter
	emu.wait(0.5)
end

function interface.stop_play()
	if (not interface.turn) then
		send_input(":IN.1", 0x08, 1.5) -- CE
		emu.wait(0.5)
	end
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output:get_value("digit3")
	local d1 = output:get_value("digit2")
	local d2 = output:get_value("digit1")
	local d3 = output:get_value("digit0")
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then	send_input(":IN.2", 0x08, 0.5)
	elseif (p == 2)	then	send_input(":IN.3", 0x08, 0.5)
	elseif (p == 3)	then	send_input(":IN.3", 0x04, 0.5)
	elseif (p == 4)	then	send_input(":IN.2", 0x04, 0.5)
	elseif (p == 5)	then	send_input(":IN.1", 0x04, 0.5)
	elseif (p == 6)	then	send_input(":IN.1", 0x02, 0.5)
	elseif (p == 7)	then	send_input(":IN.2", 0x02, 0.5)
	elseif (p == 8)	then	send_input(":IN.3", 0x02, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn) then
			if (interface.edit == 1) then
				interface.edit = 2
			elseif (interface.edit ==2 and event == "get") then
				send_input(":IN.0", 0x08, 0.5) -- 0 / MD
			end
			interface.send_pos(x)
			interface.send_pos(y)
		end

		if (event == "put") then
			if (interface.turn and interface.edit == 0) then
				send_input(":IN.0", 0x04, 0.5) -- Enter
				emu.wait(0.5)
			end
			if (interface.color == "W") then
				interface.color = "B"
			else
				interface.color = "W"
			end
			if (interface.edit == 0) then
				interface.turn = not interface.turn
			end
		end
	end
end

function interface.get_options()
	return { { "string", "Level", "10"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		interface.level = value
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local ram = emu.item(machine.devices[':maincpu'].items['0/:nvram'])
	local adr = 0x0067
	local piece = (ram:read(adr+16*(y-1)+x-1))&0x07
	if     piece==0x05 then return 'q'
	elseif piece==0x04 then return 'r'
	elseif piece==0x03 then return 'b'
	elseif piece==0x02 then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	emu.wait(1)
	if     (piece == "q") then	send_input(":IN.3", 0x04, 1)
	elseif (piece == "r") then	send_input(":IN.2", 0x04, 1)
	elseif (piece == "b") then	send_input(":IN.1", 0x04, 1)
	elseif (piece == "n") then	send_input(":IN.1", 0x02, 1)
	end
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		send_input(":IN.0", 0x04, 1) -- Enter
	end
end

return interface
