"PURPOSE:
"
"   integrates pdb (python debugger) into vim
"
"BACKGROUND:
"
"   pdb is a text-based debugger. Although it can give code context with the
"   "list" command, it would be helpful to have VIM highlight where you are in
"   the code. Tabify incorporates the following functionality when debugging
"   with pdb
"
"       1) Update cursor line in vim to match where pdb is in the debugging
"          process
"       2) Highlight/delete breakpoints that have been set on the fly in pdb
"
"USAGE:
"
"   setup
"
"       1) in bash, type
"
"           python -u scriptname.py | tee .debug
"
"          the -u tells python to keep unloading its buffer (i.e., keep
"          printing its output). piping to tee keeps stdout as well as sending
"          output to .debug (note: this will create a ".debug" file. You can't
"          change this without altering the code)
"
"       2) in vim, type
"
"           :call vim_pdb#Python_debug(1 or 0)
"
"          This tells Vim to look for changes in a ".debug" file that will be
"          (note: there is a mapping <leader>d and <leader>D to automate this
"          function call)
"
"   using the debugger:
"
"       1) Stepping: use pdb like normal in bash (e.g., using s, n, c, r,
"          etc). Vim will automatically follow the pdb output
"
"       2) Breakpoints: to set/remove breakpoints, type into bash "b
"          linenumber" to set a breakpoint and "cl linenumber" to remove a
"          breakpoint (this also works for "b fname:linenumber"). Vim will
"          automatically detect the breakpoint changes.
"
"          (note: in pdb, "cl" without a linenumber allows the user to clear
"          all breakpoints at once, but this is not integrated into this
"          script)

function! vim_pdb#Python_debug(remove_dot_debug)
"toggles debug mode on and off, doing the following
"   1) global (g:python_debug_mode) variable indicating whether debug mode is on
"   2) sets an autocommand group to launch "Debug_monitor" function every 0.1 sec
"   3) deletes the file ".debug" (toggling on or off)

    "make sure python support is installed
    if !has('python')
        finish
    endif

    if g:python_debug_mode == 0
        "debug mode was previously off, so turn it on

        "1) toggle the global debug_mode variable
        let g:python_debug_mode = 1
        let g:python_debug_lines = 0

        "2) set autocommand group to launch "Debug_monitor"
        augroup python_debug
            autocmd!
            autocmd CursorHold * :call vim_pdb#Debug_monitor()
        augroup END

        set updatetime=100      "do it every 0.1 seconds

        "3) delete the file ".debug"
        if a:remove_dot_debug
            call vim_pdb#Delete_file(".debug")
            call pos#Set_current_pos()
            tabdo call vim_pdb#Remove_highlighting(getmatches(), 'all')
            call pos#Return_to_orig_pos()
        endif

        "other stuff: put the cursor in the first column/send message
        execute "normal! 0"
        echo 'Python debug is turned on'

        "g:prev_time is a global variable in vim representing the last time ".debug"
        let g:prev_time = 0

    else

        "1) toggle the global debug_mode variable
        let g:python_debug_mode = 0
        let g:python_debug_lines = 0

        "2) set autocommand group to launch "Debug_monitor"
        augroup python_debug
            autocmd!
        augroup END

        set updatetime=4000     "back to default time

        "3) delete the file ".debug"
        if a:remove_dot_debug
            call vim_pdb#Delete_file(".debug")
        endif

        "other stuff: remove the cursor line from every tab
        call pos#Set_current_pos()
        tabdo set nocursorline
        call pos#Return_to_orig_pos()
        redraw
        echo 'Python debug is turned off'

    endif

endfunction

function! vim_pdb#Delete_file(fname)
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

function! vim_pdb#Debug_monitor()
" purpose: reads .debug file in current directory and
"   1) Puts the cursor at the same line as the pdb debugger
"   2) updates/deletes brakepoints
"
" usage:
"   1) The function is called by the OnCursorHold event
"      (note the use of feedkeys below to make sure the event occurs every few
"      seconds)
"      see function vim_pdb#Delete_file
"   2) in bash, type python -u scriptname.py | tee .debug

"set cursor to first column to make sure the OnCursorHold event is reset (so
"this function can be called again after "updatetime" seconds)
call feedkeys("0")

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" start of python code
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
python << EOF
import os, time, re, vim

def find_debug_line(lines):
    '''given lines from .debug, returns the filename and line of the current pdb line
    if no relevant lines are found, returns empty strings

    arguments: lines (a list of strings) represents the unprocessed lines of debug
               unprocessed lines are added lines since the last processing of .debug

    algorithm:  loop through each line in reverse.
                the first line giving a line number will be parsed and the results
                returned
    '''

    #reverse the lines so it is looking for the most recent entry
    lines = lines[::-1]

    #loop through the lines
    for idx, ln in enumerate(lines):

        #the pdb format for the current line number is one of two things
        if ln[0] == '>' or ln[0:7] == '(Pdb) >':

            #pull out the path and line number
            #example line: > /home/eric/.vim/bundle/tabify/autoload/stuff.py(5)<module>()
            m = re.search(r"(/.*)\((\d+)\)", ln)
            full_path   = m.group(1)        #e.g., full_path = /home/eric/.vim/bundle/tabify/autoload/stuff.py
            line_num    = m.group(2)        #e.g., line_num  = 5
            return full_path, line_num

    #if nothing has been found, return empty strings
    return "", ""

def go_to_debug_line(full_path, line_num):
    '''updates the cursor position in vim using the results from find_debug_line

    arguments: full_path (string) - the file of interest
               line_num (string) - the line number of interest
    '''

    #found is 1 when there is an open tab matching the full path
    found = vim.eval("tags#Look_for_matching_tab('" + full_path + "')")

    #if found == 0 (the tab is not currently open), open a new tab
    #note that Look_for_matching_tab opens the tab for you in this case
    if found == '0':
        vim.command("tabnew " + full_path)

    #go to the appropriate line
    vim.command('execute "normal! ' + line_num + 'G"')

    #turn on the cursor line
    vim.command("set cursorline")

    #for some reason, the filetype is not recognized automatically
    vim.command("set filetype=python")

def process_breakpoint_line(ln):
    #example pdb output:
    #(Pdb) Breakpoint 1 at /home/eric/.vim/bundle/tabify/autoload/temp.py:2
    m = re.search("(\d+) at (.+):(\d+)", ln)
    break_num = m.group(1)      #e.g., break_num = 1
    full_path = m.group(2)      #e.g., full_path = /home/eric/.vim/bundle/tabify/autoload/temp.py
    line_num  = m.group(3)      #e.g., line_num  = 2
    return break_num, full_path, line_num

def process_breakpoints(new_lines, all_lines):
    '''toggles highlighting on lines representing breakpoints in pdb

    arguments: new_lines (list of strings) - unprocessed lines in .debug
               all_lines (list of strings) - all lines in .debug

    algorithm: loop through new_lines
               if a breakpoint has been added, highlight that line
               if a breakpoint has been deleted, remove the highlightin
    '''
    #loop through all the new lines of pdb
    for ln in new_lines:

        if ln[0] != '\n':

            #if a breakpoint has been added, then update the highlighting
            if ln[0:10] == 'Breakpoint' or ln[0:16] == '(Pdb) Breakpoint':

                break_num, full_path, line_num = process_breakpoint_line(ln)

                #check whether the file has been opened
                found = vim.eval("tags#Look_for_matching_tab('" + full_path + "')")

                #if the file has not been opened, open it
                if found == '0':
                    vim.command("tabnew " + full_path)

                #highlight the line
                vim.command('call matchadd("pdb_breakpoint", "\\\%' + line_num + 'l")')

            #if a breakpoint has been deleted, then remove the highlighting
            elif ln[0:18] == 'Deleted breakpoint' or ln[0:24] == '(Pdb) Deleted breakpoint':

                #example pdb output:
                #(Pdb) Deleted breakpoint 1
                m = re.search("\d+", ln)
                break_num = m.group(0)      #e.g., break_num = 1

                #loop through all the lines, looking for that breakpoint (to get the line num/path)
                for ln2 in all_lines:

                    #found the breakpoint, get parameters
                    if ln2[0:10] == 'Breakpoint' or ln2[0:16] == '(Pdb) Breakpoint':
                        temp_break_num, temp_full_path, temp_line_num = process_breakpoint_line(ln2)

                        if temp_break_num == break_num:
                            break

                #open the breakpoint file (if it not already open, open it in a new tab)
                found = vim.eval("tags#Look_for_matching_tab('" + temp_full_path + "')")

                if found == '0':
                    vim.command("tabnew " + temp_full_path)

                #remove the highlighting
                m = vim.eval("getmatches()")
                if m != '[]':
                    vim.command("call python_debug#Remove_highlighting(getmatches(), '\%" + temp_line_num + "l')")

def main():
    '''parses .debug, updating cursor position and adding/removing highlighting'''

    ############################################################
    # initialization
    #############################################################
    pdb_output_file = '.debug'                  #file that receives output from pdb
    prev_time = float(vim.eval("g:prev_time"))  #the last time the file was updated by pdb
    orig_pos = vim.eval("getpos('.')")          #the current position of the cursor in vim
    orig_tab = vim.eval("tabpagenr()")          #the current tab in vim

    ############################################################
    # do file checking: whether .debug exists/has been updated
    #############################################################

    #does the .debug file exist?
    if not os.path.isfile(pdb_output_file):
        return

    #has the .debug file been edited within the last 0.01 seconds?
    if abs(os.path.getmtime(pdb_output_file) - prev_time) < 0.01:
        return

    ############################################################
    # read the file/process global variables
    #############################################################
    #open the .debug file, put it into lines (last line first)
    with open('.debug') as f:
        all_lines = f.read().splitlines()

    #just look at the added lines
    prev_ending_line = int(vim.eval("g:python_debug_lines"))
    new_lines = all_lines[max(0,prev_ending_line-1):]

    #set global variables: prev time of .debug, number of lines in files
    vim.command('let g:prev_time = ' + str(os.path.getmtime(pdb_output_file)))
    vim.command('let g:python_debug_lines = ' + str(len(all_lines)))

    ############################################################
    # process the new lines
    #############################################################

    #find where the debugger is and go to it
    if new_lines and new_lines[0] != '\n':

        #turn on/off breakpoints
        process_breakpoints(new_lines, all_lines)

        #put the cursor line in the same spot as the debugger
        full_path, line_num = find_debug_line(new_lines)    #find where the debugger is
        if full_path != "":
            go_to_debug_line(full_path, line_num)           #go to that place
        else:
            #otherwise go to the original location
            vim.command("execute 'tabnext ' " + orig_tab)
            vim.command("call setpos('.', " + str(orig_pos) + ")")

main()
EOF
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" end of python code
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

endfunction

function! vim_pdb#Remove_highlighting(hl_list, excl_line_pattern)
"removes line highlighting
"
"arguments: hl_list - a list of dictionaries (the output of getmatches())
"           excl_line_pattern - either 'all' or a pattern
"               if all, then remove all line highlighting
"               otherwise, excl_line_pattern will have the form '\%6l

    "loop through every entry in hl_list
    let idx = 0
    while idx < len(a:hl_list)

        "each entry in hl_list is a dictionary, pull out relevant parameters
        let dict    = a:hl_list[idx]
        let group   = dict['group']
        let pattern = dict['pattern']
        let id      = dict['id']

        "if the group number matches the format used to create the "highlighting
        "and the excl_line_pattern matches, then delete this hl_list entry
        if group ==# 'pdb_breakpoint' && (a:excl_line_pattern ==# pattern || a:excl_line_pattern ==# 'all')

            call matchdelete(id)

        endif

        let idx += 1

    endwhile

endfunction
