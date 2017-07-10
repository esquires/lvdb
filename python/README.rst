lvdb
====

Links Vim to ipdb and gdb for lightweight but powerful debugging. Vim does
*not* have to be compiled with "+python".

ipdb and gdb are text-based debuggers. Although they can give code context with
the "list" command, it would be helpful to have vim highlight where you are in
the code. lvdb incorporates this functionality.

Installation
------------

Install python dependencies (if you want to debug python. This is not necessary
for using gdb)::

    # ubuntu 16.04 or later
    # alternatively, sudo apt-get install ipython3 python3-ipdb python3-setuptools
    apt-get install ipython python-ipdb python3-setuptools

Install the Vim plugin (if using pathogen):

    cd ~/.vim/bundle
    git clone https://github.com/esquires/lvdb

Install the python plugin (only necessary for debugging python files):

    python setup.py install

Mappings/Settings
-----------------

To start/stop the vim debugging monitor:

    :call lvdb#Python_debug()

To toggle absolute and relative line numbers

    :call lvdb#ToggleNumber()

An example of mapping these commands is:

    let mapleader = "\<space>"
    nnoremap <leader>d :call lvdb#Python_debug()<cr>
    nnoremap <leader>n :call lines#ToggleNumber()<cr>

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

1. cd into tests and open `temp.py`. Notice that the `lvdb.set_trace()` line is
   highlighted.  If it is not, then something is probably turning your syntax
   off.  Check your other plugins or vimrc. You can set syntax on by typing
   ":syntax on"

2. In vim, type `\d` to start the debug monitor

   (assuming you have set <localleader> to "\" as suggested in the
   mappings/settings section. You can set it to whatever you want though)

3. In the system shell (e.g., bash), type

        python temp1.py

   lvdb will start and break at the `lvdb.set_trace()` line (this does the same
   thing as ipdb but outputs some debugging information so vim knows what
   line/file ipdb is at). In addition, vim will jump to the same location.

   You can now type "s" or "n" to step through the code as normal. Vim will
   update the active line or open a new tab if a new file is encountered in the
   code.

4. In Vim, type `\d` to end the debug monitor.

Sample Workflow (gdb debugging)
-------------------------------

1. Create a .gdbinit file with the following contents:
    
        set logging file /tmp/lvdb.txt
        set logging on

2. on the command line, cd into `lvdb/tests` and compile by typing:

        $ gcc -g -o temp temp1.c temp2.c

3. open `temp1.c` in vim and type "\d" to start the debug monitor

   (assuming you have set <localleader> to "\" as suggested in the
   settings/mappings section. You can set it to whatever you want though)

4. In the system shell (e.g., bash), type

        $ gdb -x .gdbinit -f temp

5. :T You can now type "s" or "n" to step through the code as normal. Vim will
   update the active line or open a new tab if a new file is encountered in the
   code.


6.  In Vim, type `\d` to end the debug monitor

License
----------

see LICENSE in the root directory
