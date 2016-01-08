''' command line wrapper for calling gdb '''
import subprocess
import argparse
import sysconfig
import os

def main():
    ''' main function '''

    parser = argparse.ArgumentParser(description='lvdb wrapper for gdb. Assumes .gdbinit contains at least "set logging on."')
    parser.add_argument("fname", help='a binary that to be called with gdb')
    parser.add_argument("-d", "--debug", action="store_true", help="whether to output debugging information in gdb_monitor.log")
    args = parser.parse_args()

    # start monitor with same version of python in the background
    # this is in case the default system version (say 2.6) does not have
    # IPython installed
    python_bin = 'python' + str(sysconfig.get_python_version())
    pid = subprocess.Popen([python_bin, '-c', "import lvdb; lvdb.monitor_gdb_file({})".format(args.debug)]).pid

    # start gdb (waiting until it exits)
    subprocess.call(['gdb', '-x', '.gdbinit', args.fname])

    # kill the gdb monitor and remove temporary files
    subprocess.call(['kill', str(pid)])

    for f in ['.debug_gdb_objs', '.debug_location', '.debug_breakpoint']:
        try:
            os.remove(f)
        except OSError:
            pass

if __name__ == '__main__':
    main()
