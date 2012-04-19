#!/usr/bin/env python
# -*- coding: utf-8 -*-
""" rtlo (UNICODE right-to-left override).

    Uses a neat trick to rename a file to look like an 
    JPEG file.

    Author: 0xd15ea5e (code@0xd15ea5e.com)

    Last Update:  20100211
    Created:      20100211

"""
import os
import sys

if __name__ == "__main__":
    try:
        orig = sys.argv[1]
    except:
        print("rtlo [filename]")
        exit(1)
    
    fname, fext = os.path.splitext(orig)
    try:
        os.rename(orig, fname + u"\u202Egpj" + fext)
    except:
        print("Error!")
        exit(1)
    print("OK.")
