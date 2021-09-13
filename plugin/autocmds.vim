" plugin/autocmds.vim
" -------------------
"
" SPDX-License-Identifier: MIT
"
" Copyright 2021 Lawrence Velázquez
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
        call s:SetCwds(getcwd(), a:doc)
    elseif &buftype ==# 'terminal' || &buftype ==# 'prompt'
        " The buffer is intended for use with external jobs.
        call s:SetCwds('', '')
    else
        " The buffer is not associated with a file.
        call s:SetCwds(getcwd(), '')
    endif
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
function! s:BufFilePostHandler() abort
    if expand('<afile>') !=# '[Command Line]' && expand('<amatch>')[0] !=# '!'
        call s:StdHandler()
    endif
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

    " Select a function to 'communicate' with a supported terminal.
    "
    " TODO: Identify terminals in tmux sessions, where TERM_PROGRAM and
    " TERM are changed.  Use its 'show-environment' command, maybe?
    if $TERM_PROGRAM ==# 'Apple_Terminal'
                \ || &term =~# '^nsterm-\|^nsterm$\|^Apple_Terminal$'
        let s:SetCwds = function('termcwd#nsterm#SetCwds')
    else
        unlet! s:SetCwds
        return
    endif

    augroup termcwd
        " Handle naming an unnamed buffer with :write or :update.
        autocmd BufAdd * call s:StdHandler()

        " Handle switching buffers.  This covers a lot of ground, but
        " some actions don't switch buffers, and others switch *before*
        " changing the file name.
        autocmd BufEnter * call s:BufEnterHandler()

        " Handle renaming a buffer with :file or :saveas.
        autocmd BufFilePost * call s:BufFilePostHandler()

        " Handle entering the command-line window.
        if exists('##CmdwinEnter')
            autocmd CmdwinEnter * call s:StdHandler()
        endif

        " Handle changing the current directory.
        if exists('##DirChanged')
            autocmd DirChanged * call s:StdHandler(expand('%:p'))
        endif

        " Handle returning from :shell.
        autocmd ShellCmdPost * call s:StdHandler()

        " Handle the initial entrance to a windowed terminal buffer.
        if exists('##TerminalWinOpen')
            autocmd TerminalWinOpen * call s:StdHandler()
        endif

        " Handle ceding control to another process.  Leave a clean slate
        " because there's no way to know whether that process will set
        " its own directory and document (although 'no' is a safe bet).
        autocmd VimLeave * call s:SetCwds('', '')
        if exists('##VimSuspend')
            autocmd VimSuspend * call s:SetCwds('', '')
        endif

        " Handle resuming after suspension.  Can't use the standard
        " handler because '<abuf>' is always empty.  Use '%:p' because
        " '<amatch>' is always empty.
        if exists('##VimResume')
            autocmd VimResume * call s:BasicHandler(expand('%:p'))
        endif

        " Handle switching windows.  This covers a lot of ground, but
        " some actions don't switch windows, and others switch *before*
        " changing the file name.
        autocmd WinEnter * call s:StdHandler()
    augroup END
endfunction


" Define autocommands on initial load.
call s:TermChangedHandler()


let &cpoptions = s:saved_cpoptions
unlet s:saved_cpoptions
