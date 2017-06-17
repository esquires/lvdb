from IPython.core.debugger import Pdb
import os
import ipdb
import sys
from pprint import pprint

class Lvdb(Pdb, object):
    """extends IPython Pdb by outputting 2 files on the interaction event

    .debug_location: filename:line_num
    """
    f_loc = "/tmp/lvdb.txt"

    def __init__(self, *args, **kwargs):
        self.fname = None
        self.line = None
        super(Lvdb, self).__init__(*args, **kwargs)

    def interaction(self, frame, traceback):

        if frame and frame.f_code:

            fname = os.path.abspath(frame.f_code.co_filename)
            line = frame.f_lineno

            if fname != self.fname or line != self.line:
                with open(self.f_loc, "w") as f:
                    f.write(fname + ":" + str(line))

                self.fname = fname
                self.line = line

        # call ipdb as normal
        super(Lvdb, self).interaction(frame, traceback)

def set_trace(frame=None):
    ''' recreates ipdb.set_trace() but uses Lvdb class rather than Pdb

        calls most of the ipdb.set_trace functionality and then does the rest
        manually. this is required because the internal functions update_stdout
        and wrap_sys_excepthook are not made available in the ipdb.__init__
        script

    '''
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
