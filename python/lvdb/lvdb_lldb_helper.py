#!/usr/bin/python
"""Wrapper code for lldb to interact with lvdb."""

import os
import lldb

LOG_FILE = "/tmp/lvdb.txt"


def command_generator(cmd):
    """Create a function that writes file_name:line_num to LOG_FILE."""
    def callback(debugger, command, result, internal_dict):
        lldb.debugger.HandleCommand(cmd + " " + command)

        target = debugger.GetSelectedTarget()
        process = target.GetProcess()
        thread = process.GetSelectedThread()
        frame = thread.GetSelectedFrame()
        line = frame.GetLineEntry()
        path = line.GetFileSpec().GetDirectory()
        fname = line.GetFileSpec().GetFilename()
        line_num = line.GetLine()

        try:
            full_fname = os.path.join(path, fname)
        except AttributeError:
            pass
        else:
            with open(LOG_FILE, "w") as f:
                f.write(full_fname + ":" + str(line_num))

    return callback


step_cmd = command_generator("step")
next_cmd = command_generator("next")
jump_cmd = command_generator("jump")
finish_cmd = command_generator("finish")
continue_cmd = command_generator("continue")
run_cmd = command_generator("run")
up_cmd = command_generator("up")
down_cmd = command_generator("down")


def __lldb_init_module(debugger, internal_dict):
    def cmd_str(func, alias):
        return debugger.HandleCommand(
            'command script add -f lvdb_lldb_helper.' + func + ' ' + alias)

    cmd_str('step_cmd', 's')
    cmd_str('next_cmd', 'n')
    cmd_str('jump_cmd', 'j')
    cmd_str('finish_cmd', 'fin')
    cmd_str('continue_cmd', 'c')
    cmd_str('run_cmd', 'r')
    cmd_str('run_cmd', 'u')
