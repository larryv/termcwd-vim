" autoload/termcwd/nsterm.vim - Apple Terminal
" --------------------------------------------
"
" SPDX-License-Identifier: MIT
"
" Copyright 2021-2023 Lawrence Velazquez
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


let s:saved_cpoptions = &cpoptions
set cpoptions&vim


" Sets Apple Terminal's current working directory to `dir` and current
" working document to `doc`.  If either is empty, tells Terminal to
" clear its corresponding state; otherwise, both `dir` and `doc` should
" be absolute paths, or the behavior is unspecified.
"
" `SendCtrlSeq` must be a Funcref to a function that accepts a control
" sequence [1][2] and sends it to the terminal.
function! termcwd#nsterm#SetCwds(dir, doc, SendCtrlSeq) abort
	" The sequences are intended to contain valid RFC 8089 'file'
	" URIs (<https://www.rfc-editor.org/rfc/rfc8089.html>).

	" TODO: What about remote paths?
	let l:enc_host = termcwd#PercentEncodeRegName(hostname())

	" Use termcwd#PercentEncode() with a custom pattern rather than
	" termcwd#PercentEncodePath() because ';' needs to be encoded in
	" paths, otherwise Terminal truncates them there.

	let l:unencoded_pat = '\m\C[/!$&''()*+,=:@]'

	if a:dir is ''
		let l:dir_seq = "\e]7;\7"
	else
		let l:enc_dir = termcwd#PercentEncode(a:dir, l:unencoded_pat)
		let l:dir_seq = "\e]7;file://" . l:enc_host . l:enc_dir . "\7"
	endif

	if a:doc is ''
		let l:doc_seq = "\e]6;\7"
	else
		let l:enc_doc = termcwd#PercentEncode(a:doc, l:unencoded_pat)
		let l:doc_seq = "\e]6;file://" . l:enc_host . l:enc_doc . "\7"
	endif

	call a:SendCtrlSeq(l:dir_seq . l:doc_seq)
endfunction


let &cpoptions = s:saved_cpoptions
unlet s:saved_cpoptions


" References
"
"  1. https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
"  2. https://en.wikipedia.org/wiki/C0_and_C1_control_codes
