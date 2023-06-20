" autoload/termcwd.vim - Shared functions
" ---------------------------------------
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


" Returns `str`, percent-encoded as per RFC 3986 [1].  The argument is
" not required to be in any particular text encoding.
"
" Unreserved characters [2] are left unencoded.  If other characters
" must be also, a pattern can be provided as the second argument; each
" byte of `str` is individually tested against the pattern and is output
" unencoded if it matches.  The pattern should work independently of
" 'magic', 'ignorecase', 'smartcase', and 'cpoptions', as no particular
" default behavior is guaranteed.  Portability techniques include:
"
"   - Always using '\v', '\m', '\M', or '\V'.
"   - Always using '\c' or '\C'.
"   - Inside '[...]' and friends, always using '\\' to represent '\' and
"     never using '\' for anything else.
function! termcwd#PercentEncode(str, ...) abort
	" 'a:str[v:val]' does not work bytewise in Vim 9 script.
	let l:bytes = map(range(strlen(a:str)), 'strpart(a:str, v:val, 1)')

	" Constructing this literal in-function looks wasteful but is
	" just as fast as accessing predefined script-local Dictionary
	" entries and is more legible to boot.  Use '\w' to match common
	" bytes a bit faster than '[0-9A-Za-z_]'.
	let l:encoding_expr = 'v:val =~# ''\w\|[-.~]'''
	if a:0 >= 1
		let l:encoding_expr .= ' || v:val =~# a:1'
	endif
	let l:encoding_expr .= ' ? v:val : printf("%%%02X", char2nr(v:val))'

	return join(map(l:bytes, l:encoding_expr), '')
endfunction


" Returns `path`, percent-encoded [1] like an RFC 3986 'path-abempty',
" 'path-absolute', 'path-rootless', or 'path-empty' component [3].  The
" argument is not required to be in any particular text encoding.
function! termcwd#PercentEncodePath(path) abort
	return termcwd#PercentEncode(a:path, '\m\C[/!$&''()*+,;=:@]')
endfunction


" Returns `name`, percent-encoded [1] as an RFC 3986 'reg-name' sub-
" component [4].  The argument is not required to be in any particular
" text encoding or have any particular syntax.
function! termcwd#PercentEncodeRegName(name) abort
	return termcwd#PercentEncode(a:name, '\m\C[!$&''()*+,;=]')
endfunction


" Sends the control sequence [5][6] `seq` to the terminal, treating it
" literally (e.g., '\e' is not interpreted as ESC).  The sequence must
" not produce visible output.
"
" This implementation requires that the printf(1) utility be available
" as a shell builtin or via PATH and that shell-related options (e.g.,
" 'shell', 'shellcmdflag', 'shellquote', 'shellxquote') have values that
" are not too unusual.  To reduce the number of printf(1) invocations,
" a caller sending multiple sequences should consider concatenating them
" and making just one call.
function! termcwd#SendCtrlSeq(seq) abort
	" Callers should not be passing in non-Strings.
	let l:seq = a:seq . ''

	" Don't waste time sending the same sequence repeatedly.
	if !exists('s:prev_seq') || l:seq !=# s:prev_seq
		" I would love to do this in a simple, 'Vim-native' way.
		" My first attempt hijacked 'title' [7], and initial
		" versions of this plugin used 'icon', but I don't like
		" commandeering user options.  Using '!printf' works but
		" imposes restrictions on shell-related options and is
		" slower than I'd like.
		execute 'silent !printf "\%s" ' . shellescape(l:seq, 1)
		let s:prev_seq = l:seq
	endif
endfunction


let &cpoptions = s:saved_cpoptions
unlet s:saved_cpoptions


" References
"
"  1. https://www.rfc-editor.org/rfc/rfc3986.html#section-2.1
"  2. https://www.rfc-editor.org/rfc/rfc3986.html#section-2.3
"  3. https://www.rfc-editor.org/rfc/rfc3986.html#section-3.3
"  4. https://www.rfc-editor.org/rfc/rfc3986.html#section-3.2.2
"  5. https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
"  6. https://en.wikipedia.org/wiki/C0_and_C1_control_codes
"  7. https://github.com/larryv/vimfiles/commit/353a2a35a1d2e51c11932eae075147775a27e597
