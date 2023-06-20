" autoload/termcwd/tmux.vim - tmux
" --------------------------------
"
" SPDX-License-Identifier: MIT
"
" Copyright 2022-2023 Lawrence Velazquez
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


" Passes the control sequence [1][2] `seq` through tmux [3] to the
" underlying terminal.
function! termcwd#tmux#SendCtrlSeq(seq) abort
	let l:seq = "\ePtmux;" . substitute(a:seq, '\C\e', '\0\0', 'g') . "\e\\"
	call termcwd#SendCtrlSeq(l:seq)
endfunction


" References
"
"  1. https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
"  2. https://en.wikipedia.org/wiki/C0_and_C1_control_codes
"  3. https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it
