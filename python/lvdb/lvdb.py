import os
import sys

from IPython.core.debugger import decorate_fn_with_doc
from IPython.terminal.debugger import TerminalPdb
import ipdb


class Lvdb(TerminalPdb, object):
    """extends IPython Pdb by outputting 2 files on the interaction event.

    .debug_location: filename:line_num
    """

    f_loc = "/tmp/lvdb.txt"

    def __init__(self, *args, **kwargs):
        self.fname = None
        self.line = None
        self.orig_cwd = os.getcwd()
        super(Lvdb, self).__init__(*args, **kwargs)

    def _write_frame(self, frame):
        if frame and frame.f_code:

            fname = os.path.join(self.orig_cwd, frame.f_code.co_filename)
            line = frame.f_lineno

            if fname != self.fname or line != self.line:
                with open(self.f_loc, "w") as f:
                    f.write(fname + ":" + str(line))

                self.fname = fname
                self.line = line

    def do_jump(self, line_number):
        with open(self.f_loc, "w") as f:
            f.write(self.fname + ':' + str(line_number))
        return super(Lvdb, self).do_jump(line_number)

    def do_where(self, arg):
        line_number = int(arg) if arg else self.line
        with open(self.f_loc, "w") as f:
            f.write(self.fname + ':' + str(line_number))
        return super(Lvdb, self).do_where(arg)

    def interaction(self, frame, traceback):
        self._write_frame(frame)
        super(Lvdb, self).interaction(frame, traceback)

    def new_do_up(self, arg):
        super(Lvdb, self).new_do_up(arg)
        self._write_frame(self.curframe)

    do_u = do_up = decorate_fn_with_doc(new_do_up, TerminalPdb.do_up)

    def new_do_down(self, arg):
        super(Lvdb, self).new_do_down(arg)
        self._write_frame(self.curframe)

    do_d = do_down = decorate_fn_with_doc(new_do_down, TerminalPdb.do_down)


def set_trace(frame=None):
    """Recreates ipdb's set_trace but uses Lvdb class rather than Pdb.

    calls most of the ipdb.set_trace functionality and then does the rest
    manually. this is required because the internal functions update_stdout
    and wrap_sys_excepthook are not made available in the ipdb.__init__
    script
    """
    try:
        ipdb.set_trace("a string as the frame argument causes an AttributeError")
    except AttributeError:
        pass

    if frame is None:
        frame = sys._getframe().f_back

    # 'Linux' is the color definition. For a cross-platform implementation, see
    # from IPython import get_ipython
    # def_colors = get_ipython().colors
    # on a linux system, def_colors will be 'Linux'
    # if a need arises this will be made cross-platform
    Lvdb('Linux').set_trace(frame)
