"PURPOSE:
"   toggles line numbers so that a user can have absolute numbers when using
"   ipdb (useful for setting breakpoints, seeing errors, etc), but relative
"   numbering when using vim (useful for movements such as 4j)
function! lines#ProcessAugroupSettings()

    if     (g:lvdb_toggle_lines == g:lvdb_toggle_always_all)

            setlocal nu
            setlocal rnu

            "start the toggling
            augroup linenums_on_focus
                autocmd!
                autocmd FocusGained *.* :call lines#Turn_off_abs_line_numbers()
                autocmd FocusLost   *.* :call lines#Turn_on_abs_line_numbers()
            augroup END

    elseif (g:lvdb_toggle_lines == g:lvdb_toggle_never)

            "stop the toggling
            augroup linenums_on_focus
                autocmd!
            augroup END

    elseif (g:lvdb_toggle_lines == g:lvdb_toggle_debug &&
         \  g:lvdb_debug_mode   == g:lvdb_debug_off)

            :call lines#Turn_off_abs_line_numbers()

            "stop the toggling
            augroup linenums_on_focus
                autocmd!
            augroup END

    elseif (g:lvdb_toggle_lines == g:lvdb_toggle_always) ||
         \ (g:lvdb_toggle_lines == g:lvdb_toggle_debug &&
         \  g:lvdb_debug_mode   == g:lvdb_debug_on)

            setlocal nu
            setlocal rnu

            "start the toggling
            augroup linenums_on_focus
                autocmd!
                autocmd FocusGained *.py :call lines#Turn_off_abs_line_numbers()
                autocmd FocusLost   *.py :call lines#Turn_on_abs_line_numbers()
            augroup END

    end

endfunction

function! lines#ToggleNumber()
"if absolute line numbering is on, turn it off but keep relative numbering
"designed to be easily called from a keyboard mapping
    if v:version > 703
        let turn_on_abs = &relativenumber
    else
        let turn_on_abs = !&number
    endif

    if turn_on_abs
        call lines#Turn_on_abs_line_numbers()
    else
        call lines#Turn_off_abs_line_numbers()
    endif

endfunction

function! lines#Turn_off_abs_line_numbers()
"designed to be incorporated into GainedFocus event
    if v:version > 703
        "setlocal number
        setlocal relativenumber
        setlocal number
    else
        setlocal relativenumber
    endif
endfunction

function! lines#Turn_on_abs_line_numbers()
"designed to be incorporated into LostFocus event
    if v:version > 703
        "setlocal number
        setlocal norelativenumber
    else
        setlocal number
    endif
endfunction
