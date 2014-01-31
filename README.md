hsalf
=====
disassembler & emulator for action script in flash(.swf)

caution) this is not fully implemented yet. some(many) action doesn't work

Usage
-----
    require './hsalf'

    f = Hsalf.new("flash.swf", actionscript_addr)
    f.disas # disassemble
    f.debug # emulation

feature
-------
emulation wil show each action corresponding local, global things. and perform proper stack operation or branching

if getvariable fails (no such name of variable), it ask to value to push in the stack.

    string: enclosing with double qoute ex) "string"
    number(hex): start with "0x" ex) 0x42
    anything else: convert into number (even if not number will be 0)

Blog
----
(will be written in Korean) Preparing...

Reference
---------
[http://www.m2osw.com/swf_alexref](http://www.m2osw.com/swf_alexref)

License
-------
The MIT License (MIT)

Copyright (c) 2014 ilumi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
