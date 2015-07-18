import os
import pickle
import time
import re

fname_gdb = 'gdb.txt'
fname_loc = '.debug_location'
fname_brk = '.debug_breakpoint'
fname_pkl = '.debug_gdb_objs'

def _rm_file(f):
    if os.path.isfile(f):
        os.remove(f)

def _delete_breakpoints(ln, info_brk):

    # convert comma separated string to list
    bp_nums = []
    old_pos = len("Deleted breakpoint ")

    while True:

        pos_comma = ln.find(",",old_pos+1)
        pos_space = ln.find(" ",old_pos+1)

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

        for i in range(len(info_brk)):
            try:
                pos = info_brk[i][2].index(num)
                if len(info_brk[i][2]) == 1:
                    del info_brk[i]
                else:
                    del info_brk[i][2][pos]
                    del info_brk[i][1][pos]
                break
            except:
                pass

    return info_brk

def _add_breakpoints(bp_num, info_brk, ln_num, fname):

    found = False

    for i in range(len(info_brk)):

        if info_brk[i][0] == fname:

            if not ln_num in info_brk[i][1]:

                info_brk[i][1].append(ln_num)
                info_brk[i][2].append(bp_num)

            found = True
            break

    if not found:
        info_brk.append( [ fname, [ln_num], [bp_num] ] )

    return info_brk

def _monitor_gdb_file_helper():

    if not os.path.isfile(fname_gdb):
        return

    ############################################################
    # initialization
    ############################################################

    info_loc = []

    pwd = os.getcwd() + os.sep
    try:
        with open(fname_gdb, 'r') as f:
            lines_gdb = f.read().splitlines()
    except:
        #file not found so exit
        return

    try:
        info_brk, mod_time_gdb, active_fname = pickle.load(open(fname_pkl, 'rb'))
    except IOError:
        info_brk, mod_time_gdb, active_fname = [], -1, ""

    if not os.path.isfile(fname_brk):
        info_brk = []

    if mod_time_gdb == os.path.getmtime(fname_gdb):
        return

    ############################################################
    # parsing: output info_loc, info_brk
    ############################################################
    for ln in lines_gdb:

        if ln == '' or ln[0] == '$':
            #user just printed a variable or line is blank
            continue
        elif ln[0:len("delete all breakpoints")] == "Delete all breakpoints":
            info_brk = []

        elif ln[0:len("deleted")] == "Deleted":
            bp_nums = _delete_breakpoints(ln, info_brk)

        else:

            try:
                ln_num = re.match("(\d+)\s", ln).group(1)
                info_loc = [active_fname, ln_num]
                continue
            except AttributeError:
                pass

            try:
                fname_pos = ln.index(" at ") + 4
            except ValueError:
                continue

            try:
                colon_pos = ln.index(":", fname_pos)
            except:
                #No breakpoint at this line.
                continue

            if ln[colon_pos-3:colon_pos] == 'use':
                #Missing separate debuginfos, use: debuginfo-install glibc-2.12-1.149.el6_6.5.x86_64
                continue

            fname = ln[fname_pos:colon_pos]
            fname = os.path.abspath(fname)

            if os.path.basename(fname)[:2] == '0x':

                #Breakpoint 2 at 0x40050c: file sub/sub.c, line 4.
                L = len("breakpoint ")
                space_pos = ln.index(" ", L+1)
                comma_pos = ln.index(",", colon_pos)
                fname_pos = colon_pos + 7

                fname = ln[fname_pos:comma_pos]
                fname = os.path.abspath(fname)

                ln_num = int(ln[comma_pos+7:-1])
                bp_num = int(ln[L:space_pos])

                info_brk = _add_breakpoints(bp_num, info_brk, ln_num, fname)
                if not active_fname:
                    active_fname = fname


            elif ln[0:len("breakpoint")] == "Breakpoint":

                #Breakpoint 1, main () at temp.c:11
                L = len("breakpoint ")
                comma_pos = ln.index(",")

                ln_num = int(ln[colon_pos+1:])
                bp_num = int(ln[L:comma_pos])

                info_brk = _add_breakpoints(bp_num, info_brk, ln_num, fname)
                if not active_fname:
                    active_fname = fname
            else:

                #hello_world () at sub/sub.c:4
                try:
                    ln_num = int(ln[colon_pos+1:])
                except ValueError:
                    continue

                active_fname = fname
                info_loc = [active_fname, ln_num]

    ############################################################
    # printout
    ############################################################
    if info_brk:

        s = ''
        for item in info_brk:
            if type(item[1]) is int:
                item[1] = [item[1]]

            s += item[0] + '\n' + '[' + ", ".join([str(i) for i in item[1]]) + ']\n'
        s = s[:-1]

        with open(fname_brk, 'w') as f:
            f.write("%s" % s)

    else:
        _rm_file(fname_brk)

    if info_loc:
        with open(fname_loc, 'w') as f:
            f.write("%s\n%s" % (info_loc[0], info_loc[1]))

    ############################################################
    # setup for next run
    ############################################################
    L = len(lines_gdb)
    with open(fname_gdb) as f:
        lines_gdb = f.readlines()

    with open(fname_gdb, 'w') as f:
        f.write("".join(lines_gdb[L:]))

    pickle.dump( (info_brk, os.path.getmtime(fname_gdb), active_fname), open(fname_pkl, "wb"))

def monitor_gdb_file():

    pickle.dump( ([], -1, ""), open(fname_pkl, "wb"))

    while True:
        time.sleep(0.05)
        _monitor_gdb_file_helper()
