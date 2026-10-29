interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.level = "a4"
interface.cur_level = nil
local throttled = true

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local clev = interface.cur_level
	local level = interface.level
	interface.cur_level = interface.level
	local cols_idx = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8}
	clev = 8*(cols_idx[clev:sub(1, 1)]-1)+tonumber(clev:sub(2, 2))
	level = 8*(cols_idx[level:sub(1, 1)]-1)+tonumber(level:sub(2, 2))

	throttled = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x40, 0.5) -- Level
	if level < clev then
		level = level + 64
	end
	while clev + 8 <= level do
		send_input(":IN.1", 0x80, 0.5) -- Color
		clev = clev + 8
	end
	for i=1,level-clev do
		send_input(":IN.1", 0x40, 0.5) -- Level
	end
	send_input(":IN.0", 0x20, 0.5) -- Set Up
	send_input(":IN.0", 0x20, 0.5) -- Set Up
	machine.video.throttled = throttled
end

function interface.setup_machine()
	sb_reset_board(":board")
--	send_input(":IN.1", 0x20, 0.5) -- New Game
	emu.wait(4)

	interface.cur_level = "a4"
	interface.setlevel()
end

function interface.start_play(init)
	send_input(":IN.0", 0x02, 0.5) -- Play
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x04, 0.5) -- K
	elseif (n == 2) then send_input(":IN.1", 0x04, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.1", 0x10, 0.5) -- R
	elseif (n == 4) then send_input(":IN.0", 0x10, 0.5) -- B
	elseif (n == 5) then send_input(":IN.1", 0x08, 0.5) -- N
	elseif (n == 6) then send_input(":IN.0", 0x08, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x20, 0.5) -- Set Up
		send_input(":IN.1", 0x20, 0.5) -- New Game
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.1", 0x80, 0.5) -- Color
					end
					setpiece(math.abs(p))
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.1", 0x80, 0.5) -- Color
		end
		send_input(":IN.0", 0x20, 0.5) -- Set Up
	end
end

function interface.edit_game()
	send_input(":IN.0", 0x01, 0.5) -- Non Auto
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
	return {{"string", "Level", "a4"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if level:match("^[a-h][1-8]$") then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.test_promotion(x, y)
	local function led_off(port, code, x, y)
		send_input(port, code, 0.5)
		emu.wait(0.5)
		return not interface.is_selected(x, y)
	end

	local p
	throttled = machine.video.throttled
	machine.video.throttled = false

	if     led_off(":IN.1", 0x04, x, y) then p = "Q"
	elseif led_off(":IN.1", 0x10, x, y) then p = "R"
	elseif led_off(":IN.0", 0x10, x, y) then p = "B"
	elseif led_off(":IN.1", 0x08, x, y) then p = "N"
	else p = "Q"
	end

	machine.video.throttled = throttled
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	if     (piece == "q") then send_input(":IN.1", 0x04, 0.5)
	elseif (piece == "r") then send_input(":IN.1", 0x10, 0.5)
	elseif (piece == "b") then send_input(":IN.0", 0x10, 0.5)
	elseif (piece == "n") then send_input(":IN.1", 0x08, 0.5)
	end
	sb_promote(":board", x, y, piece)
end

return interface
