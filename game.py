#!/usr/bin/env python3
#-*- coding: utf-8 -*-

import sys
sys.path.append('tools')
import ut

cmd = '{0} --path {1}'.format(ut.get_godot_path('godot.${os}.tools.64'), ut.get_src_path())
print(cmd)
ut.run(cmd)