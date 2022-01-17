" autoload/termcwd/screen.vim - GNU screen
" ----------------------------------------
"
" SPDX-License-Identifier: MIT
"
" Copyright 2022 Lawrence Velázquez
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" 'Software'), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
" IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
" CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
" TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
" SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


" Passes the control sequence [1][2] `seq` through GNU `screen` to the
" underlying terminal.
function! termcwd#screen#SendCtrlSeq(seq) abort
    " Package `seq` into a Device Control String sequence by converting
    " ESC \ to ESC ESC \ ESC P \ and bookending with ESC P and ESC \.
    " (Quoting hell compels me to spell this out.)
    "
    " This seems poorly documented.  The `screen` manual [3] mentions
    " that DCS '[o]utputs a string directly to the host terminal without
    " interpretation' but says nothing about handling embedded ESC \.
    " After skimming the source [4], I wrongly concluded that it was
    " sufficient to imitate tmux and convert ESC to ESC ESC.  I realized
    " my mistake upon coming across a more general implementation in
    " Koichi Murase's ble.sh [5] that works within nested `screen`
    " instances (while mine didn't).  (I don't really understand why
    " Murase's approach works but mine didn't.  Maybe one day I'll
    " close-read the `screen` source, but that day is not today.)

    " Use a double-quoted literal for the substitute() replacement
    " argument because '\e' is not interpreted as ESC there.
    let l:seq = substitute(a:seq, '\C\e\\', "\e\e\\\\\eP\\\\", 'g')
    let l:seq = "\eP" . l:seq . "\e\\"
    call termcwd#SendCtrlSeq(l:seq)
endfunction


" References
"
"  1. https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
"  2. https://en.wikipedia.org/wiki/C0_and_C1_control_codes
"  3. https://www.gnu.org/software/screen/manual/html_node/Control-Sequences.html
"  4. https://git.savannah.gnu.org/cgit/screen.git/tree/src/ansi.c?h=v.4.2.0#n474
"  5. https://github.com/akinomyoga/ble.sh/blob/a3349e4a1748a7249ac3d2cd97ffe60457c2ad1a/src/util.sh#L5608-L5649
