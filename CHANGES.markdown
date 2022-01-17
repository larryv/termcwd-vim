<!--
    CHANGES.markdown
    ----------------

    SPDX-License-Identifier: MIT

    Copyright 2022 Lawrence Velázquez
-->

# Changes #

This is a summary of notable changes in each version of `termcwd` for
Vim.  The complete history is contained in the `main` branch of the Git
repository.

All dates are UTC.


## v0.3 ##

2022-01-17  
https://github.com/larryv/termcwd-vim/releases/tag/v0.3

-   Stopped trying to identify the host terminal from within tmux
    because the method introduced in version 0.2 was broken nonsense.
    (d94b539)
-   Learned to work within GNU `screen`. (8e4b9f5)


## v0.2 ##

2022-01-13  
https://github.com/larryv/termcwd-vim/releases/tag/v0.2

-   `plugin/autocmds.vim` was renamed to `plugin/termcwd.vim` to
    facilitate packaging as a vimball. (880f95f)
-   Learned how to identify the underlying terminal from within tmux
    sessions. (04f03f9)


## v0.1 ##

2022-01-01  
https://github.com/larryv/termcwd-vim/releases/tag/v0.1

-   Initial development release.  Should work with Vim 7.2 or later
    running directly under Apple Terminal 2.2.3 (303.2) or later.
