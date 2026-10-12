interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.turn = true
interface.level = 1
interface.cur_level = nil
interface.prom=false

function interface.setlevel()
	interface.cur_level = interface.level
	send_input(":IN.2", 0x04, 1) -- St (Clear)
	send_input(":IN.2", 0x02, 1) -- A (View)
	interface.send_pos(interface.level)
	send_input(":IN.2", 0x04, 1) -- St (Clear)
end

function interface.setup_machine()
	interface.turn = true
	emu.wait(1.0)

	interface.cur_level = 1
	interface.setlevel()
end

function interface.start_play(init)
	interface.turn = false
	send_input(":IN.2", 0x08, 1) -- Z (Enter)
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit6")
	local d1 = output_value("digit5")
	local d2 = output_value("digit4")
	local d3 = output_value("digit3")
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then	send_input(":IN.0", 0x08, 0.5)
	elseif (p == 2)	then	send_input(":IN.0", 0x04, 0.5)
	elseif (p == 3)	then	send_input(":IN.0", 0x02, 0.5)
	elseif (p == 4)	then	send_input(":IN.0", 0x01, 0.5)
	elseif (p == 5)	then	send_input(":IN.1", 0x01, 0.5)
	elseif (p == 6)	then	send_input(":IN.1", 0x02, 0.5)
	elseif (p == 7)	then	send_input(":IN.1", 0x04, 0.5)
	elseif (p == 8)	then	send_input(":IN.1", 0x08, 0.5)
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
				send_input(":IN.2", 0x08, 1)
			end
			interface.turn = not interface.turn
		end
	end
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "8"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		value = value:gsub("_", " ")
		local level = tonumber(value)
		if (level < 1 or level> 8) then
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
	-- TODO
end

return interface
