interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 1
interface.cur_level = nil
local throttled = true

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local level = interface.level
	local y = (level - 1) % 8 + 1
	local x = (level - y) / 8 + 1
	send_input(":IN.0", 0x04, 0.5) -- Set Level
	sb_press_square(":board", 1, x, y)
	send_input(":IN.1", 0x01, 0.5) -- Go
end

function interface.setup_machine()
	sb_reset_board(":board")
    send_input(":IN.1", 0x80, 0.5) -- New Game
	emu.wait(1)

	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x20, 0.5) -- Verify/Setup
		send_input(":IN.1", 0x20, 0.5) -- Verify/Setup
		send_input(":IN.1", 0x08, 0.5) -- Clear Board
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.1", 0x10, 0.5) -- Color
					end
					if math.abs(p)~=math.abs(piece) then
						send_input(":IN.0", 0x80>>(math.abs(p)-1), 0.5)
					end
					sb_press_square(":board", 1, x, 9-y)
					piece=p
				end
			end
		end
		send_input(":IN.1", 0x01, 0.5) -- Go
		if mode<0 then
			send_input(":IN.1", 0x10, 0.5) -- Color
		end
		send_input(":IN.0", 0x40, 0.5) -- Sound
		send_input(":IN.1", 0x08, 0.5) -- Clear
	end
end

function interface.edit_game()
	send_input(":IN.0", 0x80, 0.5) -- Referee
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.1", 0x01, 0.5) -- Go
end

function interface.is_selected(x, y)
	local xval = output_value("1." .. tostring(x - 1)) ~= 0
	local yval = output_value("0." .. tostring(8 - y)) ~= 0
	return xval and yval
end

-- the board needs a square held for more than 350 ms (MAME driver set_delay)
function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return { { "spin", "Level", "1", "1", "44"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 44) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.test_promotion(x, y)
	local map = {"s0.1","s1.1","s2.1","s3.0","s2.0","s0.0","s1.0"}
	local dig = 0x00

	local p
	throttled = machine.video.throttled
    machine.video.throttled = false

	send_input(":IN.1", 0x20, 0.5) -- Verify/Setup
	sb_press_square(":board", 1, x, y)
	for i=1,7 do
		if (output_value(map[i]) ~= 0) then
			dig = dig | (1 << (i-1))
		end
	end
	if     (dig == 0x67) then p = "Q"
	elseif (dig == 0x50) then p = "R"
	elseif (dig == 0x7c) then p = "B"
	elseif (dig == 0x54) then p = "N"
	else p = "Q"
	end
	send_input(":IN.1", 0x01, 0.5) -- Go

    machine.video.throttled = throttled
	return p
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.0", 0x40, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x20, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x10, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x08, 1)
	end
end

return interface
