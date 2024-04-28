local tele_status_ok, _ = pcall(require, "telescope")
if not tele_status_ok then
  return
end

local path_actions = setmetatable({}, {
  __index = function(_, k)
    error("Key does not exist for 'telescope_insert_path': " .. tostring(k))
  end,
})

local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

function string.starts(String, Start)
  return string.sub(String, 1, string.len(Start)) == Start
end

function string.ends(String, End)
  return End == "" or string.sub(String, -string.len(End)) == End
end

-- get git root, nil on fail
local function get_git_root()
  local output = vim.fn.system "git rev-parse --show-toplevel"
  local rescode = vim.v.shell_error

  if rescode == 0 then
    return vim.fn.trim(output)
  end

  -- in this case git command failed
  return nil
end

-- returns the git root of the project or the cwd
local function get_git_root_or_cwd()
  return get_git_root() or vim.fn.getcwd()
end

-- given a file path and a dir, return relative path of the file to a given dir
local function get_relative_path(file, dir)
  local absfile = vim.fn.fnamemodify(file, ":p")
  local absdir = vim.fn.fnamemodify(dir, ":p")

  if string.ends(absdir, "/") then
    absdir = absdir:sub(1, -2)
  else
    error("dir (" .. dir .. ") is not a directory")
  end
  local num_parents = 0
  local absolute_path = false
  local searchdir = absdir
  while not string.starts(absfile, searchdir) do
    local searchdir_new = vim.fn.fnamemodify(searchdir, ":h")
    if searchdir_new == searchdir then
      -- reached root directory
      absolute_path = true
      break
    end
    searchdir = searchdir_new
    num_parents = num_parents + 1
  end

  if absolute_path then
    return absfile
  else
    return string.rep("../", num_parents) .. string.sub(absfile, string.len(searchdir) + 2)
  end
end

local function get_path_from_entry(entry, source)
  local filename
  if source == "buf" then
    -- path relative to current buffer
    local selection_abspath = entry.path
    local bufpath = vim.fn.expand "%:p"
    local bufdir = vim.fn.fnamemodify(bufpath, ":h")
    filename = get_relative_path(selection_abspath, bufdir)
  elseif source == "cwd" then
    -- path relative to current working directory
    filename = entry.filename
  elseif source == "git" then
    local git_root = get_git_root()

    if not git_root then
      error "Not in a git repository"
    end

    filename = get_relative_path(entry.path, git_root)
  elseif source == "source" then
    filename = get_relative_path(entry.path, path_actions.source_dir)
  else
    -- absolute path
    filename = entry.path
  end
  return filename
end

local function _insert_path(prompt_bufnr, source, insert_mode)
  local picker = action_state.get_current_picker(prompt_bufnr)

  actions.close(prompt_bufnr)

  local entry = action_state.get_selected_entry(prompt_bufnr)

  -- local from_entry = require "telescope.from_entry"
  -- local filename = from_entry.path(entry)
  local filename = get_path_from_entry(entry, source)

  local selections = {}
  for _, selection in ipairs(picker:get_multi_selection()) do
    local selection_filename = get_path_from_entry(selection, source)

    if selection_filename ~= filename then
      table.insert(selections, selection_filename)
    end
  end

  -- normal mode
  vim.cmd [[stopinsert]]

  local cursor_pos_visual_start = vim.api.nvim_win_get_cursor(0)

  -- if you use nvim_put it's hard to know the range of the new text.
  -- vim.api.nvim_put({ filename }, "", put_after, true)
  local line = vim.api.nvim_get_current_line()
  local new_line
  local text_before = line:sub(1, cursor_pos_visual_start[2] + 1)
  new_line = text_before .. filename .. line:sub(cursor_pos_visual_start[2] + 2)
  cursor_pos_visual_start[2] = text_before:len()
  vim.api.nvim_set_current_line(new_line)

  local cursor_pos_visual_end

  -- put the multi-selections
  if #selections > 0 then
    -- start with empty line
    -- table.insert(selections, 1, "")
    for _, selection in ipairs(selections) do
      vim.cmd [[normal! o ]] -- add empty space so the cursor respects the indent
      vim.cmd [[normal! x]] -- and immediately delete it
      vim.api.nvim_put({ selection }, "", true, true)
    end
    cursor_pos_visual_end = vim.api.nvim_win_get_cursor(0)
  else
    cursor_pos_visual_end = { cursor_pos_visual_start[1], cursor_pos_visual_start[2] + filename:len() - 1 }
  end

  if insert_mode then
    vim.api.nvim_win_set_cursor(0, cursor_pos_visual_end)
    -- append like 'a'
    vim.cmd [[startinsert]]
    vim.cmd [[call cursor( line('.'), col('.') + 1)]]
  else
    vim.api.nvim_win_set_cursor(0, cursor_pos_visual_end)
  end
end

--- Check if a file or directory exists in this path
local function exists(file)
  local ok, err, code = os.rename(file, file)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return true
    end
  end
  return ok, err
end

--- Check if a directory exists in this path
local function isdir(path)
  -- "/" works on both Unix and Windows
  return exists(path .. "/")
end

-- source_dir
path_actions.set_source_dir = function(dir)
  if dir then
    path_actions.source_dir = dir
  else
    local root = get_git_root()

    if not root then
      root = vim.fn.getcwd()
    end

    path_actions.source_dir = vim.fn.input("insert source directory: ", root .. "/", "dir")
  end
end

-- setup function
path_actions.setup = function(args)
  local source = ""

  if args.source_dir then
    source = get_git_root_or_cwd() .. "/" .. args.source_dir
  else
    source = get_git_root_or_cwd()
  end

  if isdir(source) then
    path_actions.source_dir = source
  else
    path_actions.source_dir = get_git_root_or_cwd()
  end

  return path_actions
end

-- default value
path_actions.source_dir = get_git_root_or_cwd()

function path_actions.insert_path(source, insert_mode)
  return function(prompt_bufnr)
    _insert_path(prompt_bufnr, source, insert_mode)
  end
end

return path_actions
