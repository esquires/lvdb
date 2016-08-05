lvdb
====

Links Vim to ipdb and gdb for lightweight but powerful debugging.

Installation
------------

This plugin requires vim to be compiled with the `+python` flag. If your
version of vim has this capability, the following command should give some
output. If it doesn't, one can recompile with `--enable-pythoninterp` set in
the configure script::

    vim --version | grep +python

Install python dependencies::

    pip install IPython ipdb

Install the Vim plugin

* If using Pathogen, then execute from the top level directory of this repo::

        ln -s $(pwd) ~/.vim/bundle/lvdb

* If not using Pathogen, Place the contents of `autoload`, `ftplugin`,
  `plugin`, and `syntax` in `~/.vim/autoload`, `~/.vim/ftplugin`,
  `~/.vim/plugin`, and `~/.vim/syntax`.

Install the python plugin:

    python setup.py install 

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
(setting breakpoints, etc) it is often nice to see absolute line numbers but
when moving around in Vim, it is nice to have relative numbering (to do things
like "4j" to move down 4 lines). To toggle this setting, set the following in
vimrc:

    let g:lvdb_toggle_lines = 0     # never toggles lines (default)
    let g:lvdb_toggle_lines = 1     # only toggle lines in *.py files when the vim debugging monitor is active
    let g:lvdb_toggle_lines = 2     # always toggle lines for *.py files
    let g:lvdb_toggle_lines = 3     # always toggle lines for all files

Sample Workflow (python debugging)
----------------------------------

1. cd into tests and open `temp.py`. Note that the vim pwd has to match the
   directory you are calling python from (i.e., ":pwd" in Vim must match "$
   pwd" in the shell). Notice that the `lvdb.set_trace()` line is highlighted.
   If it is not, then something is probably turning your syntax off.  Check
   your other plugins or vimrc. You can set syntax on by typing ":syntax on"

2. In vim, type `\d` to start the debug monitor

   (assuming you have set <localleader> to "\" as suggested in the
   settings/mappings section. You can set it to whatever you want though)

3. In the system shell (e.g., bash), type

        python temp1.py     # or from ipython, %run temp1.py

   ipdb will start and break at the `lvdb.set_trace()` line (this is a
   does the same thing as ipdb but outputs some debugging information so vim
   knows what line/file ipdb is at). In addition, Vim will jump to the same
   location.

4. To set a breakpoint (the commands below are native to pdb), from the
   system shell type

        b 11

   This will set a breakpoint at line 11 of `temp.py`. Now type

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

5. In Vim, type `\d` to end the debug monitor. This will also remove the
   outputs lvdb outputs when the set_trace command is hit.

Sample Workflow (gdb debugging)
-------------------------------

1. on the command line, cd into `lvdb/tests` and compile by typing:

        $ gcc -g -o temp temp1.c temp2.c

2. open `temp1.c` in vim and type "\d" to start the debug monitor

   (assuming you have set <localleader> to "\" as suggested in the
   settings/mappings section. You can set it to whatever you want though)

3. In the system shell (e.g., bash), type

        $ vim_gdb temp

   Note that `.gdbinit` contains `set logging on`. This file should always be
   in the directory you call vim_gdb from. This code will call `gdb temp` while
   also starting a monitor in the background. Notice that the cursor in vim has
   gone to line 11. In addition, because of the breakpoint, the line is
   highlighted red. Let's clear that breakpoint:

        (gdb) cl 11 

    Notice that the red highlight is now gone. Let's continue stepping through
    the code another 2 lines:

        (gdb) s
        (gdb) s

    Vim has opened `temp2.c` and put the cursor on the appropriate line. We can
    continue the code to the end:

        (gdb) c

4.  In Vim, type `\d` to end the debug monitor

Background
----------

ipdb and gdb are text-based debuggers. Although they can give code context with
the "list" command, it would be helpful to have vim highlight where you are in
the code. lvdb incorporates this functionality. Specifically, it

* updates the cursor line in vim to match where pdb is in the debugging process

* Highlights/deletes breakpoints that have been set on the fly in pdb. It also
  highlights lvdb.set_trace() lines when using lvdb.

lvdb has been designed to be simple and lightweight but give full access to
ipdb and gdb. For python, it does this as follows:

* The python installation makes sure 2 files are created when a
  `lvdb.set_trace()` is hit. These are `.debug_location` and `.debug_breakpoint`,
  and they contain the current state of the debugger.

* When the user tells Vim to start the debug monitor, Vim will monitor
  `.debug_location` and `.debug_breakpoint`. From `.debug_location`, it will
  set the cursor to match where ipdb is in the code. Thus, the user can follow
  where ipdb is within Vim. From `.debug_breakpoint`, Vim sets highlighting so
  the user can know where the breakpoint is located.

For gdb, it does this by having an external script monitor (see
`gdb_monitor.py` in the `python/lvdb` folder) that also updates
`.debug_breakpoint` and `.debug_location`.

License
----------

see LICENSE in the root directory
