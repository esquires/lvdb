''' provides polling method/class to monitor gdb output '''
import os
import time
import re
import logging
import pprint

POLL_INTERVAL = 0.05

class LogHandler(object):
    ''' monitors gdb output (from "set logging on") and outputs 2 files for location/breakpoints
        
        one could use the watchdog module but the latency between a modified
        event and the "on_modified" call is too long to be of use
    '''

    FNAME_GDB = 'gdb.txt'
    FNAME_LOC = '.debug_location'
    FNAME_BRK = '.debug_breakpoint'

    def __init__(self, debug):

        logging.basicConfig(filename="gdb_monitor.log")
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.DEBUG if debug else logging.INFO)
        self.logger.debug('in __init__')

        self.active_fname = ""
        self.info_loc = [None, None]
        self.info_brk = []
        self.last_mod = -1

        if os.path.isfile(self.FNAME_GDB):
            self.on_modified()
        self.logger.debug('done with init')

    def _add_breakpoints(self, bp_num, ln_num, fname):

        found = False

        for i in range(len(self.info_brk)):

            if self.info_brk[i][0] == fname:

                if not ln_num in self.info_brk[i][1]:

                    self.info_brk[i][1].append(ln_num)
                    self.info_brk[i][2].append(bp_num)

                found = True
                break

        if not found:
            self.info_brk.append([fname, [ln_num], [bp_num]])

    def _delete_breakpoints(self, ln):

        # convert comma separated string to list
        bp_nums = []
        old_pos = len("Deleted breakpoint ")

        while True:

            pos_comma = ln.find(",", old_pos+1)
            pos_space = ln.find(" ", old_pos+1)

            if pos_space == -1 and pos_comma == -1:
                break
            elif pos_space >= 0 and pos_comma >= 0:
                pos = min(pos_comma, pos_space)
            elif pos_space == -1:
                pos = pos_comma
            elif pos_comma == -1:
                pos = pos_space

            bp_nums.append(int(ln[old_pos:pos]))
            old_pos = pos

        # delete breakpoints
        for num in bp_nums:

            for i in range(len(self.info_brk)):
                try:
                    pos = self.info_brk[i][2].index(num)
                    if len(self.info_brk[i][2]) == 1:
                        del self.info_brk[i]
                    else:
                        del self.info_brk[i][2][pos]
                        del self.info_brk[i][1][pos]
                    break
                except ValueError:
                    pass

    def on_modified(self):
        ''' parses the output of gdb and if there changes, update FNAME_BRK and FNAME_LOC '''

        if not os.path.isfile(self.FNAME_GDB) \
           or abs(self.last_mod - os.path.getmtime(self.FNAME_GDB)) < POLL_INTERVAL/10.0:
            return

        try:
            # read the file then clear it
            with open(self.FNAME_GDB, 'r') as f:
                lines = f.read().splitlines()

            self.logger.debug('processing file: {}'.format(self.FNAME_GDB))
            self.logger.debug('lines = {}'.format(pprint.pformat(lines)))

            if not lines:
                self.logger.debug('exiting'.format(pprint.pformat(lines)))
                return

            with open(self.FNAME_GDB, 'w') as f:
                pass

        except FileNotFoundError:
            return

        self.last_mod = os.path.getmtime(self.FNAME_GDB)
        info_loc_updated = False
        info_brk_updated = False

        for ln in lines:

            self.logger.debug('processing line: {}'.format(ln))

            if ln == '' or ln[0] == '$':

                self.logger.debug('empty/printed variable, doing nothing')
                continue

            elif ln[0:len("delete all breakpoints")] == "Delete all breakpoints":

                self.logger.debug('clearing info_brk')
                info_brk_updated = True
                self.info_brk = []

            elif ln[0:len("deleted")] == "Deleted":

                self._delete_breakpoints(ln)
                info_brk_updated = True
                self.logger.debug('info_brk = {}'.format(pprint.pformat(self.info_brk)))
                self.logger.debug('calling _delete_breakpoints({},{}).format(ln, info_brk)')
                self.logger.debug('info_brk = {}'.format(pprint.pformat(self.info_brk)))

            else:

                try:
                    ln_num = re.match(r"(\d+)\s", ln).group(1)
                    self.info_loc = [self.active_fname, ln_num]
                    info_loc_updated = True
                    self.logger.debug('line number update, info_loc = {}'.format(self.info_loc))
                    continue
                except AttributeError:
                    self.logger.debug('no line number update')

                try:
                    fname_pos = ln.index(" at ") + 4
                except ValueError:
                    continue

                try:
                    colon_pos = ln.index(":", fname_pos)
                except ValueError:
                    continue

                if ln[colon_pos-3:colon_pos] == 'use':
                    #Missing separate debuginfos, use: debuginfo-install glibc-2.12-1.149.el6_6.5.x86_64
                    continue

                fname = ln[fname_pos:colon_pos]
                fname = os.path.abspath(fname)

                self.logger.debug('fname = {}'.format(fname))

                if os.path.basename(fname)[:2] == '0x':

                    self.logger.debug('fname is a memory location, looking further in the line')
                    #Breakpoint 2 at 0x40050c: file sub/sub.c, line 4.
                    L = len("breakpoint ")
                    space_pos = ln.index(" ", L+1)
                    comma_pos = ln.index(",", colon_pos)
                    fname_pos = colon_pos + 7

                    fname = ln[fname_pos:comma_pos]
                    fname = os.path.abspath(fname)

                    ln_num = int(ln[comma_pos+7:-1])
                    bp_num = int(ln[L:space_pos])

                    self._add_breakpoints(bp_num, ln_num, fname)

                    self.logger.debug('self.activefname to {}, ln_num = {}'.format(fname, ln_num))
                    info_loc_updated = True
                    self.active_fname = fname

                elif ln[0:len("breakpoint")] == "Breakpoint":

                    self.logger.debug('this is a breakpoint line')

                    #Breakpoint 1, main () at temp.c:11
                    L = len("breakpoint ")
                    comma_pos = ln.index(",")

                    ln_num = int(ln[colon_pos+1:])
                    bp_num = int(ln[L:comma_pos])

                    self._add_breakpoints(bp_num, ln_num, fname)

                    self.logger.debug('updated fname to {}, ln_num = {}'.format(fname, ln_num))

                    self.active_fname = fname
                    info_loc_updated = True
                    info_brk_updated = True
                    self.logger.debug('updating self.active_fname to {}'.format(self.active_fname))

                else:

                    #hello_world () at sub/sub.c:4
                    try:
                        ln_num = int(ln[colon_pos+1:])
                    except ValueError:
                        continue

                    self.active_fname = fname
                    self.logger.debug('updated fname to {}, ln_num = {}'.format(fname, ln_num))
                    info_loc_updated = True
                    self.info_loc = [self.active_fname, ln_num]

        self.logger.debug('done looping through lines')

        if info_brk_updated:
            if self.info_brk:

                self.logger.debug('self.info_brk = {}'.format(pprint.pformat(self.info_brk)))

                s = ''
                for item in self.info_brk:
                    if type(item[1]) is int:
                        item[1] = [item[1]]

                    s += item[0] + '\n' + '[' + ", ".join([str(i) for i in item[1]]) + ']\n'
                s = s[:-1]

                with open(self.FNAME_BRK, 'w') as f:
                    f.write("%s" % s)

            else:
                _rm_file(self.FNAME_BRK)

        if info_loc_updated and self.info_loc:
            self.logger.debug('printing out info_loc = {}'.format(pprint.pformat(self.info_loc)))
            with open(self.FNAME_LOC, 'w') as f:
                f.write("%s\n%s" % (self.info_loc[0], self.info_loc[1]))

def _rm_file(f):
    try:
        os.remove(f)
    except OSError:
        pass

def monitor_gdb_file(debug=False):
    ''' sets up LogHandler and calls it every POLL_INTERVAL, exits on KeyboardInterrupt '''

    handler = LogHandler(debug)

    try:
        while True:
            time.sleep(POLL_INTERVAL)
            handler.on_modified()

    except KeyboardInterrupt:
        pass
