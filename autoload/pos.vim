
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" creates a stack of cursor positions. each stack entry contains the following
"   1) Tab Number
"   2) Cursor Position: [bufnum, lnum, col, off] (see help getpos)
"
" useful with returning after custom <c-]> and :S defined in Tabify plugin
"
" last updated: 12/1/2013
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! pos#Set_current_pos()
    "add the current position to the position stack
    if !exists("g:original_position")
        let g:original_position = []
        let g:original_tab_num = []
    endif

    call add(g:original_position, getpos("."))
    call add(g:original_tab_num,  tabpagenr())
endfunction

function! pos#Return_to_orig_pos()
    "go back to original position and remove the top entry from the stack
    "(see also, Set_current_pos)
    if exists("g:original_position")
        if !empty(g:original_position)

            "go to the position on top of the stack
            execute 'tabnext ' . g:original_tab_num[-1]
            call setpos('.',g:original_position[-1])

            "take the value off the list
            let g:original_position = g:original_position[:-2]
            let g:original_tab_num = g:original_tab_num[:-2]

            return
        endif
    endif

    echo "Nothing left on tag stack"
endfunction

function! pos#Clear_tag_stack()

    let g:original_position = []
    let g:original_tab_num  = []

endfunction
