" plugin/termcwd.vim
" -------------------
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


" Avoid line continuations before resetting 'cpoptions'.
if exists('g:loaded_termcwd') | finish | endif
if has('gui_running') | finish | endif
if !has('autocmd') | finish | endif
if !has('modify_fname') | finish | endif

let g:loaded_termcwd = 1

let s:saved_cpoptions = &cpoptions
set cpoptions&vim


" Basic autocommand handler.  Tells the terminal to update its current
" directory and document based on buffer type.  The `doc` argument is
" expected to be an absolute path, although it is not always used.
function! s:BasicHandler(doc) abort
	if &buftype ==# '' || &buftype ==# 'nowrite' || &buftype ==# 'help'
		" The buffer is associated with a file.
		let l:dir = getcwd()
		let l:doc = a:doc
	elseif &buftype ==# 'terminal' || &buftype ==# 'prompt'
		" The buffer is intended for use with external jobs.
		let l:dir = ''
		let l:doc = ''
	else
		" The buffer is not associated with a file.
		let l:dir = getcwd()
		let l:doc = ''
	endif
	call s:SetCwds(l:dir, l:doc, s:SendCtrlSeq)
endfunction


" Handler for BufEnter events.  Calls the standard handler except for
" a spurious event that occurs while opening the help window.  (There
" are other such events, but I can't pick them out easily.)
function! s:BufEnterHandler() abort
	if &buftype !=# 'help' || expand('<amatch>') isnot ''
		call s:StdHandler()
	endif
endfunction


" Handler for BufFilePost events.  Calls the standard handler except for
" spurious events that occur while opening terminal buffers and the
" command-line window.  (Those buffers don't have their final type yet,
" so this implementation checks their names.  Hope anyone who wants to
" rename a file '[Command Line]' is okay with the proxy icon being stale
" until they switch windows or buffers.)
"
" TODO: Look into whether the quickfix window needs similar treatment.
" TODO: See if getcmdwintype() would be useful for this.
function! s:BufFilePostHandler() abort
	if expand('<afile>') !=# '[Command Line]' && expand('<amatch>')[0] !=# '!'
		call s:StdHandler()
	endif
endfunction


" Returns a Funcref to a function that accepts a control sequence [1][2]
" as a String argument and passes it to the underlying terminal.
function! s:ChooseSendCtrlSeq() abort
	" TODO: Look into handling Vim terminal buffers.
	if $TMUX isnot ''
		let l:sendctrlseq = 'termcwd#tmux#SendCtrlSeq'
	elseif &term =~# '^screen\d*\%(-[^-]\|\.[^.]\|$\)'
	            \ || $TERMCAP =~# '^SC|screen\d*\%(-[^-]\|\.[^.]\|[|:]\)'
		let l:sendctrlseq = 'termcwd#screen#SendCtrlSeq'
	else
		let l:sendctrlseq = 'termcwd#SendCtrlSeq'
	endif

	if v:version < 702 || (v:version == 702 && !has('patch061'))
		" Creating an autoloading Funcref fails if the
		" function's script hasn't been sourced yet.  Call the
		" function to force sourcing, but intentionally pass too
		" few arguments so it does nothing.
		try
			call call(l:sendctrlseq, [])
		catch /\m\C^Vim(call):E119:/
		endtry
	endif

	return function(l:sendctrlseq)
endfunction


" Returns a Funcref to a function that can set the terminal's current
" directory and document.  The function accepts a directory path as the
" first argument, a file path as the second, and a Funcref returned by
" s:ChooseSendCtrlSeq() as the third.  Either path argument may be empty
" to indicate that the corresponding state should be cleared.  Arguments
" that the terminal cannot use are ignored.
"
" Throws an exception if the current terminal is not supported.
function! s:ChooseSetCwds() abort
	" TODO: Identify terminals in tmux sessions, where TERM_PROGRAM
	" and TERM are changed.  Turns out that `tmux show-environment`
	" doesn't do what I need, so I don't know what to try now.
	if $TERM_PROGRAM ==# 'Apple_Terminal'
	            \ || &term =~# '^nsterm-\|^nsterm$\|^Apple_Terminal$'
		let l:setcwds = 'termcwd#nsterm#SetCwds'
	else
		throw 'termcwd(ChooseSetCwds):unsupported terminal'
	endif

	if v:version < 702 || (v:version == 702 && !has('patch061'))
		" Creating an autoloading Funcref fails if the
		" function's script hasn't been sourced yet.  Call the
		" function to force sourcing, but intentionally pass too
		" few arguments so it does nothing.
		try
			call call(l:setcwds, [])
		catch /\m\C^Vim(call):E119:/
		endtry
	endif

	return function(l:setcwds)
endfunction


" Standard autocommand handler.  Calls the basic handler if the event
" applies to the current buffer.  The argument is optional and is passed
" to the basic handler.  If it is omitted, the default is the expansion
" of '<amatch>' because that is often an absolute path with intermediate
" symbolic links resolved.  (This is how MacVim's proxy icons work.)
function! s:StdHandler(...) abort
	if expand('<abuf>') == bufnr('%')
		call s:BasicHandler(a:0 ? a:1 : expand('<amatch>'))
	endif
endfunction


" Handler for TermChanged events, and this plugin's de facto main().
" Defines the autocommands if the terminal is supported and clears them
" otherwise (other than the TermChanged autocommand itself).
"
" Note that multiple details are used to identify terminals, so changing
" 'term' might not result in different behavior.
function! s:TermChangedHandler() abort
	augroup termcwd
		autocmd!
		autocmd TermChanged * call s:TermChangedHandler()
	augroup END

	" Pick the functions for assembling control sequences and
	" sending them to the terminal.
	try
		let s:SetCwds = s:ChooseSetCwds()
	catch /\m\C^termcwd(ChooseSetCwds):/
		unlet! s:SendCtrlSeq s:SetCwds
		return
	endtry
	let s:SendCtrlSeq = s:ChooseSendCtrlSeq()

	" NOTE: Guard autocommands that use events unavailable in 7.2.
	augroup termcwd
		" Handle naming an unnamed buffer with :write or
		" :update.
		autocmd BufAdd * call s:StdHandler()

		" Handle switching buffers.  This covers a lot of
		" ground, but some actions don't switch buffers, and
		" others switch *before* changing the file name.
		autocmd BufEnter * call s:BufEnterHandler()

		" Handle renaming a buffer with :file or :saveas.
		autocmd BufFilePost * call s:BufFilePostHandler()

		" Handle entering the command-line window.
		autocmd CmdwinEnter * call s:StdHandler()

		" Handle changing the current directory.  This only
		" matters in fileless windows because the other
		" autocommands update the directory too.  Requires patch
		" 8.0.1459.
		if exists('##DirChanged')
			autocmd DirChanged * call s:StdHandler(expand('%:p'))
		endif

		" Handle returning from :shell.
		autocmd ShellCmdPost * call s:StdHandler()

		" Handle the initial entrance to a terminal buffer.
		" Requires patch 8.0.1596 but is more portable than
		" `TerminalWinOpen`, which needs 8.1.2219.  I think
		" StdHandler's current-buffer check is sufficient to
		" weed out unwanted events, but if not, switching to
		" `TerminalWinOpen` would be fine.
		if exists('##TerminalOpen')
			autocmd TerminalOpen * call s:StdHandler()
		endif

		" Handle ceding control to another process.  Leave
		" a clean slate because there's no way to know whether
		" that process will set its own directory and document
		" (although 'no' is a safe bet).  Handling suspension
		" requires patch 8.2.2128.
		autocmd VimLeave * call s:SetCwds('', '', s:SendCtrlSeq)
		if exists('##VimSuspend')
			autocmd VimSuspend * call s:SetCwds('', '', s:SendCtrlSeq)
		endif

		" Handle resuming after suspension.  Can't use the
		" standard handler because '<abuf>' is always empty.
		" Use '%:p' because '<amatch>' is also always empty.
		" Requires patch 8.2.2128.
		if exists('##VimResume')
			autocmd VimResume * call s:BasicHandler(expand('%:p'))
		endif

		" Handle switching windows.  This covers a lot of
		" ground, but some actions don't switch windows, and
		" others switch *before* changing the file name.
		autocmd WinEnter * call s:StdHandler()
	augroup END
endfunction


" Define autocommands on initial load.
call s:TermChangedHandler()


let &cpoptions = s:saved_cpoptions
unlet s:saved_cpoptions


" References
"
"  1. https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
"  2. https://en.wikipedia.org/wiki/C0_and_C1_control_codes
