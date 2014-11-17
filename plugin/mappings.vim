"syntax is necessary for breakpoint highlighting code
syntax on

"define global constants
let g:vim_pdb_toggle_never      = 0
let g:vim_pdb_toggle_debug      = 1
let g:vim_pdb_toggle_always     = 2
let g:vim_pdb_toggle_always_all = 3

let g:vim_pdb_debug_off         = 0
let g:vim_pdb_debug_on          = 1

"default to not in debug mode
let g:vim_pdb_debug_mode        = g:vim_pdb_debug_off

"setup whether the user wants to have line numbers toggle
"(will be updated on vim_pdb#Python_debug() )
:call lines#ProcessAugroupSettings()
