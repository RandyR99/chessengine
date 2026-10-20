interface = {}

interface.level = "a5"
interface.cur_level = nil
interface.edit = false

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	send_input(":IN.1", 0x02, 0.5) -- Level
	sb_press_square(":board", 0.5, x, y)
	send_input(":IN.1", 0x02, 0.5) -- Level
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(5)
	send_input(":IN.1", 0x01, 0.5)	-- New Game
	emu.wait(1.5)
	interface.cur_level = "a5"
	interface.setlevel()
	machine.video.throttled = throttled_state
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.1", 0x04, 0.5)	-- Set Up
		send_input(":IN.1", 0x01, 0.5)	-- New Game
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.1", 0x10, 0.5) -- Change Color
					end
					if math.abs(p)~=math.abs(piece) then
						send_input(":IN.0", 0x40>>math.abs(p), 0.5)
					end
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.1", 0x10, 0.5) -- Change Color
		end
		send_input(":IN.1", 0x04, 0.5)	-- Set Up
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	send_input(":IN.1", 0x08, 0.5)	-- Multimove
end

function interface.start_play(init)
	send_input(":IN.0", 0x40, 0.5)	-- Play
end

function interface.is_selected(x, y)
	local xval = output_value("2." .. tostring(x - 1)) ~= 0
	local yval = output_value("0." .. tostring(y - 1)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return { { "string", "Level", "a5"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if (level:match("[a-h][1-8]")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.test_promotion(x, y)
	local function piece_led(port, code, x, y)
		send_input(port, code, 0.5)
		emu.wait(0.5)
		return (output_value("0." .. (y - 1)) == 0)
	end

	local p

	if     piece_led(":IN.0", 0x10, x, y) then p = "Q"
	elseif piece_led(":IN.0", 0x02, x, y) then p = "N"
	elseif piece_led(":IN.0", 0x04, x, y) then p = "B"
	elseif piece_led(":IN.0", 0x08, x, y) then p = "R"
	else p = "Q"
	end

	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	emu.wait(0.5)
	if     (piece == "q") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x08, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x04, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x02, 1)
	end
end

return interface
