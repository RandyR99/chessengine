interface = {}

interface.turn = true
interface.level = "a1"
interface.cur_level = nil
interface.edit = false

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Mephisto Ix"
end

function interface.get_author()
	return "Thomas Nitsche & Elmar Henne"
end

function interface.setdigit(n)
	if     (n == 0)	then send_input(":IN.3", 0x01, 0.5)
	elseif (n == 1)	then send_input(":IN.0", 0x02, 0.5)
	elseif (n == 2)	then send_input(":IN.0", 0x08, 0.5)
	elseif (n == 3)	then send_input(":IN.1", 0x02, 0.5)
	elseif (n == 4)	then send_input(":IN.1", 0x08, 0.5)
	elseif (n == 5)	then send_input(":IN.2", 0x02, 0.5)
	elseif (n == 6)	then send_input(":IN.2", 0x08, 0.5)
	elseif (n == 7)	then send_input(":IN.3", 0x02, 0.5)
	elseif (n == 8)	then send_input(":IN.3", 0x08, 0.5)
	elseif (n == 9)	then send_input(":IN.2", 0x04, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	send_input(":IN.1", 0x04, 0.5) -- LEV
	interface.send_pos(x)
	interface.send_pos(y)
	send_input(":IN.0", 0x04, 0.5) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	send_input(":RESET", 0x01, 0.5)  -- RES
	emu.wait(1)
	send_input(":IN.0", 0x01, 0.5) -- CL
	machine.video.throttled = throttled_state
	interface.cur_level = "a1"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.2", 0x01, 0.5) -- LIST
		send_input(":IN.3", 0x04, 0.5) -- REV
		machine.video.throttled = throttled_state
		return ("")
	else
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p > 0 then
						interface.setdigit(0) -- White
					else
						interface.setdigit(9) -- Black
					end
					interface.setdigit(8 - math.abs(p))
					interface.setdigit(x)
					interface.setdigit(9 - y)
					send_input(":IN.0", 0x04, 0.5) -- ENT
				end
			end
		end
		if mode == 1 then
			interface.setdigit(0) -- White
		else
			interface.setdigit(9) -- Black
		end
		send_input(":IN.0", 0x04, 0.5) -- ENT
		send_input(":IN.0", 0x01, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	interface.edit = on
end

function interface.start_play(init)
	interface.turn = false
	send_input(":IN.1", 0x01, 0.5) -- STA
end

function interface.stop_play()
	send_input(":IN.0", 0x04, 0.5) -- ENT
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit3") & 0x7f
	local d1 = output_value("digit2") & 0x7f
	local d2 = output_value("digit1") & 0x7f
	local d3 = output_value("digit0") & 0x7f
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then send_input(":IN.0", 0x02, 0.5)
	elseif (p == 2)	then send_input(":IN.0", 0x08, 0.5)
	elseif (p == 3)	then send_input(":IN.1", 0x02, 0.5)
	elseif (p == 4)	then send_input(":IN.1", 0x08, 0.5)
	elseif (p == 5)	then send_input(":IN.2", 0x02, 0.5)
	elseif (p == 6)	then send_input(":IN.2", 0x08, 0.5)
	elseif (p == 7)	then send_input(":IN.3", 0x02, 0.5)
	elseif (p == 8)	then send_input(":IN.3", 0x08, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		if (interface.turn) then
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "put") then
			if interface.edit == true then
				send_input(":IN.0", 0x04, 0.5) -- ENT
			else
				if (interface.turn) then
					send_input(":IN.1", 0x01, 1) -- STA
				end
				interface.turn = not interface.turn
			end
		end
		machine.video.throttled = throttled_state
	end
end

function interface.get_options()
	return {
		{ "string", "Level", "a1" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if (level:match("^[a-h][1-8]$")) then
			interface.level = level
			interface.setlevel()
		end
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
