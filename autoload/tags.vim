function! tags#Look_for_matching_tab(fname)
" helper function to Open_tag_in_new_tab
" loops through the tabs, if there is a matching filename, then it will select
" that line number and return 1. otherwise it will do nothing and return 0.

    "check current tab
    if a:fname ==# expand('%:p')
        return 1
    endif

    "get current tab number
    let tab_num = tabpagenr()
    tabnext

    "loop until it gets back to the current tab
    while tabpagenr() != tab_num

        " if the tab name is equal to the input fname
        if a:fname ==# expand('%:p')
            "return that it has been found
            return 1
        endif

        "otherwise continue looping
        tabnext

    endwhile

    "if nothing has been found, then return false
    return 0

endfunction
