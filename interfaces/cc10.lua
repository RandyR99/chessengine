interface = {}

interface.invert = false
interface.turn = true
interface.level = 1
interface.cur_level = nil
interface.set = false
interface.edit = false
interface.stm = 1

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Fidelity Chess Challenger 10"
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local lcd_num = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67, 0x3f }
	-- LV steps through the levels, digit3 shows the level number
	for i = 1, 25 do
		send_input(":IN.0", 0x02, 0.5) -- LV
		emu.wait(0.2)
		if (output_value("digit3") == lcd_num[interface.level]) then
			break
		end
	end
	send_input(":IN.2", 0x01, 0.5) -- CL
end

function interface.setup_machine()
	interface.invert = false
	interface.turn = true
	send_input(":RESET", 0x01, 1)  -- RE
	emu.wait(1.0)
	interface.set = false
	interface.stm = 1

	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x01, 0.6) -- SPK
		return ("")
	else
		interface.invert=(mode==-1)
		interface.stm = mode
		send_input(":IN.2", 0x02, 0.6) -- PB
		for y=1,8 do
			for x=1,8 do
				send_input(":IN.3", 0x02, 0.6) -- PV
				local p=0
				if interface.invert then
					p=-get_piece_id(9-x,9-y)
				else
					p=get_piece_id(x,y)
				end
				if p~=0 then
					local n=math.abs(p)
					if     n==1 then send_input(":IN.2", 0x04, 0.6) -- K
					elseif n==2 then send_input(":IN.0", 0x04, 0.6) -- Q
					elseif n==3 then send_input(":IN.3", 0x08, 0.6) -- R
					elseif n==4 then send_input(":IN.1", 0x08, 0.6) -- B
					elseif n==5 then send_input(":IN.3", 0x04, 0.6) -- N
					elseif n==6 then send_input(":IN.1", 0x04, 0.6) -- P
					end
					if p>0 then
						send_input(":IN.3", 0x01, 0.6) -- EN
					end
				else
					-- avcc keeps the old position in Problem Mode: clear the square
					send_input(":IN.2", 0x01, 0.6) -- CL
				end
			end
		end
		send_input(":IN.2", 0x02, 0.6) -- PB
		send_input(":IN.1", 0x01, 0.6) -- SPK
		interface.set = true
	end
end

function interface.edit_game(on)
	-- history moves are only tracked, then the final position is set up
	interface.edit = on
	if (not on) then
		local stm = interface.stm
		interface.setup_machine()
		interface.set_pos(0)
		interface.set_pos(stm)
	end
end

function interface.start_play(init)
	if (init or interface.set) then
		interface.turn = false
		send_input(":IN.1", 0x02, 0.5) -- DM
		send_input(":IN.2", 0x02, 0.5) -- PB
		interface.set = false
	end
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x6f, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit0")
	local d1 = output_value("digit1")
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then	send_input(":IN.0", 0x04, 0.5)
	elseif (p == 2)	then	send_input(":IN.1", 0x04, 0.5)
	elseif (p == 3)	then	send_input(":IN.2", 0x04, 0.5)
	elseif (p == 4)	then	send_input(":IN.3", 0x04, 0.5)
	elseif (p == 5)	then	send_input(":IN.0", 0x08, 0.5)
	elseif (p == 6)	then	send_input(":IN.1", 0x08, 0.5)
	elseif (p == 7)	then	send_input(":IN.2", 0x08, 0.5)
	elseif (p == 8)	then	send_input(":IN.3", 0x08, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn and not interface.edit) then
			interface.send_pos(x)
			interface.send_pos(y)
		end

		if (event == "put") then
			if (interface.turn and not interface.edit) then
				send_input(":IN.3", 0x01, 1) -- EN
				interface.set = false
			end
			interface.turn = not interface.turn
			interface.stm = -interface.stm
		end
	end
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "10"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 10) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
end

return interface

