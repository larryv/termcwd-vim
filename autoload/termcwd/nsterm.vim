" autoload/termcwd/nsterm.vim - Apple Terminal
" --------------------------------------------
"
" Copyright 2021 Lawrence Velázquez


let s:saved_cpoptions = &cpoptions
set cpoptions&vim


" Sets Apple Terminal's current working directory and current working
" document.  If either argument is empty, tells Terminal to clear its
" corresponding state.  Nonempty arguments should be absolute paths, or
" the behavior is unspecified.
function! termcwd#nsterm#SetCwds(dir, doc) abort
    " The sequences are intended to contain valid RFC 8089 'file' URIs
    " (<https://www.rfc-editor.org/rfc/rfc8089.html>).

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

    call termcwd#SendCtrlSeq(l:dir_seq . l:doc_seq)
endfunction


let &cpoptions = s:saved_cpoptions
unlet s:saved_cpoptions
