lvdb
====

Links Vim to ipdb and gdb for lightweight but powerful debugging.

Installation
------------

Check Dependencies

    1)  vim --version | grep +python

        if there is no outupt to this command, recompile vim with the
        python flag enabled (something along the lines of ./configure
        --enable-pythoninterp)

    2)  pip install IPython

    3)  pip install ipdb

Install the Vim plugin

    a)  If using Pathogen,

            1) place lvdb/vim_pkg directory in .vim/bundle
            2) In vim, run ":Helptags"

    b)  If not using Pathogen,

            1) place lvdb/vim_pkg contents in .vim/
            2) In vim, run ":helptags"

    c)  Anytime you need help, just type ":h lvdb.txt"

Install the VimPdb python plugin:

    Eventually this will be a pip package and one can simply execute

        pip install lvdb

    Until then, we will add the lvdb/python_pkg to the PYTHONPATH

        cd lvdb/python_pkg
        export PYTHONPATH=$PYTHONPATH:$(pwd):$(pwd)/bin
        echo "export PYTHONPATH=$PYTHONPATH:$(pwd)" >> ~/.bashrc
        export PATH=$PATH:$(pwd)/bin

    The code contained in this small package inherits the IPython debugger
    object, which inherits from PDB. The only addition is that it creates 2
    files while ipdb is running: .debug_location and .debug_monitor.

Mappings/Settings
-----------------

To start the vim debugging monitor (can also be called with ":call lvdb#Python_debug()")

    <localleader>d
    or
    :call lvdb#Python_debug()

To toggle absolute and relative line numbers

    <localleader>n
    or
    :call lvdb#ToggleNumber()

If you don't have a local leader set, put the following in your .vimrc

    let maplocalleader = "\\"

lvdb will also toggle line numbers automatically if you desire (see :h rnu and
:h nu for details. The toggling is only available for gvim). When debugging
(setting breakpoints, etc) to see absolute line numbers but when moving around
in Vim, it is nice to have relative numbering (to do things like "4j" to move
down 4 lines). To toggle this setting, set the following in vimrc:

    let g:lvdb_toggle_lines = 0

        never toggles lines (default)

    let g:lvdb_toggle_lines = 1

        only toggle lines in *.py files when the vim debugging monitor is
        active

    let g:lvdb_toggle_lines = 2

        always toggle lines for *.py files

    let g:lvdb_toggle_lines = 3

        always toggle lines for all files

Background
----------

ipdb and gdb are text-based debuggers. Although they can give code context with
the "list" command, it would be helpful to have vim highlight where you are in
the code. lvdb incorporates this functionality. Specifically, it

    1) updates the cursor line in vim to match where pdb is in the
       debugging process
    2) Highlights/deletes breakpoints that have been set on the fly in
       pdb. It also highlights lvdb.set_trace() lines when using lvdb.

The lvdb debugger has been designed to be simple and lightweight but
give full access to ipdb and gdb. For python, it does this as follows:

    1) The python installation (see steps c and d in |lvdb_installation|) makes
       sure 2 files are created when a lvdb.set_trace() is hit. These are
       .debug_location and .debug_breakpoint, and they contain the current
       state of the debugger.

    2) When the user tells Vim to start the debug monitor, Vim will
       monitor .debug_location and .debug_breakpoint. From
       .debug_location, it will set the cursor to match where ipdb is in
       the code. Thus, the user can follow where ipdb is within Vim. From
       .debug_breakpoint, Vim sets highlighting so the user can know where
       the breakpoint is located.

For gdb, it does this by having an external script monitor (see gdb\_monitor.py
in the python\_pkg folder) that also updates .debug\_breakpoint and
.debug\_location.

For a more advanced Vim-based python debugger, see Pyclewn:
http://pyclewn.sourceforge.net/

Sample Workflow (python debugging)
----------------------------------

a) cd into tests and open temp.py. Note that the vim pwd has to match the
   directory you are calling python from (i.e., ":pwd" in Vim must match "$
   pwd" in the shell). Notice that the "lvdb.set_trace()" line is highlighted.
   If it is not, then something is probably turning your syntax off.  Check
   your other plugins or vimrc. You can set syntax on by typing ":syntax on"

b) In vim, type "\d" to start the debug monitor

   (assuming you have set <localleader> to "\" as suggested in the
   settings/mappings section. You can set it to whatever you want though)

c) Type

        python temp1.py     # or from ipython, %run temp1.py

   ipdb will start and break at the "lvdb.set_trace()" line (this is a
   does the same thing as ipdb but outputs some debugging information so vim
   knows what line/file ipdb is at). In addition, Vim will jump to the same
   location.

d) To set a breakpoint (the commands below are native to pdb), from the
   system shell type

        b 11

   This will set a breakpoint at line 11 of temp.py. Now type

        s

   to step 1 line forward in the code. You should see Vim now highlight
   line 11 as well. You can now type

        c

   and the code will run to the newly established breakpoint. Type

        cl

   to clear the breakpoint. and

        s

   to step again. You should see the breakpoint cleared in Vim. In
   addition to the above commands, all the niceties of IPython and ipdb
   are available from the shell, including object inspection, tab
   completion, etc.

e) In Vim, type "\d" to end the debug monitor. This will also remove the
   outputs lvdb outputs when the set_trace command is hit.

Sample Workflow (gdb debugging)
-------------------------------

a) on the command line, cd into lvdb/tests and compile by typing:

        $ gcc -g -o temp temp1.c temp2.c

b) open temp1.c in vim and type "\d" to start the debug monitor

   (assuming you have set <localleader> to "\" as suggested in the
   settings/mappings section. You can set it to whatever you want though)

c) In the system shell (e.g., bash), type

        $ vim_gdb temp

   Note that ".gdbinit" contains "set logging on". This file should always be
   in the directory you call vim_gdb from. This code will call "gdb temp" while
   also starting a monitor in the background. Notice that the cursor in vim has
   gone to line 11. In addition, because of the breakpoint, the line is
   highlighted red. Let's clear that breakpoint:

        (gdb) cl 11 

    Notice that the red highlight is now gone. Let's continue stepping through
    the code another 2 lines:

        (gdb) s
        (gdb) s

    Vim has opened temp2.c and put the cursor on the appropriate line. We can
    continue the code to the end:

        (gdb) c

e)  In Vim, type "\d" to end the debug monitor

License
----------

see LICENSE in the root directory
