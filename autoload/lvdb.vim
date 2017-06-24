function! lvdb#Python_debug()
    "make sure python support is installed
    if g:lvdb_debug_mode == g:lvdb_debug_off

        "1) debug mode was previously off, so turn it on
        let g:lvdb_debug_mode = g:lvdb_debug_on

        "2) set autocommand group to launch "Debug_monitor"
        let g:amt = 1
        try
            " better to call a timer but this requires 
            " (a) a version of vim after 7.4.1578 and
            " (b) compilation with +timers
            call timer_start(10, 'lvdb#Debug_monitor', {'repeat': -1})
            let g:lvdb_has_timers = 1
        catch
            augroup python_debug
                autocmd!
                autocmd CursorHold * :call lvdb#Debug_monitor()
            augroup END
            let g:lvdb_has_timers = 0
            set updatetime=10      "do it every 0.01 seconds
          execute "normal! 0"
        endtry 

        echo 'Python debug is turned on'

    elseif g:lvdb_debug_mode == g:lvdb_debug_on

        "1) turn off debug mode
        let g:lvdb_debug_mode = g:lvdb_debug_off

        "2) turn off autocommand that triggers debug mode
        if g:lvdb_has_timers == 0
            augroup python_debug
                autocmd!
            augroup END
        end 

        set updatetime=4000     "back to default time

        "4) tell the user it has stopped
        echo 'Python debug is turned off'

        set nocursorline
    endif

    "in case the user has updated their line number toggle settings, update it
    call lines#ProcessAugroupSettings()

endfunction

function! lvdb#Debug_monitor(...)
    if a:0 == 0
        " called using OnCursorHold event with no arguments
        " otherwise a:1 is a timer
        call feedkeys("hl")
    endif 
    if g:lvdb_has_timers && g:lvdb_debug_mode == g:lvdb_debug_off
        call timer_stop(a:1)
        return
    endif 

    call lvdb#process_location_file()
endfunction

function! lvdb#process_location_file()
    if !filereadable(g:lvdb_gdb_output_file)
        return
    endif 

    let lines = readfile(g:lvdb_gdb_output_file)
    call writefile([], g:lvdb_gdb_output_file)

    let len_lines = len(lines)
    if len_lines == 0
        return
    endif 

    let idx = -1
    while -idx <= len_lines

        let data = split(lines[idx], ':')
        let idx -= 1

        if len(data) < 2
            continue
        endif 

        let fname = data[0]
        if fname[0] == ''
            " gdb sometimes puts  at the beginning of the filename
            let fname = fname[2:]
        endif 

        if fname[0] != "/"
            continue
        endif 

        let line = data[1]

        let curr_fname = expand('%:p')
        let curr_line = line(".")
        if fname[0] != "/" || (fname == curr_fname && line == curr_line)
            continue
        endif

        set cursorline

        let found = tags#Look_for_matching_tab(fname)

        if found == 0
            exec "tabnew " . fname
        endif

        exec line

        try
            let &foldlevel=foldlevel('.')
        endtry 

        break
    endwhile 

endfunction 
