# telescope-insert-path.nvim

Set of [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) actions to insert file path on the current buffer.

<img src="https://user-images.githubusercontent.com/12980409/206919320-aa0d9b79-771e-4560-9cb3-9787d1c6460f.gif" width="100%"/>

## Breaking change compared to upstream

The only public function is now `insert_path(relative, insert_mode_after_adding_path)`
For example `["["] = path_actions.insert_reltobufpath_insert` becomes `["["] = path_actions.insert_path("buf", true)`

### Supported Path Types

- Absolute path
- Relative path (to current working directory)
- Relative path (to buffer file)
- Relative to git root
- Relative to custom source direcotry

### Custom source directory
The custom source directory can be set using the method `require('telescope_insert_path').set_source_dir()`.

A default custom source directory can be set using the global option `telescope_insert_path_source_dir`. 
In the case this option is set and present in the root of the project (git root or cwd) this will be used, 
if the value does not exists or it's not a directory the root of the project will be used as default.

### Supported Telescope Modes

- Multiple selections
- Any modes (Find files, Live grep, ...)

## Installation

Install using vim-plug:

```vim
Plug 'kiyoon/telescope-insert-path.nvim'
```

Install using packer:

```lua
use {'kiyoon/telescope-insert-path.nvim'}
```

Setup telescope with path actions in vimscript / lua:

```lua
local path_actions = require('telescope_insert_path')

require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ["<C-f>r"] = path_actions.insert_path("buf", true),
        ["<C-f>a"] = path_actions.insert_path("abs", true),
        ["<C-f>g"] = path_actions.insert_path("git", true),
        ["<C-f>s"] = path_actions.insert_path("source", true),
      }
    }
  }
}
```
