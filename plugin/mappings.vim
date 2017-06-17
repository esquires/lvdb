"define global constants
let g:lvdb_toggle_never      = 0
let g:lvdb_toggle_debug      = 1
let g:lvdb_toggle_always     = 2
let g:lvdb_toggle_always_all = 3

let g:lvdb_debug_off         = 0
let g:lvdb_debug_on          = 1

"default to not in debug mode
let g:lvdb_debug_mode = g:lvdb_debug_off

let g:lvdb_gdb_output_file = '/tmp/lvdb.txt'

"setup whether the user wants to have line numbers toggle
"(will be updated on lvdb#Python_debug() )
call lines#ProcessAugroupSettings()
