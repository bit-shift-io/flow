#!/usr/bin/env python3
#-*- coding: utf-8 -*-

import os
import sys
import pathlib
import subprocess

path = pathlib.Path(os.path.abspath(os.getcwd()))


print(os.path.realpath(sys.argv[0]))
print(path)

cwd = pathlib.Path(os.path.join(path, 'build/godot/bin'))
print(cwd)

cmd = './godot.osx.tools.64 --editor --path {0}/src'.format(path)
print(cmd)
proc = subprocess.Popen(cmd, shell=True, cwd=cwd, env=os.environ, encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
while True:
    output = proc.stdout.read(1)
    if len(output) == 0 and proc.poll() is not None:
        break
    if output:
        print(output, end='')