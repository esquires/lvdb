function! tags#Look_for_matching_tab(fname)
" helper function to Open_tag_in_new_tab
" loops through the tabs, if there is a matching filename, then it will select
" that line number and return 1. otherwise it will do nothing and return 0.

    if getftype(a:fname) == "link"
        let search_for = resolve(a:fname)
        echom 'updating from ' . a:fname ' to ' . search_for
    else 
        let search_for = a:fname
    endif

    "check current tab
    if tags#Look_for_matching_win(search_for)
        return 1
    endif

    "get current tab number
    let tab_num = tabpagenr()
    tabnext

    "loop until it gets back to the current tab
    while tabpagenr() != tab_num

        if tags#Look_for_matching_win(search_for)
            return 1
        endif

        "otherwise continue looping
        tabnext

    endwhile

    "if nothing has been found, then return false
    return 0

endfunction

function! tags#Look_for_matching_win(search_for)
    if a:search_for ==# expand('%:p')
        return 1
    endif

    " get the current window number
    let win_num = winnr()
    execute "normal! \<c-w>\<c-w>"

    while winnr() != win_num

        if a:search_for ==# expand('%:p')
            return 1
        endif

        execute "normal! \<c-w>\<c-w>"
    endwhile 

    return 0
endfunction
