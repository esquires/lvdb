function! tags#Look_for_matching_tab(fname, full_fname)
" helper function to Open_tag_in_new_tab
" loops through the tabs, if there is a matching filename, then it will select
" that line number and return 1. otherwise it will do nothing and return 0.

    let search_for = resolve(a:fname)

    "check current tab
    if tags#Look_for_matching_win(search_for, a:full_fname)
        return 1
    endif

    "get current tab number
    let tab_num = tabpagenr()
    tabnext

    "loop until it gets back to the current tab
    while tabpagenr() != tab_num

        if tags#Look_for_matching_win(search_for, a:full_fname)
            return 1
        endif

        "otherwise continue looping
        tabnext

    endwhile

endfunction

function! tags#Look_for_matching_win(search_for, full_fname)

    if a:full_fname == 1
        let modifier = 'p'
    else
        let modifier = 't'
    endif

    if a:search_for ==# resolve(expand('%:' . modifier))
        return 1
    endif

    " get the current window number
    let win_num = winnr()
    execute "normal! \<c-w>\<c-w>"

    while winnr() != win_num

        if a:search_for ==# expand('%:' . modifier)
            return 1
        endif

        execute "normal! \<c-w>\<c-w>"
    endwhile 

    return 0
endfunction
