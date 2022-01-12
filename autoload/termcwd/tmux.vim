" autoload/termcwd/tmux.vim - tmux
" --------------------------------
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


" This plugin's tmux workarounds are known to be necessary for and work
" with tmux 3.2a.


" Given the name of an environment variable in `var_name`, returns the
" variable's value from tmux's global environment.  Throws an exception
" if the variable has been removed from the environment or is hidden.
function! termcwd#tmux#GetGlobalEnvVar(var_name) abort
    let l:cmd = 'tmux show-environment -g ' . shellescape(a:var_name)
    silent let l:cmd_output = system(l:cmd)
    if v:shell_error || l:cmd_output !~# '='
        let l:exception = 'termcwd(tmux#GetGlobalEnvVar):'
        let l:exception .= 'could not get variable ' . a:var_name
        let l:exception .= ' from tmux environment'
        throw l:exception
    endif
    return substitute(l:cmd_output, '\C^.\{-}=\|\n$', '', 'g')
endfunction
