interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function led_on(name)
	local led = machine.devices[":"]:output(name)
	return led ~= nil and led:get() ~= 0
end

interface.level = 1
interface.cur_level = nil
interface.edit = false

function interface.get_module()
	return "Chess King Triomphe"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	repeat
		send_input(":IN.1", 0x08, 0.5) -- Level
		local cur_level = 0
		for y = 0, 7 do
			if led_on("1." .. y) then
				cur_level = cur_level + 1
			end
		end
	until cur_level == interface.level
end

function interface.setup_machine()
	sb_reset_board(":board")
	send_input(":IN.1", 0x10, 0.5) -- New Game

	interface.cur_level = 1
	interface.setlevel()
end

function interface.edit_game(on)
	-- manual section 8: playing both sides, TAKE BACK cancels the computer's reply
	interface.edit = on
end

function interface.start_play(init)
	send_input(":IN.1", 0x02, 0.5) -- Move
end

function interface.is_selected(x, y)
	local xval = led_on("0." .. (x - 1))
	local yval = led_on("1." .. (y - 1))
	return xval and yval
end

function interface.select_piece(x, y, event)
	if (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		sb_select_piece(":board", 0.5, x, y, event)
		if (interface.edit and event == "put") then
			-- the keys are ignored until the computer announces its reply (a file led lights up)
			local t = 0
			repeat
				emu.wait(0.1)
				t = t + 0.1
				local announced = false
				for x = 0, 7 do
					if led_on("0." .. x) then
						announced = true
					end
				end
			until announced or t > 60
			send_input(":IN.1", 0x04, 0.5) -- Take Back
		end
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "8" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 8) then
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
	sb_promote(":board", x, y, "q")
end

return interface
