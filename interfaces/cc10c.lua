interface = {}
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.turn = true
interface.invert = false
interface.edit = false
interface.stm = 1
interface.pending = false
interface.last_get = nil
interface.level = 1
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Fidelity Chess Challenger 10 C"
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
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	-- CL steps through the levels, digit3 shows the level number
	for i = 1, 20 do
		send_input(":IN.1", 0x04, 0.5) -- CL
		emu.wait(0.2)
		if (output_value("digit3") == lcd_num[interface.level]) then
			break
		end
	end
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	interface.turn = true
	interface.invert = false
	interface.edit = false
	interface.stm = 1
	interface.pending = false
	send_input(":RESET", 0x01, 0.5) -- RE
	emu.wait(1.0)

	interface.cur_level = 1
	interface.setlevel()
end

-- piece in the machine's frame: with invert the machine plays White from the top (ranks mirrored)
local function frame_piece(x, y)
	if (interface.invert) then
		y = 9 - y
	end
	return get_piece_id(x, y)
end

-- does the player's piece p (board id, any sign) on fx,fy attack tx,ty? player pawns move up the board
local function attacks(p, fx, fy, tx, ty, occupied)
	local dx, dy = tx - fx, ty - fy
	local t = math.abs(p)
	if (t == 6) then
		return dy == 1 and math.abs(dx) == 1
	elseif (t == 5) then
		return (math.abs(dx) == 1 and math.abs(dy) == 2) or (math.abs(dx) == 2 and math.abs(dy) == 1)
	elseif (t == 1) then
		return math.max(math.abs(dx), math.abs(dy)) == 1
	end
	local straight = (dx == 0 or dy == 0)
	local diagonal = (math.abs(dx) == math.abs(dy))
	if (dx == 0 and dy == 0) or (t == 3 and not straight) or (t == 4 and not diagonal) or (t == 2 and not straight and not diagonal) then
		return false
	end
	local sx = dx == 0 and 0 or dx // math.abs(dx)
	local sy = dy == 0 and 0 or dy // math.abs(dy)
	local x, y = fx + sx, fy + sy
	while (x ~= tx or y ~= ty) do
		if (occupied(x, y)) then
			return false
		end
		x, y = x + sx, y + sy
	end
	return true
end

-- the machine only moves after a player move: find a player piece that can step onto its
-- square from an empty one without checking the machine's king (knights first, king last:
-- moving the king or a rook costs the player's castling)
local function find_trigger(mc)
	local kx, ky
	for y = 1, 8 do
		for x = 1, 8 do
			if (frame_piece(x, y) * mc == 1) then
				kx, ky = x, y
			end
		end
	end
	local steps = {
		[5] = { {1,2}, {2,1}, {2,-1}, {1,-2}, {-1,-2}, {-2,-1}, {-2,1}, {-1,2} },
		[4] = { {1,1}, {1,-1}, {-1,1}, {-1,-1} },
		[2] = { {0,1}, {0,-1}, {1,0}, {-1,0}, {1,1}, {1,-1}, {-1,1}, {-1,-1} },
		[6] = { {0,1} },
		[3] = { {0,1}, {0,-1}, {1,0}, {-1,0} },
		[1] = { {0,1}, {0,-1}, {1,0}, {-1,0}, {1,1}, {1,-1}, {-1,1}, {-1,-1} },
	}
	for _, t in ipairs({ 5, 4, 2, 6, 3, 1 }) do
		for y = 1, 8 do
			for x = 1, 8 do
				local p = frame_piece(x, y)
				if (p ~= 0 and p * mc < 0 and math.abs(p) == t) then
					for _, d in ipairs(steps[t]) do
						local fx, fy = x - d[1], y - d[2]
						if (fx >= 1 and fx <= 8 and fy >= 1 and fy <= 8 and frame_piece(fx, fy) == 0 and not (t == 6 and fy == 1)
						and (t ~= 1 or math.max(math.abs(fx - kx), math.abs(fy - ky)) > 1)) then
							local occupied = function(ox, oy)
								return (ox == fx and oy == fy) or (frame_piece(ox, oy) ~= 0 and not (ox == x and oy == y))
							end
							if (kx == nil or not attacks(p, fx, fy, kx, ky, occupied)) then
								return { fx = fx, fy = fy, x = x, y = y }
							end
						end
					end
				end
			end
		end
	end
	return nil
end

-- set up the plugin's board in Problem Mode with the machine (color mc) to move; the machine
-- only moves after a player move, so the player's move (or a trigger move) is entered last
local function sync(mc, move)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.invert = (mc == 1) -- the machine always plays the pieces moving down the board
	send_input(":RESET", 0x01, 0.5) -- RE
	emu.wait(1.0)
	interface.cur_level = 1
	interface.setlevel()
	-- Problem Mode: DM/PB twice right after RE, "Prob" shows and the board is empty
	send_input(":IN.1", 0x02, 0.5) -- DM/PB
	emu.wait(0.5)
	send_input(":IN.1", 0x02, 0.5) -- DM/PB
	emu.wait(0.5)
	local trig = nil
	if (move == nil) then
		trig = find_trigger(mc)
	end
	local code = { 3, 1, 8, 6, 4, 2 } -- K Q R B N P, the queen is 1 and the king 3 in Problem Mode
	for y = 1, 8 do
		for x = 1, 8 do
			local p = frame_piece(x, y)
			local px, py = x, y
			if (trig ~= nil and x == trig.x and y == trig.y) then
				px, py = trig.fx, trig.fy
			end
			if (p ~= 0) then
				interface.send_pos(px)
				interface.send_pos(py)
				if (p * mc < 0) then
					send_input(":IN.0", 0x08, 0.5) -- E: the player's piece
				end
				interface.send_pos(code[math.abs(p)])
				send_input(":IN.1", 0x01, 0.5) -- EN
			end
		end
	end
	send_input(":IN.1", 0x02, 0.5) -- DM/PB: leave Problem Mode
	emu.wait(0.5)
	if (move ~= nil) then
		local fy, ty = move.fy, move.ty
		if (interface.invert) then
			fy, ty = 9 - fy, 9 - ty
		end
		trig = { fx = move.fx, fy = fy, x = move.tx, y = ty }
	end
	if (trig ~= nil) then
		interface.send_pos(trig.fx)
		interface.send_pos(trig.fy)
		interface.send_pos(trig.x)
		interface.send_pos(trig.y)
		send_input(":IN.1", 0x01, 0.5) -- EN, the machine starts thinking
	end
	interface.pending = false
	interface.turn = false
	machine.video.throttled = throttled_state
end

function interface.set_pos(mode)
	-- the position is entered on the next player move or at go (sync)
	if (mode ~= 0) then
		interface.stm = mode
		interface.pending = true
	end
	return ""
end

function interface.edit_game(on)
	-- history moves are only tracked, the final position is set up like a FEN
	interface.edit = on
	if (not on) then
		interface.pending = true
	end
end

function interface.start_play(init)
	if (interface.pending) then
		sync(interface.stm, nil)
	elseif (init) then
		interface.turn = false
		send_input(":IN.1", 0x02, 0.5) -- DM/PB
		send_input(":IN.1", 0x01, 0.5) -- EN
	end
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x6f, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	if (interface.invert) then
		y = 9 - y
	end
	local d0 = output_value("digit0")
	local d1 = output_value("digit1")
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then	send_input(":IN.0", 0x80, 0.5)
	elseif (p == 2)	then	send_input(":IN.0", 0x40, 0.5)
	elseif (p == 3)	then	send_input(":IN.0", 0x20, 0.5)
	elseif (p == 4)	then	send_input(":IN.0", 0x10, 0.5)
	elseif (p == 5)	then	send_input(":IN.0", 0x08, 0.5)
	elseif (p == 6)	then	send_input(":IN.0", 0x04, 0.5)
	elseif (p == 7)	then	send_input(":IN.0", 0x02, 0.5)
	elseif (p == 8)	then	send_input(":IN.0", 0x01, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event == "get") then
		interface.last_get = {x=x, y=y}
	elseif (event == "put") then
		local g = interface.last_get
		if (interface.edit) then
			interface.turn = not interface.turn
		elseif (interface.pending) then
			sync(-interface.stm, { fx = g.x, fy = g.y, tx = x, ty = y })
		elseif (interface.turn) then
			local fy, ty = g.y, y
			if (interface.invert) then
				fy, ty = 9 - fy, 9 - ty
			end
			interface.send_pos(g.x)
			interface.send_pos(fy)
			interface.send_pos(x)
			interface.send_pos(ty)
			send_input(":IN.1", 0x01, 1) -- EN
			interface.turn = false
		else
			interface.turn = true
		end
		interface.stm = -interface.stm
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

