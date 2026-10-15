interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = "a1"
interface.cur_level = nil

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8}
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))

	send_input(":IN.1", 0x20, 0.5) -- Set Level
	sb_press_square(":board", 0.5, x, y)
	send_input(":IN.1", 0x01, 0.5) -- Go
end

function interface.setup_machine()
	sb_reset_board(":board")
--	send_input(":IN.1", 0x80, 0.5) -- New Game
	emu.wait(1)

	interface.cur_level = "a1"
	interface.setlevel()
end

function interface.start_play(init)
	send_input(":IN.1", 0x01, 0.5) -- Go
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x04, 0.5) -- K
	elseif (n == 2) then send_input(":IN.0", 0x08, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x10, 0.5) -- R
	elseif (n == 4) then send_input(":IN.0", 0x20, 0.5) -- B
	elseif (n == 5) then send_input(":IN.0", 0x40, 0.5) -- N
	elseif (n == 6) then send_input(":IN.0", 0x80, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.1", 0x04, 0.5) -- Set Up
		send_input(":IN.1", 0x04, 0.5) -- Set Up
		send_input(":IN.1", 0x40, 0.5) -- Clear Board
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.0", 0x01, 0.5) -- Change Color
					end
					if math.abs(p)~=math.abs(piece) then
						setpiece(math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.0", 0x01, 0.5) -- Change Color
		end
		send_input(":IN.1", 0x01, 0.5) -- Go
	end
end

function interface.edit_game()
	send_input(":IN.0", 0x80, 0.5) -- Referee
	send_input(":IN.0", 0x80, 0.5) -- Referee
	emu.wait(0.5)
end

function interface.is_selected(x, y)
	local xval = output_value("1." .. (x - 1)) ~= 0
	local yval = output_value("0." .. (y - 1)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return {{"string", "Level", "a1"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if level:match("^[a-g][1-8]$") then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.test_promotion(x, y)
	send_input(":IN.1", 0x04, 0.5) -- Verify
	sb_press_square(":board", 0.5, x, y)
	local piece
	local p = output_value("digit0")
	if     (p == 0x67) then piece = "Q"
	elseif (p == 0x50) then piece = "R"
	elseif (p == 0x7c) then piece = "B"
	elseif (p == 0x54) then piece = "N"
	else piece = "Q"
	end
	send_input(":IN.1", 0x01, 0.5) -- Go
	return piece
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x08, 0.5)
	elseif (piece == "r") then send_input(":IN.0", 0x10, 0.5)
	elseif (piece == "b") then send_input(":IN.0", 0x20, 0.5)
	elseif (piece == "n") then send_input(":IN.0", 0x40, 0.5)
	end
	sb_promote(":board", x, y, piece)
end

return interface
