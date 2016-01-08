function! lvdb#Python_debug()
"toggles debug mode on and off, doing the following
"   1) global (g:lvdb_debug_mode) variable indicating whether debug mode is on
"   2) sets an autocommand group to launch "Debug_monitor" function every 0.1 sec
"   3) deletes the file ".debug" (toggling on or off)

    "make sure python support is installed
    if !has('python')
        finish
    endif

    "start with clean files
    call lvdb#Delete_file(".debug_location")
    call lvdb#Delete_file(".debug_breakpoint")

    if g:lvdb_debug_mode == g:lvdb_debug_off

        "1) debug mode was previously off, so turn it on
        let g:lvdb_debug_mode = g:lvdb_debug_on

        "2) set autocommand group to launch "Debug_monitor"
        augroup python_debug
            autocmd!
            autocmd CursorHold * :call lvdb#Debug_monitor()
        augroup END

        set updatetime=10      "do it every 0.01 seconds

        "3) clear old highlighting (make sure to keep pdb_set_trace)
        call pos#Set_current_pos()
        if hlexists('pdb_set_trace')
            tabdo call clearmatches() | match pdb_set_trace "\v^\s*lvdb\.set_trace().*"
        endif 
        call pos#Return_to_orig_pos()

        "4) Update variables that keep track of file modification times
        let g:prev_time_debug_location = 0
        let g:prev_time_debug_breakpoint = 0
        let g:lvdb_has_breakpoints = 0

        "5) let the user know it has started
        execute "normal! 0"
        echo 'Python debug is turned on'

    elseif g:lvdb_debug_mode == g:lvdb_debug_on

        "1) turn off debug mode
        let g:lvdb_debug_mode = g:lvdb_debug_off

        "2) turn off autocommand that triggers debug mode
        augroup python_debug
            autocmd!
        augroup END

        set updatetime=4000     "back to default time

        "3) clear old highlighting
        call pos#Set_current_pos()
        tabdo set nocursorline
        if hlexists('pdb_set_trace')
            tabdo call clearmatches() | match pdb_set_trace "\v^\s*lvdb\.set_trace().*"
        endif 
        call pos#Return_to_orig_pos()
        redraw

        "4) tell the user it has stopped
        echo 'Python debug is turned off'

        "5) remove necessary globals
        unlet g:prev_time_debug_location
        unlet g:prev_time_debug_breakpoint
        unlet g:lvdb_has_breakpoints

    endif

    "in case the user has updated their line number toggle settings, update it
    :call lines#ProcessAugroupSettings()

endfunction

function! lvdb#Delete_file(fname)
"deletes a file using the os module from python
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" start of python code
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
python << EOF
import os, vim
f = vim.eval("a:fname")
if os.path.isfile(f):
    os.remove(vim.eval("a:fname"))
EOF
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" end of python code
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

endfunction

function! lvdb#Debug_monitor()
"PURPOSE: reads .debug file in current directory and
"
"   1) Puts the cursor at the same line as the pdb debugger
"   2) updates/deletes breakpoints
"
"USAGE:
"
"   The function is called by the OnCursorHold event
"   (note the use of feedkeys below to make sure the event occurs routinely)

call feedkeys("hl")

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" start of python code
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
python << EOF
import os, time, re, vim

def go_to_debug_line(full_path, line_num):
    '''updates the cursor position in vim using the results from find_debug_line

    arguments: full_path (string) - the file of interest
               line_num (string) - the line number of interest
    '''

    try:
        #an error can occur when user decides not to open a tab

        #found is 1 when there is an open tab matching the full path
        found = vim.eval("tags#Look_for_matching_tab('" + full_path + "')")

        #if found == 0 (the tab is not currently open), open a new tab
        #note that Look_for_matching_tab opens the tab for you in this case
        if found == '0':
            vim.command("tabnew " + full_path)

        #go to the appropriate line
        vim.command('execute "normal! ' + line_num + 'G"')

        #if the cursor is at the bottom of the line, execute zz to center it
        if vim.eval("winheight(0)") == vim.eval("winline()"):
            vim.command('execute "normal! zz"')

        #turn on the cursor line
        vim.command("set cursorline")

        try:
            vim.command("foldopen")
        except:
            #ignore the error that occurs when there is no fold
            pass

        #for some reason, the filetype is not recognized automatically
        if vim.eval("expand('%:e') == 'py'") == '1':
            vim.command("set filetype=python")
        else:
            vim.command("set filetype=cpp")

    except:
        os.remove(".debug_location")


def process_location_file():

    fname = '.debug_location'
    prev_time = float(vim.eval("g:prev_time_debug_location"))  #the last time the file was updated by pdb

    ############################################################
    # check for whether to update the location based on whether the location file is updated
    #############################################################

    #does the .debug file exist?
    if not os.path.isfile(fname):
        return

    #has the .debug file been edited within the last 0.01 seconds?
    if abs(os.path.getmtime(fname) - prev_time) < 0.01:
        return

    orig_pos = vim.eval("getpos('.')")          #the current position of the cursor in vim
    orig_tab = vim.eval("tabpagenr()")          #the current tab in vim

    #open the .debug file, put it into lines (last line first)
    #the file will only have 2 lines:
    #   line 1: the full path name      e.g.    /home/me/junk.py
    #   line 2: the line number                 1
    with open('.debug_location') as f:
        lines = f.read().splitlines()

    #record last modification time so this code is not called too much (see
    #above)
    vim.command('let g:prev_time_debug_location = ' + str(os.path.getmtime(fname)))

    if len(lines) != 2:
        return

    full_path = lines[0]
    line_num  = lines[1]

    if full_path != "":
        go_to_debug_line(full_path, line_num)           #go to that place
    else:
        #otherwise go to the original location
        vim.command("execute 'tabnext ' " + orig_tab)
        vim.command("call setpos('.', " + str(orig_pos) + ")")

def process_breakpoint_file():

    fname = '.debug_breakpoint'
    prev_time = float(vim.eval("g:prev_time_debug_breakpoint"))  #the last time the file was updated by pdb

    #does the .debug file exist?
    if not os.path.isfile(fname):

        #only clear breakpoints if there is a match in the active file
        matches = vim.eval('getmatches()')

        for m in matches:
            if m['group'] == 'pdb_breakpoint':

                vim.command('call pos#Set_current_pos()')
                if vim.eval("hlexists('pdb_breakpoint')") == '1':
                    vim.command('tabdo call clearmatches() | match pdb_set_trace "\v^\s*lvdb\.set_trace().*"')
                vim.command('call pos#Return_to_orig_pos()')
                break

        return

    #has the .debug file been edited within the last 0.01 seconds?
    if abs(os.path.getmtime(fname) - prev_time) < 0.01:
        return

    #clear old highlighting (keeping the set_trace highlighting)
    vim.command('call pos#Set_current_pos()')
    if vim.eval("hlexists('pdb_set_trace')") == 1:
        vim.command('tabdo call clearmatches() | match pdb_set_trace "\v^\s*lvdb\.set_trace().*"')
    vim.command('call pos#Return_to_orig_pos()')

    #open the .debug file, put it into lines (last line first)
    with open(fname) as f:
        lines = f.read().splitlines()

    if lines:
        vim.command('let g:lvdb_has_breakpoints = 1')
    else:
        vim.command('let g:lvdb_has_breakpoints = 0')

    vim.command('let g:prev_time_debug_breakpoint = ' + str(os.path.getmtime(fname)))

    #the lines are structured as follows:
    #   1) file name_with_full_path                 e.g,    /home/me/junk.py
    #   2) list of_line_numbers_with_breakpoints            [1,2]
    #and this pattern repeats. Thus, if there are 4 files, the
    #.debug_breakpoint file will have 8 lines
    for i in range(len(lines)/2):

        full_path = lines[2*i]

        #check whether the file has been opened
        found = vim.eval("tags#Look_for_matching_tab('" + full_path + "')")

        #if the file has not been opened, open it
        if found == '0':
            vim.command("tabnew " + full_path)

        #convert lines to a list
        line_nums = lines[2*i+1][1:-1]
        line_nums = line_nums.split(",")

        for line_num in line_nums:

            #highlight the line
            s = 'call matchaddpos("pdb_breakpoint", [' + line_num + '])'
            vim.command(s)

def main():

    '''parses .debug, updating cursor position and adding/removing highlighting'''

    process_breakpoint_file()
    process_location_file()

main()
EOF
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" end of python code
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

endfunction
