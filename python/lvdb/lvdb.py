from IPython.core.debugger import Pdb
import os
import ipdb
import sys

class VimPdb(Pdb, object):
    """extends IPython Pdb by outputting 2 files on the interaction event

    .debug_location:    line 1 - current file, line 2 - line number

    .debug_breakpoint:  an even number of lines with
                        odd  lines - current file
                        even lines - list of breakpoints for that file
    """

    f_loc = ".debug_location"
    f_bpt = ".debug_breakpoint"

    def _process_location(self, frame):
        """logic for .debug_location"""

        #if frame information exists
        if frame and frame.f_code:

            #get the filename and line number
            fname = frame.f_code.co_filename
            l_num = frame.f_lineno

            #co_filename does not include the full path when the file is in
            #the current directory. To keep things consistent, prepend the
            #path if necessary
            if not os.path.isabs(fname):
                fname = os.getcwd() + os.sep + fname

            #write the 2 lines to .debug_location
            with open(self.f_loc, "w") as f:
                f.write("%s\n%s" % (fname, l_num))

    def _process_breakpoints(self):
        """logic for .debug_breakpoint

        if there are no breakpoints then remove the file

        if there are breakpoints, only update .debug_breakpoint when there has
        been a change. This is inferred if any of the following are true:

            1) self.breaks exists but there is no output file

            2) the length of self.breaks is inconsistent with the output file

                (self.breaks is a dictionary. when self.breaks is consistent
                with .debug_breakpoint, .debug_breakpoint will have 2 lines
                [file, breakpoint_list] for every entry. )

            3) the files listed in .debug_breakpoint are not found in
               self.breaks

            4) the breakpoints associated with files are not consistent
            between self.breaks and .debug_breakpoint

        If any of the above hold, then update the breakpoint file
        """

        #if there are no breakpoints, then remove the .debug_breakpoint file
        if not self.breaks:
            if os.path.isfile(self.f_bpt):
                os.remove(self.f_bpt)

        #otherwise, figure out whether the breakpoints have changed
        else:

            #case 1: there is no output file
            if not os.path.isfile(self.f_bpt):

                bps_changed = True

            else:

                #infer changes by comparing the output file to self.breaks
                with open(self.f_bpt, "r") as f:
                    lines = f.read().splitlines()

                bps_changed = False

                #case 2: the length of self.breaks is inconsistent with the
                #output file
                if (not lines) or (len(lines)/2 != len(self.breaks)):

                    bps_changed = True

                else:

                    if len(lines) % 2 == 0:
                        for i in range(int(len(lines)/2)):

                            #get the key (pathname)
                            k = lines[2*i]

                            #get the associated list of breakpoints
                            lnums = lines[2*i+1][1:-1].split(',')
                            lnums = [int(l) for l in lnums]

                            #case 3: files listed in .debug_breakpoint are not
                            #found in self.breaks
                            if not k in self.breaks:
                                bps_changed = True
                            else:

                                #case 4: breakpoints are not consistent within the
                                #file
                                bps_changed = ( str(lnums) != str(self.breaks[k]) )

                            if bps_changed:
                                #if any breakpoints have changed, there is no need
                                #to look further
                                break

            #update the output file if necessary
            if bps_changed:

                bp_str = ''

                for k in self.breaks:
                    bp_str += str(k) + '\n'
                    bp_str += str(self.breaks[k]) + '\n'

                bp_str = bp_str[:-1]

                with open(self.f_bpt, "w") as f:
                    f.write(bp_str)

    def interaction(self, frame, traceback):

        self._process_location(frame)
        self._process_breakpoints()
        super(VimPdb, self).interaction(frame, traceback)

def set_trace(frame=None):
    ''' recreates ipdb.set_trace() but uses VimPdb class rather than Pdb

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
    VimPdb('Linux').set_trace(frame)
