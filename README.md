vim-pdb
===

Links Vim to pdb for lightweight but powerful debugging

Installation
------------

Dependencies

    1) Bash - this might work with other shells but has not been tested
    2) tee - a command line utility
    3) vim is compiled with python support. To check, type into Bash:

         vim --version | grep +python

Installation

    If using Pathogen,

        1) place vim-pdb directory in .vim/bundle
        2) In vim, run ":Helptags"
        3) Anytime you need help, just type ":h vim_pdb.txt"

    If not using Pathogen,

        1) place vim-pdb contents in .vim/
        2) In vim, run ":helptags"
        3) Anytime you need help, just type ":h vim_pdb.txt"

    If you don't have a local leader set, put the following in your .vimrc

        let maplocalleader = "\\"

Background
----------

        pdb is a text-based debugger. Although it can give code context with the
        "list" command, it would be helpful to have VIM highlight where you are
        in the code. vim-pdb incorporates this functionality. Specifically, it

        1) updates the cursor line in vim to match where pdb is in the
           debugging process
        2) Highlights/deletes breakpoints that have been set on the fly in pdb.
           It also highlights pdb.set_trace() lines.

        The vim-pdb debugger has been designed to be simple and lightweight.
        For a more advanced Vim-based python debugger, see Pyclewn:
        http://pyclewn.sourceforge.net/

Sample Workflow
------------------

This workflow is written out explicitly. After getting used to it, this
should take less than 5 seconds to initially get started. Repeated runs
just involves repeating step 4

1) In Bash, cd into the directory of the script you want to debug

        cd directory

2) In Vim,

    a) make sure the Vim directory is the same as the code to debug

        :cd directory

    b) place breakpoints in your code as desired using pdb.set_trace()

    c) type "\D"

3) Set Bash and Vim side by side so you can see both windows.

4) In Bash, type

    python -u yourscript.py | tee .debug

5) Use pdb in Bash like normal (inspecting variables, stepping, etc).
   Vim will automatically update the current file/line as pdb changes.

6) In Vim, type "\D"

Extra Details
----------------

*python -u scriptname.py | tee .debug

    The "-u" tells python to keep unloading its buffer (i.e., keep
    printing its output). Piping to "tee" keeps stdout as well as
    sending output to the file ".debug".

*localleader_d or localleader_D*

    This tells Vim to monitor changes in the ".debug" file that is
    being piped from Bash. After reading the file, Vim will
    automatically find the line number and file that pdb is currently
    on (it will open a new tab if the file is not currently open). The
    same is true when breakpoints are added/deleted.

    The difference between |localleader_d| and |localleader_D| is
    whether the ".debug" file is cleared. The former does not clear
    the file while the latter does. Unless you want to make changes to
    Vim files, just use |localleader_D|.

    Note that |localleader_d| and |localleader_D| are mappings for the
    following function calls:

        |localleader_d|    maps to  :call python_debug#Python_debug(0)
        and
        |localleader_d|    maps to  :call python_debug#Python_debug(1)

License
----------

        see LICENSE in the root directory
