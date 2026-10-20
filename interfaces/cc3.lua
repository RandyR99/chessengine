interface = {}

interface.turn = true
interface.invert = false
interface.last_get = nil
interface.edit = false
interface.history = {}
interface.level = 1
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Fidelity Chess Challenger 3"
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == interface.level) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	-- the level can only be chosen right after RE: CL steps 1 -> 2 -> 3
	send_input(":RESET", 0x01, 0.5) -- RE
	emu.wait(0.5)
	for i = 1, interface.level - 1 do
		send_input(":IN.1", 0x04, 0.5) -- CL
		emu.wait(0.5)
	end
	interface.cur_level = interface.level
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	interface.turn = true
	interface.invert = false
	interface.last_get = nil
	interface.cur_level = nil
	interface.setlevel()
end

function interface.start_play(init)
	if (init) then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		interface.invert = true
		interface.turn = false
		send_input(":IN.1", 0x02, 0.5) -- DM
		emu.wait(0.5)
		send_input(":IN.1", 0x02, 0.5) -- DM
		emu.wait(0.5)
		send_input(":IN.1", 0x01, 0.5) -- EN
		emu.wait(0.5)
		machine.video.throttled = throttled_state
	end
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x6f, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	
	local d0 = output_value("digit0")
	local d1 = output_value("digit1")
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	
	if (d0 == 0x3f and d1 == 0x3f and d2 == 0x3f and d3 == 0x00) then -- "000 ", computer castles queenside
		return (interface.invert and y == 1 and (x == 5 or x == 7)) or (not interface.invert and y == 8 and (x == 5 or x == 3))
	end
	if (d0 == 0x3f and d1 == 0x3f and d2 == 0x00 and d3 == 0x00) then -- "00  ", computer castles kingside
		return (interface.invert and y == 1 and (x == 5 or x == 3)) or (not interface.invert and y == 8 and (x == 5 or x == 7))
	end
	if (interface.invert) then
		x = 9 - x
		y = 9 - y
	end
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if (interface.invert) then
		p = 9 - p
	end
	if     (p == 1)	then send_input(":IN.0", 0x80, 0.5)
	elseif (p == 2)	then send_input(":IN.0", 0x40, 0.5)
	elseif (p == 3)	then send_input(":IN.0", 0x20, 0.5)
	elseif (p == 4)	then send_input(":IN.0", 0x10, 0.5)
	elseif (p == 5)	then send_input(":IN.0", 0x08, 0.5)
	elseif (p == 6)	then send_input(":IN.0", 0x04, 0.5)
	elseif (p == 7)	then send_input(":IN.0", 0x02, 0.5)
	elseif (p == 8)	then send_input(":IN.0", 0x01, 0.5)
	end
end

function interface.send_pos_full(x, y)
	interface.send_pos(x)
	interface.send_pos(y)
end

local function enter_move(m, special)
	-- special = DM entry: the machine takes the move without answering it
	local x, y = m.tx, m.ty
	local dy
	if (m.type == "castling" or m.type == "en_passant") then
		send_input(":IN.1", 0x02, 0.5) -- DM
		if (m.type == "en_passant") then
			dy = y
			y = m.fy
		end
	elseif (special) then
		send_input(":IN.1", 0x02, 0.5) -- DM
	end
	interface.send_pos_full(m.fx, m.fy)
	interface.send_pos_full(x, y)
	send_input(":IN.1", 0x01, 0.5) -- EN

	-- special moves require extra steps
	if (m.type == "castling" or m.type == "en_passant") then
		if (special) then
			send_input(":IN.1", 0x02, 0.5) -- DM
		end
		if (m.type == "castling" and x == 7) then
			interface.send_pos_full(8, y)
			interface.send_pos_full(6, y)
		elseif (m.type == "castling" and x == 3) then
			interface.send_pos_full(1, y)
			interface.send_pos_full(4, y)
		else
			interface.send_pos_full(x, y)
			interface.send_pos_full(x, dy)
		end
		send_input(":IN.1", 0x01, 0.5) -- EN
	end
end

-- the machine's move as shown on the display, in the machine's own squares
local function read_move()
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x6f, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local function index(t, v)
		for i = 1, 8 do
			if (t[i] == v) then
				return i
			end
		end
	end
	local fx, fy = index(xval, output_value("digit0")), index(yval, output_value("digit1"))
	local tx, ty = index(xval, output_value("digit2")), index(yval, output_value("digit3"))
	if (fx and fy and tx and ty) then
		return fx .. fy .. tx .. ty
	end
end

local function wait_reply(entered)
	local last, since = nil, 0
	for i = 1, 3000 do
		emu.wait(0.1)
		local m = read_move()
		if (m ~= nil and m ~= entered) then
			if (m == last) then
				since = since + 1
				if (since >= 10) then
					return m
				end
			else
				last, since = m, 0
			end
		end
	end
end

local function press_raw(p)
	send_input(":IN.0", 0x80 >> (p - 1), 0.5)
end

function interface.edit_game(on)
	interface.edit = on
	if (on) then
		interface.history = {}
		return
	end
	local hist = interface.history
	local n = #hist
	if (n == 0) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.cur_level = nil
	interface.setlevel() -- RE, the level is kept
	interface.invert = (n % 2 == 0) -- the machine moves next: White after an even number of moves
	local first, entered = 1, nil
	if (interface.invert) then
		send_input(":IN.1", 0x02, 0.5) -- DM
		emu.wait(0.5)
		send_input(":IN.1", 0x02, 0.5) -- DM: CC L, the machine has the light pieces
		emu.wait(0.5)
		send_input(":IN.1", 0x01, 0.5) -- EN, the machine plays a first move
	else
		enter_move(hist[1], false)
		first = 2
		local m = hist[1]
		entered = m.fx .. m.fy .. m.tx .. m.ty
	end
	if (n > 1 or interface.invert) then
		-- take back the machine's own move with a DM entry, then enter the history
		local r = wait_reply(entered)
		if (r ~= nil) then
			send_input(":IN.1", 0x02, 0.5) -- DM
			press_raw(tonumber(r:sub(3, 3)))
			press_raw(tonumber(r:sub(4, 4)))
			press_raw(tonumber(r:sub(1, 1)))
			press_raw(tonumber(r:sub(2, 2)))
			send_input(":IN.1", 0x01, 0.5) -- EN
		end
		for i = first, n - 1 do
			enter_move(hist[i], true)
		end
		enter_move(hist[n], false)
	end
	interface.turn = false
	interface.last_get = nil
	machine.video.throttled = throttled_state
end

function interface.select_piece(x, y, event)
	if (interface.edit) then
		if (event == "get") then
			interface.last_get = {x=x, y=y}
		elseif (event == "put") then
			local g = interface.last_get
			interface.history[#interface.history + 1] = { fx = g.x, fy = g.y, tx = x, ty = y, type = get_move_type(g.x, g.y, x, y) }
			interface.last_get = nil
		end
	elseif (event == "get" and interface.turn) then
		interface.last_get = {x=x, y=y}
	elseif (event == "put" and interface.turn) then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		local g = interface.last_get
		enter_move({ fx = g.x, fy = g.y, tx = x, ty = y, type = get_move_type(g.x, g.y, x, y) }, false)
		interface.last_get = nil
		machine.video.throttled = throttled_state
	end
	if (event == "put" and not interface.edit) then
		interface.turn = not interface.turn
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "3" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 3) then
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

