local function fail(s, ...) 
  ya.notify { title = "Command Palette", content = string.format(s, ...), timeout = 5, level = "error" } 
end

local function info(s, ...) 
  ya.notify { title = "Command Palette", content = string.format(s, ...), timeout = 3, level = "info" } 
end

local function debug(s, ...)
  ya.notify { title = "Command Palette DEBUG", content = string.format(s, ...), timeout = 5, level = "warn" }
end

-- Get all TOML files from plugins directory
local function get_plugin_tomls()
  local tomls = {}
  local plugins_dir = os.getenv("HOME") .. "/.config/yazi/plugins"
  
  -- Try to list directory contents
  local handle = io.popen("find '" .. plugins_dir .. "' -name '*.toml' 2>/dev/null")
  if handle then
    for line in handle:lines() do
      table.insert(tomls, line)
    end
    handle:close()
  end
  
  return tomls
end

-- Parse TOML keymap file to extract keybindings
local function parse_keymap_file(file_path)
  local commands = {}
  
--   debug("Parsing file: " .. file_path)
  
  -- Read file content
  local file = io.open(file_path, "r")
  if not file then
    -- debug("Could not open file: " .. file_path)
    return commands
  end
  
  local content = file:read("*all")
  file:close()
  
--   debug("File content length: " .. #content)
  
  -- Parse prepend_keymap entries
  local current_entry = {}
  local in_prepend = false
  local entry_count = 0
  
  for line in content:gmatch("[^\r\n]+") do
    line = line:gsub("^%s*", ""):gsub("%s*$", "") -- trim whitespace
    
    if line:match("^%[%[.*%.prepend_keymap%]%]") then
      -- Save previous entry if complete
      if current_entry.key and current_entry.run then
        table.insert(commands, current_entry)
        entry_count = entry_count + 1
      end
      -- Start new entry
      current_entry = {}
      in_prepend = true
    elseif in_prepend and line ~= "" then
      -- Parse key binding
      local key_match = line:match('^on%s*=%s*"([^"]*)"')
      if key_match then
        current_entry.key = key_match
      else
        local key_array = line:match('^on%s*=%s*%[([^%]]*)%]')
        if key_array then
          -- Convert array format to readable format
          local keys = {}
          for k in key_array:gmatch('"([^"]*)"') do
            table.insert(keys, k)
          end
          current_entry.key = table.concat(keys, " + ")
        end
      end
      
      -- Parse description
      local desc_match = line:match('^desc%s*=%s*"([^"]*)"')
      if desc_match then
        current_entry.desc = desc_match
      end
      
      -- Parse run command
      local run_match = line:match('^run%s*=%s*"(.*)"%s*$')
      if run_match then
        current_entry.run = run_match
      else
        local run_array = line:match('^run%s*=%s*%[([^%]]*)')
        if run_array then
          -- Handle array format - take first command
          local first_cmd = run_array:match('"([^"]*)"')
          if first_cmd then
            current_entry.run = first_cmd
          end
        end
      end
    end
  end
  
  -- Don't forget the last entry
  if current_entry.key and current_entry.run then
    table.insert(commands, current_entry)
    entry_count = entry_count + 1
  end
  
--   debug("Found " .. entry_count .. " commands in " .. file_path)
  
  return commands
end

-- Get all available commands from keymap files
local function get_all_commands()
  local commands = {}
  
  -- Try to read from config keymap
  local config_path = os.getenv("HOME") .. "/.config/yazi/keymap.toml"
  local config_commands = parse_keymap_file(config_path)
  
  for _, cmd in ipairs(config_commands) do
    cmd.source = "config"
    table.insert(commands, cmd)
  end
  
  -- Try to read from plugin TOML files
  local plugin_tomls = get_plugin_tomls()
  for _, toml_path in ipairs(plugin_tomls) do
    local plugin_commands = parse_keymap_file(toml_path)
    for _, cmd in ipairs(plugin_commands) do
      cmd.source = "plugin:" .. toml_path:match("([^/]+)$")
      table.insert(commands, cmd)
    end
  end
  
--   debug("Total commands found: " .. #commands)
  
  return commands
end

-- Get current hovered file in sync context
local get_current_file = ya.sync(function()
  local h = cx.active.current.hovered
  return h and tostring(h.url) or ""
end)

-- Execute a yazi command
local function execute_command(cmd_string)
--   debug("Executing command: " .. cmd_string)
-- Get current hovered file
  local current_file = get_current_file()
  
  -- Parse the command type and execute accordingly
  if cmd_string:match("^shell") then
    -- Handle shell commands - pass current file as argument
    local shell_cmd = cmd_string:match('shell%s+["\']([^"\']+)["\']') or 
                     cmd_string:match('shell%s+--block%s+["\']([^"\']+)["\']')
    if shell_cmd then
      -- Remove trailing backslash if present
      shell_cmd = shell_cmd:gsub("\\$", "")
      local is_blocking = cmd_string:match("--block") and true or false
    --   debug("Shell command: " .. shell_cmd .. " with file: " .. current_file)
      ya.manager_emit("shell", { shell_cmd .. " " .. current_file, block = is_blocking })
    else
      fail("Could not parse shell command: " .. cmd_string)
    end
  elseif cmd_string:match("^plugin") then
    -- Handle plugin commands
    local plugin_name = cmd_string:match("plugin%s+([%w%-_]+)")
    local plugin_args = cmd_string:match("plugin%s+[%w%-_]+%s+(.+)")
    
    if plugin_name then
    --   debug("Plugin: " .. plugin_name .. " Args: " .. (plugin_args or "none"))
      if plugin_args then
        -- Parse args if present
        local args = {}
        for arg in plugin_args:gmatch("[^%s]+") do
          table.insert(args, arg)
        end
        ya.manager_emit("plugin", { plugin_name, args = args })
      else
        ya.manager_emit("plugin", { plugin_name })
      end
    else
      fail("Could not parse plugin command: " .. cmd_string)
    end
  else
    -- Handle other yazi commands
    local parts = {}
    for part in cmd_string:gmatch("[^%s]+") do
      table.insert(parts, part)
    end
    
    if #parts > 0 then
      local command = parts[1]
      local args = {}
      for i = 2, #parts do
        table.insert(args, parts[i])
      end
      
    --   debug("Yazi command: " .. command .. " Args: " .. table.concat(args, ", "))
      if #args > 0 then
        ya.manager_emit(command, args)
      else
        ya.manager_emit(command, {})
      end
    else
      fail("Empty command string")
    end
  end
end

-- Create fuzzy searchable command palette using fzf
local function show_command_palette()
  local commands = get_all_commands()
  
  if #commands == 0 then
    fail("No commands found in keymap files")
    return
  end
  
  local _permit = ya.hide()
  local child, err = Command("fzf")
    :arg({
      "--height=80%",
      "--layout=reverse",
      "--border",
      "--prompt=🔍 Command Palette: ",
      "--header=Type to search commands",
      "--preview-window=right:40%",
      "--preview=echo {3}",
      "--delimiter=\t",
      "--with-nth=1,2",
      "--bind=ctrl-/:toggle-preview"
    })
    :stdin(Command.PIPED)
    :stdout(Command.PIPED)
    :stderr(Command.INHERIT)
    :spawn()
  
  if not child then
    fail("Failed to spawn fzf. Is it installed?")
    return
  end
  
  -- Build input for fzf
  local input_lines = {}
  for _, cmd in ipairs(commands) do
    local desc = cmd.desc or "No description"
    local key_display = cmd.key or "No key"
    local line = string.format("%s\t%s\t%s", desc, key_display, cmd.run)
    table.insert(input_lines, line)
  end
  
  child:write_all(table.concat(input_lines, "\n"))
  child:flush()
  
  local output, err = child:wait_with_output()
  if not output then
    fail("Cannot read fzf output")
    return
  end
  
  if not output.status.success and output.status.code ~= 130 then
    fail("fzf exited with error code: " .. tostring(output.status.code))
    return
  end
  
  -- Parse fzf output
  local selected_line = output.stdout:match("([^\n]*)")
  if not selected_line or selected_line == "" then
    return
  end
  
  local desc, key, run_cmd = selected_line:match("([^\t]*)\t([^\t]*)\t([^\t]*)")
  if run_cmd then
    info("Executing: " .. desc)
    execute_command(run_cmd)
  end
end

-- Alternative built-in interface (fallback if fzf not available)
local function show_builtin_palette()
  local commands = get_all_commands()
  
  if #commands == 0 then
    fail("No commands found in keymap files")
    return
  end
  
  -- Create candidates for ya.which with single character keys
  local candidates = {}
  local keys = "abcdefghijklmnopqrstuvwxyz0123456789"
  
  for i, cmd in ipairs(commands) do
    if i > #keys then break end -- Limit to available keys
    
    local desc = cmd.desc or "No description"
    local key_display = cmd.key or "No key"
    local display = string.format("%s (%s)", desc, key_display)
    
    table.insert(candidates, {
      on = keys:sub(i, i),
      desc = display,
      cmd = cmd.run,
      key = cmd.key
    })
  end
  
  -- Show the selection interface
  local choice = ya.which {
    cands = candidates,
    silent = true
  }
  
  if choice then
    local selected = candidates[choice]
    info("Executing: " .. (selected.desc or "Unknown command"))
    execute_command(selected.cmd)
  end
end

return {
  entry = function(_, args)
    local use_builtin = args and args[1] == "builtin"
    
    if use_builtin then
      show_builtin_palette()
    else
      show_command_palette()
    end
  end,
}
