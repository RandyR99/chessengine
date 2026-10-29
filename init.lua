local exports = {}
exports.name = "chessengine"
exports.version = "2026.09.01"
exports.description = "Chess UCI/XBoard Interface plugin"
exports.license = "The BSD 3-Clause License"
exports.author = { name = "Sandro Ronco, Franz Huber & Randy Reade" }

local frskip = 10
local ticker = 0

-- popup error message for unsupported underpromotions:
local prom_check = true

-- random start delay (0-1 sec) to avoid many duplicate games in engine matches:
local rand_delay = 1

-- max. random delay (sec) before sending a move to the engine:
local move_delay = 0

local wbgui = false
local module = ""
local editmode = 0
local setupmode = 0
local edit_num = 0
local loop_num = 0
local lastpos = "position startpos moves"

local plugin_path = ""
local protocol = ""
local co = nil
local conth = nil
local quitting = false
local interface = nil
local board = nil
local game_started = false
local sel_started = false
local piece_get = false
local my_color = "B"
local ply = "W"
local piece_from = nil
local piece_to = nil
local prev_move = nil
local moved_since_position = false -- the machine sent a bestmove after the last "position" command
local game_over_sent = false -- "bestmove 0000" was sent for the machine's resignation or draw claim
local pos_count = {}         -- occurrences of each position (board + side to move) in this game, for threefold repetition
local turn_since = nil       -- emulated time when the machine's current turn began
local max_think = 0          -- the machine's longest move in this game (emulated seconds)
local scr = [[
  while true do
    _G.status = io.stdin:read("*line")
    if _G.status == nil then
      return "" -- stdin closed: end the thread
    end
    yield()
    if _G.status == "quit" then
      return "" -- a finished thread lets MAME exit
    end
  end
]]

local function describe_system()
  return manager.machine.system.description
end

local function board_reset()
  local throttle_state = manager.machine.video.throttled
  if manager.machine.system.name ~= 'ivant' and
       manager.machine.system.name ~= 'igor' and
       manager.machine.system.name ~= 'chessac' and
       manager.machine.system.name ~= 'schachak' and
       manager.machine.system.name ~= 'vcc' and
       manager.machine.system.name ~= 'vsc' and
       manager.machine.system.name ~= 'csc' and
       manager.machine.system.name ~= 'csce' and
       manager.machine.system.name ~= 'ccmk2' and
       manager.machine.system.name ~= 'ccmk2a' and
       manager.machine.system.name ~= 'chmate' and
       manager.machine.system.name ~= 'gambitv' and
       manager.machine.system.name ~= 'kishon' and
       manager.machine.system.name ~= 'kishona' and
       manager.machine.system.name ~= 'super9cc' then
    manager.machine.video.throttled = false
  end
  game_started = false
  piece_get = false
  sel_started = false
  my_color = "B"
  ply = "W"
  piece_from = nil
  piece_to = nil
  prev_move = nil
  pos_count = {}
  max_think = 0
  manager.machine.video.frameskip = frskip

  board = {{ 3, 5, 4, 2, 1, 4, 5, 3 },
    {  6, 6, 6, 6, 6, 6, 6, 6 },
    {  0, 0, 0, 0, 0, 0, 0, 0 },
    {  0, 0, 0, 0, 0, 0, 0, 0 },
    {  0, 0, 0, 0, 0, 0, 0, 0 },
    {  0, 0, 0, 0, 0, 0, 0, 0 },
    { -6,-6,-6,-6,-6,-6,-6,-6 },
    { -3,-5,-4,-2,-1,-4,-5,-3 }}

  -- FIXED: Pass the local tracking variables down into the child script's setup routine
  if interface.setup_machine then
    interface.setup_machine()
  end

  if rand_delay ~= 0 then
    emu.wait(math.random())
  end
  manager.machine.video.throttled = throttle_state
end

local function board_clear()
  game_started = false
  piece_get = false
  sel_started = false
  my_color = "B"
  ply = "W"
  piece_from = nil
  piece_to = nil
  prev_move = nil
  pos_count = {}
  max_think = 0

  board = {{ 0, 0, 0, 0, 0, 0, 0, 0 },
    {  0, 0, 0, 0, 0, 0, 0, 0 },
    {  0, 0, 0, 0, 0, 0, 0, 0 },
    {  0, 0, 0, 0, 0, 0, 0, 0 },
    {  0, 0, 0, 0, 0, 0, 0, 0 },
    {  0, 0, 0, 0, 0, 0, 0, 0 },
    {  0, 0, 0, 0, 0, 0, 0, 0 },
    {  0, 0, 0, 0, 0, 0, 0, 0 }}
end

local function move_to_pos(move)
  local rows_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
  local x = rows_idx[move:sub(1, 1)]
  local y = tonumber(move:sub(2, 2))
  return {x = x, y = y}
end

local function promote_pawn(pos, piece, promotion)
  local sign = 1
  if board[pos.y][pos.x] < 0 then
    sign = -1
  end

  if     (piece == "q") then  board[pos.y][pos.x] = board[pos.y][pos.x] - (4 * sign)
  elseif (piece == "r") then  board[pos.y][pos.x] = board[pos.y][pos.x] - (3 * sign)
  elseif (piece == "b") then  board[pos.y][pos.x] = board[pos.y][pos.x] - (2 * sign)
  elseif (piece == "n") then  board[pos.y][pos.x] = board[pos.y][pos.x] - (1 * sign)
  end

  if interface.promote then
    emu.wait(0.5)
    if promotion then
      interface.promote(pos.x, pos.y, string.lower(piece))
    else
      interface.promote(pos.x, pos.y, string.upper(piece))
    end
  end
end

local function promotion_error(piece)
  if piece == piece:lower() and piece ~= "q" then
    local msg = "ERROR: Promotion to \"" .. piece:upper() .. "\" is not supported by '" .. module .. "'!"
    if prom_check then
      emu.print_error(msg)
    else
      manager.machine:popmessage(msg)
    end
  end
end

local function send_input(tag, mask, seconds)
  local port = manager.machine.ioport.ports[tag]
  if port == nil then
    error("send_input: no input port '" .. tag .. "'", 2)
  end
  local field = port:field(mask)
  if field == nil then
    error(string.format("send_input: port '%s' has no field for mask 0x%x", tag, mask), 2)
  end
  field:set_value(1)
  emu.wait(seconds * 2 / 3)
  field:set_value(0)
  emu.wait(seconds * 1 / 3)
end

local function sb_set_ui(tag, mask, state)
  local field = manager.machine.ioport.ports[tag .. ":UI"]:field(mask)
  if (field ~= nil) then
    field:set_value(state)
    emu.wait(0.5)
  end
end

local function sb_press_square(tag, seconds, x, y)
  sb_set_ui(tag, 0x0001, 1)
  send_input(tag .. ":RANK." .. tostring(y), 1 << (x - 1), seconds)
  sb_set_ui(tag, 0x0001, 0)
end

local function sb_promote(tag, x, y, piece)
  local mask = 0
  if     (string.lower(piece) == 'q') then  mask = 0x10
  elseif (string.lower(piece) == 'r') then  mask = 0x08
  elseif (string.lower(piece) == 'b') then  mask = 0x04
  elseif (string.lower(piece) == 'n') then  mask = 0x02
  end

  if board[y][x] < 0 or (board[y][x] == 0 and y == 8) then
    mask = mask << 6
  end

  send_input(tag .. ":SPAWN", mask, 0.09)
  
  -- Fetches the global output via the root device container proxy
  local root_device = manager.machine.devices[":"]
  local piece_ui_state = root_device and root_device:output("piece_ui0")
  
  if piece_ui_state and piece_ui_state:get() ~= 0 then
    sb_set_ui(tag, 0x0002, 1)
    send_input(tag .. ":RANK." .. tostring(y), 1 << (x - 1), 0.09)
    sb_set_ui(tag, 0x0002, 0)
  end
end

local function sb_remove_piece(tag, x, y)
  sb_set_ui(tag, 0x0002, 1)
  send_input(tag .. ":RANK." .. tostring(y), 1 << (x - 1), 0.09)
  sb_set_ui(tag, 0x0002, 0)
  send_input(tag .. ":UI", 0x0008, 0.09)  -- SensorBoard REMOVE
end

local function sb_select_piece(tag, seconds, x, y, event)
  if (event ~= "capture") then
    send_input(tag .. ":RANK." .. tostring(y), 1 << (x - 1), seconds)
  end
  if (event == "en_passant") then
    send_input(tag .. ":UI", 0x0008, seconds) -- SensorBoard REMOVE
  end
end

local function sb_move_piece(tag, x, y)
  sb_set_ui(tag, 0x0002, 1)
  sb_select_piece(tag, 0.09, x, y, "")
  sb_set_ui(tag, 0x0002, 0)
end

local function sb_clear_board(tag)
  send_input(tag .. ":UI", 0x0100, 0.09)  -- SensorBoard CLEAR
end

local function sb_reset_board(tag)
  send_input(tag .. ":UI", 0x0200, 0.09)  -- SensorBoard RESET
end

local function sb_rotate_board(tag)
  sb_set_ui(tag, 0x0002, 1)
  send_input(tag .. ":UI", 0x0200, 0.09)  -- SensorBoard RESET
  sb_set_ui(tag, 0x0002, 0)
end

local function sb_setup_board(tag, fen)
  if tag~="" then
    sb_clear_board(tag)
  end
  emu.wait(1)
  board_clear()
  local bd_tmp="pnbrqk KQRBNP"
  local sb_tmp="PNBRQKpnbrqk"
  local x=1
  local y=8
  local n=1
  local c=fen:sub(1,1)
  local z=0
  while (c~=" ") do
    if tonumber(c)~=nil and tonumber(c)>=1 and tonumber(c)<=8 then
      x=x+tonumber(c)
    elseif c=='/' then
      x=1
      y=y-1
    else
      z=bd_tmp:find(c)
      board[y][x]=z-7
      if tag~="" then
        z=sb_tmp:find(c)
        send_input(tag .. ":SPAWN", 0x01<<(z-1), 0.09)
        sb_move_piece(tag, x, y)
      end
      x=x+1
    end
    n=n+1
    c=fen:sub(n,n)
  end
  c=fen:sub(n+1,n+1)
  if c=="b" then
    my_color="W"
    ply="B"
  else
    my_color="B"
    ply="W"
  end
  emu.wait(1)
end

local function get_piece_id(x, y)
  if (board ~= nil) then
    return board[y][x]
  end
  return 0
end

local function get_move_type(fx, fy, tx, ty)
  if (fy == 1 and fx == 5 and ty == 1 and (tx == 3 or tx == 7) and get_piece_id(fx, fy) == 1) or
     (fy == 8 and fx == 5 and ty == 8 and (tx == 3 or tx == 7) and get_piece_id(fx, fy) == -1) then
    return "castling"

  elseif (fx ~= tx and fy == 5 and ty == 6 and get_piece_id(fx, fy) == 6 and get_piece_id(tx, ty) == 0) or
         (fx ~= tx and fy == 4 and ty == 3 and get_piece_id(fx, fy) == -6 and get_piece_id(tx, ty) == 0) then
    return "en_passant"

  elseif (get_piece_id(fx, fy) == 6 and ty == 8) or (get_piece_id(fx, fy) == -6 and ty == 1) then
    if (get_piece_id(tx, ty) ~= 0) then
      return "capture_promotion"
    else
      return "promotion"
    end

  elseif (get_piece_id(tx, ty) ~= 0) then
    return "capture"
  end

  return nil
end

local function recv_cmd()
  if quitting then
    return nil
  end
  if conth.yield then
    return conth.result
  end
  return nil
end

local function send_cmd(cmd)
  io.stdout:write(cmd .. "\n")
  io.stdout:flush()
end

local function send_move(move)
  if turn_since then
    max_think = math.max(max_think, manager.machine.time:as_double() - turn_since)
  end
  prev_move = move
  moved_since_position = true
  if (protocol == "xboard") then
    send_cmd("move " .. move)
  elseif (protocol == "uci") then
    send_cmd("bestmove " .. move)
    lastpos = lastpos .. " " .. move
  end
  if (module == "sc80") then
    local rate = manager.machine.video.throttle_rate
    manager.machine.video.throttle_rate = 10.0
    emu.wait(15)
    manager.machine.video.throttle_rate = rate
  end
end

local function position_key()
  local k = ply
  for y = 1, 8 do
    for x = 1, 8 do
      k = k .. "," .. board[y][x]
    end
  end
  return k
end

-- a position seen twice with the other side to move is one move of the machine away: the machine may claim
-- the threefold repetition before making that move (the two boards differ on exactly a from and a to square)
local function repetition_by_move()
  local cur = {}
  for y = 1, 8 do
    for x = 1, 8 do
      cur[#cur + 1] = board[y][x]
    end
  end
  for k, c in pairs(pos_count) do
    if c >= 2 and k:sub(1, 1) ~= ply then
      local other, diff = {}, {}
      for v in k:gmatch(",(-?%d+)") do
        other[#other + 1] = tonumber(v)
      end
      for i = 1, 64 do
        if cur[i] ~= other[i] then
          diff[#diff + 1] = i
          if #diff > 2 then break end
        end
      end
      if #diff == 2 then
        local a, b = diff[1], diff[2]
        if (cur[a] ~= 0 and other[a] == 0 and cur[b] == 0 and other[b] == cur[a]) or
           (cur[b] ~= 0 and other[b] == 0 and cur[a] == 0 and other[a] == cur[b]) then
          return true
        end
      end
    end
  end
  return false
end

local function count_position()
  local k = position_key()
  pos_count[k] = (pos_count[k] or 0) + 1
end

local function make_move(move, reason, promotion)
  if reason ~= "_castling" and next(pos_count) == nil then
    count_position() -- the start position of this game
  end
  local from = move_to_pos(move:sub(1, 2))
  local to = move_to_pos(move:sub(3, 4))

  if interface.select_piece then
    if not piece_get then
      interface.select_piece(from.x, from.y, "get" .. reason)
      emu.wait(0.5)
    end
    if (move:len() >= 5) and interface.promote_special then
      interface.promote_special(move:sub(move:len())) -- some engines need at promotion the piece between from and to
    end
    if board[to.y][to.x] ~= 0 then
      interface.select_piece(to.x, to.y, "capture")
    end

    interface.select_piece(to.x, to.y, "put" .. reason)
  end

  piece_get = false
  sel_started = false

  -- castling
  if     (board[from.y][from.x] ==  1 and move == "e1g1") then make_move("h1f1", "_castling", false)
  elseif (board[from.y][from.x] ==  1 and move == "e1c1") then make_move("a1d1", "_castling", false)
  elseif (board[from.y][from.x] == -1 and move == "e8g8") then make_move("h8f8", "_castling", false)
  elseif (board[from.y][from.x] == -1 and move == "e8c8") then make_move("a8d8", "_castling", false)
  else
    -- next ply
    if (ply == "W") then
      ply = "B"
    else
      ply = "W"
    end
  end

  -- en passant
  if board[to.y][to.x] == 0 and board[from.y][from.x] == -6 and from.y == 4 and to.y == 3 and from.x ~= to.x and board[to.y + 1][to.x] == 6 then
    if interface.select_piece then
      interface.select_piece(to.x, to.y + 1, "en_passant")
      emu.wait(0.5)
    end
    board[to.y + 1][to.x] = 0
  elseif board[to.y][to.x] == 0 and board[from.y][from.x] == 6 and from.y == 5 and to.y == 6 and from.x ~= to.x and board[to.y - 1][to.x] == -6 then
    if interface.select_piece then
      interface.select_piece(to.x, to.y - 1, "en_passant")
      emu.wait(0.5)
    end
    board[to.y - 1][to.x] = 0
  end

  board[to.y][to.x] = board[from.y][from.x]
  board[from.y][from.x] = 0

  -- promotion
  if (move:len() >= 5) then
    promote_pawn(to, move:sub(move:len()), promotion)
  end

  if reason ~= "_castling" then
    count_position()
  end
end

local function search_selected_piece()
  local active_fpos = 0
  local active_tpos = 0
  local board_sel = {}
  if (interface.is_selected) then
    for y=1,8 do
      for x=1,8 do
        board_sel[y*8 + x] = interface.is_selected(x, y)
        if board_sel[y*8 + x] and ((board[y][x] < 0 and ply == "B") or (board[y][x] > 0 and ply == "W")) then
          piece_from = {x = x, y = y}
          active_fpos = active_fpos + 1
        end
      end
    end
    if (piece_from ~= nil) then
      for y=1,8 do
        for x=1,8 do
          if board_sel[y*8 + x] and (board[y][x] == 0 or (board[y][x] < 0 and ply == "W") or (board[y][x] > 0 and ply == "B")) then
            piece_to = {x = x, y = y}
            active_tpos = active_tpos + 1
          end
        end
      end
    end
  end

  -- If there are more than 2 selections, something is wrong
  if active_tpos > 1 or active_fpos > 1 or (piece_from ~= nil and piece_to ~= nil and piece_from.x == piece_to.x and piece_from.y == piece_to.y) then
    piece_from = nil
    piece_to = nil
  end

  -- in some systems LEDs flash for a bit after the search is completed, wait for 1.5 seconds should allow thing to stabilize
  if (not sel_started and (piece_from or piece_to)) then
    sel_started = true
    emu.wait(1.5)
    piece_from = nil
    piece_to = nil
  end

  if not piece_get and piece_from ~= nil and piece_to == nil then
    piece_get = true
    if interface.select_piece then
      interface.select_piece(piece_from.x, piece_from.y, "get")
      emu.wait(0.5)
    end
  end

  if piece_to ~= nil and piece_from ~= nil then
    local rows = { "a", "b", "c", "d", "e", "f", "g", "h" }
    local move = rows[piece_from.x] .. tostring(piece_from.y)
    move = move .. rows[piece_to.x] .. tostring(piece_to.y)
    local need_promotion = (piece_to.y == 8 and board[piece_from.y][piece_from.x] == 6) or (piece_to.y == 1 and board[piece_from.y][piece_from.x] == -6)

    -- promotion
    if (need_promotion) then
      local new_type = "q"  -- default to Queen
      if interface.get_promotion then
        new_type = interface.get_promotion(piece_to.x, piece_to.y)
      end

      if (new_type ~= nil) then
        move = move .. new_type
        need_promotion = false
        send_move(move)
      end
    else
      send_move(move)
    end

    make_move(move, "", false)

    -- some machines show the promotion only after the pawn has been moved
    if (need_promotion) then
      local new_type = nil
      if interface.get_promotion then
        new_type = interface.get_promotion(piece_to.x, piece_to.y)
      end

      if (new_type == nil) then
        if interface.test_promotion then
          new_type = string.lower(interface.test_promotion(piece_to.x, piece_to.y)) -- test promotion piece after the move (interfaces return uppercase)
        else
          manager.machine:logerror(manager.machine.system.name .. " Unable to determine the promotion")
          new_type = "q"  -- default to Queen
        end
      end

      promote_pawn(piece_to, new_type, false)
      move = move .. new_type
      send_move(move)
    end
  end
end

local function send_options()
  local tag_default = ""
  local tag_min = " "
  local tag_max = " "

  if (protocol == "uci") then
    tag_default = "default "
    tag_min = " min "
    tag_max = " max "
  end

  for idx,opt in ipairs(interface.get_options()) do
    local opt_data = nil
    if     (#opt == 3 and opt[1] == "string") then opt_data = tag_default .. tostring(opt[3])
    elseif (#opt == 2 and opt[1] == "button") then opt_data = ''
    elseif (#opt == 5 and opt[1] == "spin")   then opt_data = tag_default .. tostring(opt[3]) .. tag_min .. tostring(opt[4]) .. tag_max .. tostring(opt[5])
    elseif (#opt == 3 and opt[1] == "check")  then
      if protocol == "uci" then
        opt_data = tag_default .. tostring(opt[3]:gsub("1", "true"):gsub("0", "false"))
      elseif protocol == "xboard" then
        opt_data = tag_default .. tostring(opt[3])
      end
    elseif (#opt == 4 and opt[1] == "combo")  then
      if protocol == "uci" then
        opt_data = tag_default .. tostring(opt[3]) .. " var " .. tostring(opt[4]):gsub("\t", " var ")
      elseif protocol == "xboard" then
        opt_data = tostring(opt[4]):gsub("%f[%w_]" .. tostring(opt[3]) .. "%f[^%w_]", "*" .. tostring(opt[3])):gsub("\t", " /// ")
      end
    end
    if (opt_data ~= nil) then
      if protocol == "uci" then
        send_cmd('option name ' .. tostring(opt[2]) .. ' type ' .. tostring(opt[1]) .. ' ' .. opt_data)
      elseif protocol == "xboard" then
        send_cmd('feature option="' .. tostring(opt[2]) .. ' -' .. tostring(opt[1]) .. ' ' .. opt_data .. '"')
      end
    else
      manager.machine:logerror("Invalid interface options '" .. tostring(opt[1]) .. " " .. tostring(opt[2]) .. "'")
    end
  end
end

local function set_option(name, value)
  if (name == nil or value == nil) then
    return
  end

  if (string.lower(name) == "speed") then
    manager.machine.video.throttled = true
    manager.machine.video.throttle_rate = tonumber(value) / 100.0
  elseif (interface.set_option) then
    interface.set_option(string.lower(name), value)
  end
end

local function wait_for_go()
  -- Keep the emulated computer idle after synchronizing a position.  A UCI
  -- position command must not start a search; execute_uci_command("go") will
  -- assign the current ply to the emulated computer when Picochess asks it to
  -- move.
  if ply == "W" then
    my_color = "B"
  else
    my_color = "W"
  end
  piece_get = false
  piece_from = nil
  piece_to = nil
  sel_started = false
end

local function play_moves(old, new)
  local temp = new:sub((old:len()) + 2) .. " "
  local n = 0
  local move = ""
  local throttle_state = manager.machine.video.throttled
  if manager.machine.system.name ~= 'ivant' and
     manager.machine.system.name ~= 'igor' and
     manager.machine.system.name ~= 'chessac' and
     manager.machine.system.name ~= 'schachak' and
     manager.machine.system.name ~= 'vcc' and
     manager.machine.system.name ~= 'vsc' and
     manager.machine.system.name ~= 'csc' and
     manager.machine.system.name ~= 'csce' and
     manager.machine.system.name ~= 'ccmk2' and
     manager.machine.system.name ~= 'ccmk2a' and
     manager.machine.system.name ~= 'chmate' and
     manager.machine.system.name ~= 'gambitv' and
     manager.machine.system.name ~= 'kishon' and
     manager.machine.system.name ~= 'kishona' and
     manager.machine.system.name ~= 'super9cc' then
    manager.machine.video.throttled = false
  end
  interface.edit_game(true)
  while temp ~= "" do
    n = temp:find(" ")
    move = temp:sub(1,n-1)
    temp = temp:sub(n+1)
    make_move(move, "", true)
    lastpos = lastpos .. " " .. move
    piece_from = nil
    piece_to = nil
    sel_started = false
  end
  interface.edit_game(false)
  manager.machine.video.throttled = throttle_state
  manager.machine:popmessage("Game edit is complete!")
  if module == "mm5" then
    -- Proof of concept: Set Pos may replay a move stack without an immediate
    -- go.  Do not let MM V start playing merely because replay has finished.
    wait_for_go()
  elseif interface.start_play then
    interface.start_play(false)
    my_color = ply
  end
end

local function execute_uci_command(cmd)
  local m

  if cmd:match("^position ") ~= nil then
    moved_since_position = false
    game_over_sent = false
  end

  if cmd:match("^position fen ") ~= nil then
    if board == nil then
      board_reset()
    end
    m = cmd:find("moves ")
    if interface.set_pos then
      editmode = 0
      if game_started == false then
        local throttle_state = manager.machine.video.throttled
        manager.machine.video.throttled = false
        emu.wait(1)
        local tag=interface.set_pos(0)
        if tag:sub(1,7) == "ERROR: " then
          manager.machine.video.throttled = throttle_state
          emu.print_error(tag)
          editmode = -1
          send_cmd("bestmove ----")
          return
        else
          sb_setup_board(tag, cmd:sub(14))
          if ply == "B" then
            interface.set_pos(-1)
          else
            interface.set_pos(1)
          end
          emu.wait(1)
          manager.machine.video.throttled = throttle_state
          game_started = true
          if m ~= nil then
            lastpos = cmd:sub(1, m + 4)
          else
            lastpos = cmd .. " moves"
          end
          manager.machine:popmessage("Position setup is complete!")
        end
      end
      if m == nil then
        return
      end
    else
      emu.print_error("ERROR: 'Setup' mode is not supported by '" .. module .. "'!")
      editmode = -1
      send_cmd("bestmove ----")
      return
    end
  end
  if cmd == "uci" then
    manager.ui.show_fps = true
    protocol = cmd
    --send_cmd("id name " .. describe_system())
    local l_opt = " ("
    if interface.set_pos then
      l_opt = l_opt .. "pos"
    end

    if interface.show_pv_after_move or interface.show_info then
      if interface.set_pos then
        l_opt = l_opt .. "+info)"
      else
        l_opt = l_opt .. "info)"
      end
    else
      l_opt = l_opt .. ")"
    end
    if l_opt == " ()" then
      l_opt = ""
    end

    if interface.get_module then
      send_cmd("id name " .. interface.get_module() .. l_opt)
    else
      send_cmd("id name " .. describe_system() .. l_opt)
    end
    if manager.machine.system.name == "sparc" then
      send_cmd("id year 1993")
    else
      send_cmd("id year " .. manager.machine.system.year)
    end

    send_cmd("option name Speed type spin default 100 min 0 max 10000")
    if interface.get_options then
      send_options()
    end

    send_cmd("uciok")
    board_reset()
  elseif cmd == "isready" then
    send_cmd("readyok")
  elseif cmd == "ucinewgame" then
    if rand_delay == 2 then
      rand_delay = 1
    end
    editmode = 0
    lastpos = "position startpos moves"
    if game_started == true then
      if (module ~= "feasgla" and module ~= "avrmax" and module ~= "cc2schach" and 
          module ~= "atm18mcc" and module ~= "kblitz" and module ~= "fphantom" and 
          module ~= "cphantom") then
        manager.machine:soft_reset()
      end
      board_reset()
    end
    if module == "robotadv" then
      board_reset()
    end
   
  elseif cmd == "quit" then
    quitting = true
    manager.machine:exit()
  elseif cmd:match("^go") ~= nil then
    -- Reset both lock flags for the new search query loop
    if interface then 
      interface.move_found = false 
      interface.lock_print = false
    end

    if rand_delay == 1 then
      emu.wait(math.random())
      rand_delay = 2
    end
    if board == nil then
      board_reset()
    end
    if editmode == -1 then
      editmode = 0
      return
    elseif interface.ignore_late_go and moved_since_position then
      -- the machine answered the last position on its own before this 'go' arrived;
      -- start_play would make it move again, for the other side
      return
    elseif game_started == false or my_color ~= ply then
      if interface.start_play then
        interface.start_play(not game_started)
      end
      my_color = ply
      game_started = true
      sel_started = false
    end
  elseif cmd:match("^setoption name ") ~= nil then
    local opt_name, opt_val = string.match(cmd:sub(16), '(.+) value (.+)')
    if     (string.lower(opt_val) == "true" ) then opt_val = "1"
    elseif (string.lower(opt_val) == "false") then opt_val = "0"
    end
    set_option(opt_name, opt_val)
  elseif cmd:match("^position startpos moves ") ~= nil or
         cmd:match("^position fen .+ moves ") ~= nil then
    if board == nil then
      board_reset()
    end
    game_started = true
    local last_move = ""
    for i in string.gmatch(cmd, "%S+") do
      last_move = i
    end
    if cmd:len() > lastpos:len() + 6 then
      if interface.edit_game then
        play_moves(lastpos, cmd)
        return
      else
        emu.print_error("ERROR: 'Edit' mode is not supported by '" .. module .. "'!")
        editmode = -1
        send_cmd("bestmove ----")
        return
      end
    -- Repeating an identical UCI position must be a no-op. This happens when
    -- Picochess sets up a PGN position and python-chess sends the same position
    -- again immediately before go.
    elseif (cmd == lastpos or last_move == prev_move) then
      if module == "mm5" then
        wait_for_go()
      else
        my_color = ply
        sel_started = false
        if interface.start_play then
          interface.start_play(not game_started)
        end
      end
    else
      if move_delay > 0 then
        emu.wait(move_delay*math.random())
      end
      make_move(last_move, "", true)
      lastpos = lastpos .. " " .. last_move
      piece_from = nil
      piece_to = nil
      sel_started = false
    end
  elseif cmd == "stop" then
    if game_started == true and my_color == ply then
      if interface.stop_play then
        interface.stop_play()
      elseif interface.start_play then
        interface.start_play(not game_started)
      end
    end
  else
    manager.machine:logerror("Unhandled UCI command '" .. cmd .. "'")
  end
end

local function execute_xboard_command(cmd)
  local dummy = 1
end

local function update()
  repeat
    local command = recv_cmd()

    if edit_num > 0 then
      loop_num = loop_num + 1
      if loop_num > edit_num or command == "go" then
        if edit_num > 1 then
          manager.machine:popmessage("Game edit is complete!")
        end
        edit_num = -1
      end
    elseif setupmode > 0 and setupmode < 3 then
      setupmode = setupmode + 1
    end

    if (command ~= nil) then
      if (command == "uci" or command == "xboard") then
        protocol = command
      end

      if protocol == "uci" then
        local throttle_state = manager.machine.video.throttled
        if manager.machine.system.name ~= 'ivant' and
           manager.machine.system.name ~= 'igor' and
           manager.machine.system.name ~= 'chessac' and
           manager.machine.system.name ~= 'schachak' and
           manager.machine.system.name ~= 'vcc' and
           manager.machine.system.name ~= 'vsc' and
           manager.machine.system.name ~= 'csc' and
           manager.machine.system.name ~= 'csce' and
           manager.machine.system.name ~= 'ccmk2' and
           manager.machine.system.name ~= 'ccmk2a' and
           manager.machine.system.name ~= 'chmate' and
           manager.machine.system.name ~= 'gambitv' and
           manager.machine.system.name ~= 'kishon' and
           manager.machine.system.name ~= 'kishona' and
           manager.machine.system.name ~= 'super9cc' then
          manager.machine.video.throttled = false
        end
        
        -- Modern Protected Call (pcall) to catch interface structural errors gracefully
        local success, err = pcall(execute_uci_command, command)
        if not success then
          emu.print_error("[LUA INTERFACE ERROR] " .. tostring(err))
        end
        if command == "ucinewgame" then
          command = nil
        end
        manager.machine.video.throttled = throttle_state
      elseif protocol == "xboard" then
        execute_xboard_command(command)
        if command == "new" then
          command = nil
        end
      end

      conth:continue(conth.result)
      emu.wait(0.1)
    end
  until command == nil

  -- search for a new move
  if ply == my_color then
    if not turn_since then
      turn_since = manager.machine.time:as_double()
    end
    search_selected_piece()
    -- the machine resigned or claimed a draw (interface.game_over() reads its display or LEDs):
    -- "bestmove 0000" lets the GUI end the game
    if interface.game_over and game_started and not game_over_sent and ticker % 100 == 0 then
      if interface.game_over() then
        game_over_sent = true
        send_cmd("bestmove 0000")
      end
    end
    -- threefold repetition: many machines claim it silently and stop; once the machine has been quiet for
    -- twice its longest move of the game (at least 30 s), "bestmove 0000" lets the GUI end the game as a draw
    local seen = game_started and not game_over_sent and ticker % 100 == 0 and pos_count[position_key()] or 0
    if (seen >= 3 or (seen == 2 and repetition_by_move())) and
       manager.machine.time:as_double() - turn_since > math.max(30, 2 * max_think) then
      game_over_sent = true
      send_cmd("bestmove 0000")
    end
  else
    turn_since = nil
  end
  
  -- Info display (evaluation, best move) updated periodically
  if ticker >= 500 then
    ticker = 0
    if ply ~= my_color then
      if interface.show_pv_after_move_emu then
        interface.show_pv_after_move_emu()
      end
    else
      if interface.show_pv_after_move_player then
        interface.show_pv_after_move_player()
      end
    end
    
    if interface.show_info then
      local info_str
      if ply == my_color then
        info_str = interface.show_info(true, ply)
      else
        info_str = interface.show_info(false, ply)
      end
      -- Ensure the string is neither nil nor just empty spaces
      if info_str ~= nil and tostring(info_str):match("%S") then
        -- Forward the string and ensure a clean terminal newline sequence
        send_cmd(tostring(info_str))
      end
    end
  else
    ticker = ticker + 1
  end
end

local function load_interface(name)
  local env = { machine = manager.machine, send_input = send_input, get_piece_id = get_piece_id, output = manager.machine.output, ioport = manager.machine.ioport, get_move_type = get_move_type, load_interface = load_interface, emu = emu,
      sb_select_piece = sb_select_piece, sb_move_piece = sb_move_piece, sb_press_square = sb_press_square, sb_promote = sb_promote, promotion_error = promotion_error,
      sb_remove_piece = sb_remove_piece, sb_clear_board = sb_clear_board, sb_reset_board = sb_reset_board, sb_rotate_board = sb_rotate_board, sb_set_ui = sb_set_ui,
      pairs = pairs, ipairs = ipairs, tostring = tostring, tonumber = tonumber, string = string, math = math, print = _G.print }

  local func = loadfile(plugin_path .. "/interfaces/" .. name .. ".lua", "t", env)
  if func then
    return func()
  end
  return nil
end

function exports.set_folder(path)
  plugin_path = path
end

function exports.startplugin()
  conth = emu.thread()
  conth:start(scr)

  emu.register_periodic(
  function()
    if ((co == nil or coroutine.status(co) == "dead") and not manager.machine.paused) then
      co = coroutine.create(update)
      coroutine.resume(co)
    end
  end)

  emu.add_machine_reset_notifier(
  function()
    local system = manager.machine.system.name
    module = system
    if interface == nil then
      interface = load_interface(system)
    end

    if interface == nil and manager.machine.system.parent ~= nil then
      interface = load_interface(manager.machine.system.parent)
    end

    if interface == nil then
      interface = {}
      emu.print_error("Error: missing interface for " .. system)
    end
  end)

  emu.add_machine_stop_notifier(
  function()
  end)
end

return exports
