interface = {}
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.turn = true
interface.selected = {}
interface.selected_cnt = 0
interface.level = 1
interface.cur_level = nil
local lastx = 1
local lasty = 1
local inity = 1
interface.edit = false

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "SciSys Executive Chess"
end

function interface.get_author()
	return "Frans Morsch"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local btag = { 35, 27, 31, 57, 54, 52, 49, 47 }
	local cur_level = 0
	send_input(":IN.1", 0x80, 0.5) -- 2nd F
	send_input(":IN.2", 0x10, 0.5) -- LEVEL
	emu.wait(1)
	for y = 1, 8 do
		if (output_value("1." .. tostring(btag[y])) ~= 0) then
			cur_level = cur_level + 1
		end
	end
	local k = interface.level - cur_level
	if (k > 4) then
		k = k - 8
	elseif (k < -4) then
		k = k + 8
	end
	for i = 1, math.abs(k) do
		if (k > 0) then
			send_input(":IN.2", 0x02, 0.5) -- up
		else
			send_input(":IN.2", 0x08, 0.5) -- down
		end
	end
	send_input(":IN.0", 0x08, 0.5) -- ENTER
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	interface.turn = true
	interface.selected = {}
	interface.selected_cnt = 0
	inity = 1
	machine:soft_reset()
	emu.wait(1)
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.1", 0x80, 0.6) -- 2nd F/HOME
		send_input(":IN.1", 0x40, 0.6) -- NEW GAME/CB
		machine.video.throttled = throttled_state
		return ("")
	else
		local x0, y0
		local piece = 0
		for y = 1, 8 do
			send_input(":IN.2", 0x08, 0.6) -- down
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p == 0 then
					x0 = x
					y0 = 9 - y
					send_input(":IN.2", 0x04, 0.6) -- right
				else
					send_input(":IN.1", 0x80, 0.6) -- 2nd F/HOME
					for i = 1, 7 - math.abs(p) do
						if p > 0 then
							send_input(":IN.2", 0x01, 0.6) -- White
						else
							send_input(":IN.2", 0x04, 0.6) -- Black
						end
					end
					send_input(":IN.0", 0x08, 0.6) -- ENTER
					piece = p
				end
			end
		end
		if mode * piece < 0 then
			for i = 1, x0 - 1 do
				send_input(":IN.2", 0x04, 0.6) -- right
			end
			for i = 1, y0 - 1 do
				send_input(":IN.2", 0x02, 0.6) -- up
			end
			send_input(":IN.1", 0x80, 0.6) -- 2nd F/HOME
			for i = 1, 7 do
				if mode == 1 then
					send_input(":IN.2", 0x01, 0.6) -- White
				else
					send_input(":IN.2", 0x04, 0.6) -- Black
				end
			end
			send_input(":IN.0", 0x08, 0.6) -- ENTER
		end
		if mode == 1 then
			inity = 1
		else
			inity = 8
		end
		send_input(":IN.1", 0x80, 0.6) -- 2nd F/HOME
		send_input(":IN.1", 0x80, 0.6) -- 2nd F/HOME
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x80, 0.5) -- 2nd F
	send_input(":IN.2", 0x80, 0.5) -- MM/dr
	interface.edit = on
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = false
	inity = 9 - inity
	send_input(":IN.1", 0x80, 0.5) -- 2nd F
	send_input(":IN.2", 0x02, 0.5) -- MOVE
	machine.video.throttled = throttled_state
end

function interface.stop_play()
end

function interface.is_pos_selected(x, y, piece)
	local piece_id = get_piece_id(x, y)
	local selected = (piece_id == 0 and piece ~= 0) or (piece_id > 0 and piece <= 0) or (piece_id < 0 and piece >= 0)
	if (selected) then
		interface.selected[y * 10 + x] = piece_id
	end

	-- ignore the rook in castling
	if     (y == 1 and (x == 8 or x == 6) and (interface.selected[1*10+5] ==  1 and interface.selected[1*10+7] == 0 and interface.selected[1*10+8] ==  3)) then	return false	-- white kingside castling
	elseif (y == 1 and (x == 1 or x == 4) and (interface.selected[1*10+5] ==  1 and interface.selected[1*10+3] == 0 and interface.selected[1*10+1] ==  3)) then	return false	-- white queenside castling
	elseif (y == 8 and (x == 8 or x == 6) and (interface.selected[8*10+5] == -1 and interface.selected[8*10+7] == 0 and interface.selected[8*10+8] == -3)) then	return false	-- black kingside castling
	elseif (y == 8 and (x == 1 or x == 4) and (interface.selected[8*10+5] == -1 and interface.selected[8*10+3] == 0 and interface.selected[8*10+1] == -3)) then	return false	-- black queenside castling

	-- ignore en-passant capture
	elseif (y == 5 and x < 8 and piece_id == -6 and interface.selected[(y+1)*10+x] == 0 and interface.selected[y*10+(x+1)] ==  6) then	return false	-- white en passant
	elseif (y == 5 and x > 1 and piece_id == -6 and interface.selected[(y+1)*10+x] == 0 and interface.selected[y*10+(x-1)] ==  6) then	return false	-- white en passant
	elseif (y == 4 and x < 8 and piece_id ==  6 and interface.selected[(y-1)*10+x] == 0 and interface.selected[y*10+(x+1)] == -6) then	return false	-- black en passant
	elseif (y == 4 and x > 1 and piece_id ==  6 and interface.selected[(y-1)*10+x] == 0 and interface.selected[y*10+(x-1)] == -6) then	return false	-- black en passant
	end
	if (x == 1 and y == 1) then
		interface.selected_cnt = interface.selected_cnt + 1
	end
	if (interface.selected_cnt >= 25) then
		interface.selected_cnt = 0
		interface.selected = {}
	end

	-- wait complete scan before report selections
	if (interface.selected_cnt <= 3) then
		return false
	end
	return selected
end

function interface.is_selected(x, y)
	if (output_value("3.12") ~= 0) then -- COMP?
		return false
	end
	local xtag = { 1, 4, 0, 5, 2, 6, 3, 7 }
	local btag = { 35, 27, 31, 57, 54, 52, 49, 47 }
	local wtag = { 13,  9, 16,  6, 19,  3, 22,  0 }
	local piece = 0
	if (output_value(xtag[x] .. "." .. tostring(btag[y])) ~= 0) then
		piece = -1
	elseif (output_value(xtag[x] .. "." .. tostring(wtag[y])) ~= 0) then
		piece = 1
	end
	return interface.is_pos_selected(x, y, piece)
end

function interface.select_piece(x, y, event)
	if (interface.turn or interface.edit) then
		if (event == "get" or event == "put") then
			local throttled_state = machine.video.throttled
			machine.video.throttled = false
			if (event == "get") then
				lastx = 1
				lasty = inity
			end
			local k = x - lastx
			if (k > 4) then
				k = k - 8
			elseif (k < -4) then
				k = k + 8
			end
			for i = 1, math.abs(k) do
				if (k > 0) then
					send_input(":IN.2", 0x04, 0.5) -- right
				else
					send_input(":IN.2", 0x01, 0.5) -- left
				end
			end
			k = y - lasty
			if (k > 4) then
				k = k - 8
			elseif (k < -4) then
				k = k + 8
			end
			for i = 1, math.abs(k) do
				if (k > 0) then
					send_input(":IN.2", 0x02, 0.5) -- up
				else
					send_input(":IN.2", 0x08, 0.5) -- down
				end
			end
			send_input(":IN.0", 0x08, 0.5) -- ENTER
			if (event == "get") then
				lastx = x
				lasty = y
			end
			machine.video.throttled = throttled_state
		end
	end
	if (event == "put") then
		if (interface.edit) then
			inity = 9 - inity
		else
			interface.turn = not interface.turn
		end
		interface.selected = {}
		interface.selected_cnt = 0
		emu.wait(1)
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
	local xval = { 1, 4, 0, 5, 2, 6, 3, 7 }
	local z = tostring(xval[x]) .. "."
	if     (y == 1 and output_value(z.."33") ~= 0) or (y == 8 and output_value(z.."46") ~= 0) then return 'q'
	elseif (y == 1 and output_value(z.."10") ~= 0) or (y == 8 and output_value(z.."24") ~= 0) then return 'r'
	elseif (y == 1 and output_value(z.."14") ~= 0) or (y == 8 and output_value(z.."25") ~= 0) then return 'b'
	elseif (y == 1 and output_value(z.."34") ~= 0) or (y == 8 and output_value(z.."45") ~= 0) then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	-- nothing to press: a queen is assumed
end

return interface
