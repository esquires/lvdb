vim-pdb
===

Links Vim to ipdb for lightweight but powerful debugging

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

            1) place vim-pdb directory in .vim/bundle
            2) In vim, run ":Helptags"

    b)  If not using Pathogen,

            1) place vim-pdb contents in .vim/
            2) In vim, run ":helptags"

    c)  Anytime you need help, just type ":h vim_pdb.txt"

Install the VimPdb python plugin:

    cd vim_pdb/python_pkg

    python setup.py install

    The code contained in this small package inherits the IPython debugger
    object, which inherits from PDB. The only addition is that it creates 2
    files while ipdb is running: .debug_location and .debug_monitor.

Alter ipdb slightly:

    We now need to tell ipdb to use the object installed in the above step.

    1)  find where ipdb is installed

        locate ipdb/__main__.py

        if locate is not installed on your system, just search under
        python/site-packages. The directory where __main__.py will be
        called <dir> below.

    2)  open <dir>/__main__.py and change the following lines

        original

            from IPython.core.debugger import Pdb, BdbQuit_excepthook

        altered

            from vim_pdb import VimPdb as Pdb
            from IPython.core.debugger import BdbQuit_excepthook

Mappings/Settings
----------

To start the vim debugging monitor (can also be called with ":call vim_pdb#Python_debug()")

    <localleader>d
    or
    :call vim_pdb#Python_debug()

To toggle absolute and relative line numbers

    <localleader>n
    or
    :call vim_pdb#ToggleNumber()

If you don't have a local leader set, put the following in your .vimrc

    let maplocalleader = "\\"

vim_pdb will also toggle line numbers automatically if you desire (see :h rnu
and :h nu for details). When debugging (setting breakpoints, etc) to see
absolute line numbers but when moving around in Vim, it is nice to have
relative numbering (to do things like "4j" to move down 4 lines). To toggle
this setting, set the following in vimrc:

    let g:vim_pdb_toggle_lines = 0

        never toggles lines (default)

    let g:vim_pdb_toggle_lines = 1

        only toggle lines in *.py files when the vim debugging monitor is
        active

    let g:vim_pdb_toggle_lines = 2

        always toggle lines for *.py files

    let g:vim_pdb_toggle_lines = 3

        always toggle lines for all files

Background
----------

ipdb is a text-based debugger. Although it can give code context with the
"list" command, it would be helpful to have VIM highlight where you are in
the code. vim-pdb incorporates this functionality. Specifically, it

    1) updates the cursor line in vim to match where pdb is in the
       debugging process
    2) Highlights/deletes breakpoints that have been set on the fly in
       pdb. It also highlights pdb.set_trace() lines.

The vim-pdb debugger has been designed to be simple and lightweight but
give full access to IPython and ipdb. It does this as follows:

    1) The python installation (see steps c and d in
       |vim_pdb_installation|) makes sure 2 files are created when ipdb is
       running. These are .debug_location and .debug_breakpoint, and they
       contain the current state of the debugger.

    2) When the user tells Vim to start the debug monitor, Vim will
       monitor .debug_location and .debug_breakpoint. From
       .debug_location, it will set the cursor to match where ipdb is in
       the code. Thus, the user can follow where ipdb is within Vim. From
       .debug_breakpoint, Vim sets highlighting so the user can know where
       the breakpoint is located.

For a more advanced Vim-based python debugger, see Pyclewn:
http://pyclewn.sourceforge.net/

Sample Workflow
------------------

a)  Put the following 2 files in some directory called \<dir\>:

    -------------------------       |       -------------------------
    <dir>/temp.py                   |       <dir>/temp2.py
    -------------------------       |       -------------------------
                                    |
    import temp2                    |       def mult(a,b):
    import ipdb                     |           return a * b
                                    |
    def main():                     |       def div(a,b):
        a = 1                       |           return a / b
        ipdb.set_trace()            |
        b = 2                       |
        c = temp2.mult(a,b)         |
        d = temp2.div(a,b)          |
                                    |
        print 'a = ' + str(a)       |
        print 'b = ' + str(b)       |
        print 'c = ' + str(c)       |
        print 'd = ' + str(d)       |
                                    |
    if __name__ == '__main__':      |
        main()                      |

b) open temp.py. Notice that the "ipdb.set_trace()" line is highlighted

   (if it is not, then something is probably turning your syntax off.
   Check your other plugins or vimrc. You can set syntax on by typing
   ":syntax on")

c) In vim, type "\d" to start the debug monitor

   (assuming you have set <localleader> to "\" as suggested in the
   settings/mappings section. You can set it to whatever you want though)

d) In the system shell (e.g., bash), cd into \<dir\> and type

        python temp.py

   ipdb will start and break at the "ipdb.set_trace()" line (this is a
   normal function of ipdb). In addition, Vim will jump to the same
   location.

e) To set a breakpoint (the commands below are native to pdb), from the
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

f)  In Vim, type "\d" to end the debug monitor

License
----------

see LICENSE in the root directory
