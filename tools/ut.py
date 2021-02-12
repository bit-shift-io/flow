#-*- coding: utf-8 -*-

import os
import sys
import pathlib
import subprocess

#def get_cwd_path():
#    return pathlib.Path(os.path.abspath(os.getcwd()))

def get_src_path():
    return pathlib.Path(os.path.join(os.path.abspath(os.path.dirname(__file__)), '../src')) 

def get_godot_path(exe_pattern):
    if sys.platform.startswith('darwin'):
        exe_pattern = exe_pattern.replace('${os}', 'osx')

    if sys.platform.startswith('linux'):
        exe_pattern = exe_pattern.replace('${os}', 'linuxbsd')

    if sys.platform.startswith('win32'):
        exe_pattern = exe_pattern.replace('${os}', 'windows')
        exe_pattern += '.exe'

    path = pathlib.Path(os.path.abspath(os.getcwd()))
    godot_bin = pathlib.Path(os.path.join(path, 'build/godot/bin'))
    exe_path = pathlib.Path(os.path.join(godot_bin, exe_pattern))
    return exe_path


def run(cmd, cwd=None):
    proc = subprocess.Popen(cmd, shell=True, cwd=cwd, env=os.environ, encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    while True:
        output = proc.stdout.read(1)
        if len(output) == 0 and proc.poll() is not None:
            break
        if output:
            print(output, end='')