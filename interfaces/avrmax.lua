interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.turn = true
interface.level = 3
interface.cur_level = nil

function interface.send_click(port, value)
	send_input(port, value, 0.2)
	emu.wait(0.5)
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local level = interface.level
	interface.send_click(":IN.0", 0x04) -- FN
	interface.send_click(":IN.1", 0x01) -- 2
	if (level == 0) then interface.send_click(":IN.1", 0x04)     -- CL
	elseif (level == 9) then interface.send_click(":IN.0", 0x04) -- FN
	else interface.send_pos(level)
	end
	emu.wait(0.5)
	interface.send_click(":IN.2", 0x04) -- GO
end

function interface.setup_machine()
	interface.turn = true
    interface.send_click(":IN.0", 0x04) -- FN
    interface.send_click(":IN.0", 0x01) -- 1
    interface.send_click(":IN.1", 0x04) -- CL
	emu.wait(0.5)

	interface.cur_level = 3
	interface.setlevel()
end

function interface.start_play(init)
	interface.turn = false
	if (init) then
		interface.send_click(":IN.1", 0x04) -- CL
	end
	interface.send_click(":IN.2", 0x04) -- GO
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit0")
	local d1 = output_value("digit1")
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then	interface.send_click(":IN.0", 0x01)
	elseif (p == 2)	then	interface.send_click(":IN.1", 0x01)
	elseif (p == 3)	then	interface.send_click(":IN.2", 0x01)
	elseif (p == 4)	then	interface.send_click(":IN.3", 0x01)
	elseif (p == 5)	then	interface.send_click(":IN.0", 0x02)
	elseif (p == 6)	then	interface.send_click(":IN.1", 0x02)
	elseif (p == 7)	then	interface.send_click(":IN.2", 0x02)
	elseif (p == 8)	then	interface.send_click(":IN.3", 0x02)
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
				interface.send_click(":IN.2", 0x04) -- GO
				emu.wait(0.5)
				interface.send_click(":IN.2", 0x04) -- GO
			end
			interface.turn = not interface.turn
		end
	end
end

function interface.get_options()
	return { { "spin", "Level", "3", "0", "9"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 0 or level > 9) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- TODO
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	-- TODO
end

return interface
