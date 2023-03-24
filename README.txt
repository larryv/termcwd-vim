termcwd for Vim
===============

This plugin for command-line Vim makes Apple Terminal's proxy icon
reflect Vim's current file (for windows that have one) or working
directory (for most other windows).

It works by using escape sequences to send Vim's current file and
working directory to Terminal.  Depending on Terminal's configuration,
this may also affect the titles and initial working directories of its
windows and tabs [1].

This software is released as open source using the MIT (i.e., Expat)
License.


Requirements
------------

- Vim [5] 7.2 or later with the +autocmd, +eval, and +modify_fname
  features.  This can be checked with Vim's `version` command [6] or by
  running `vim --version` in a shell [7].

  Earlier versions may work, but 7.2 is my baseline.  A few behaviors do
  require newer Vim patches.

  - Patch 8.0.1459 [8] allows updating Terminal immediately after Vim's
    working directory changes [9][10].

  - Patch 8.0.1596 [11] allows updating Terminal when entering a Vim
    terminal window for the first time [10][12].

  - Patch 8.2.2128 [13] allows updating Terminal before Vim is
    suspended [14][15] and immediately after Vim resumes [10][16].

- Apple Terminal from Mac OS X Lion 10.7 or later -- i.e., version 2.2.3
  (303.2) or later.  This can be checked from Terminal by choosing
  "About Terminal" from the "Terminal" menu.


Installation
------------

This plugin has nothing to configure, so just download it and make sure
Vim can find it at startup [17].  Here are a few options:

- Clone this repository into a Vim package [18].  Recommended for Vim 8
  or later.

      mkdir -p ~/.vim/pack/whatever/start \
          && cd ~/.vim/pack/whatever/start \
          && git clone https://github.com/larryv/termcwd-vim.git

- Use a third-party plugin manager such as Tim Pope's pathogen [19].
  Its documentation should explain how to install plugins.  Recommended
  for Vim 7, which predates native package support.

- Clone or download this repository to an arbitrary location and
  manually update Vim's `runtimepath` option [20] (perhaps in ~/.vimrc).
  Left as an exercise for the reader.  Recommended for my enemies.

That's it.  Enjoy the icon.


Notes
-----

 [1]: Terminal's General preferences [2] determine whether new windows
      or tabs open with the same working directory as the current window
      or tab.  Each profile's Window [3] and Tab [4] preferences
      determine whether windows' and tabs' titles display the name or
      path of the working document or directory.
 [2]: https://support.apple.com/guide/terminal/change-general-preferences-trmlstrtup
 [3]: https://support.apple.com/guide/terminal/change-profiles-tab-preferences-trmltab
 [4]: https://support.apple.com/guide/terminal/change-profiles-window-preferences-trmlwindw
 [5]: https://www.vim.org
 [6]: https://vimhelp.org/various.txt.html#%3Aversion
 [7]: Do not simply look at Vim's welcome screen, as it does not provide
      complete version information.  For example, in the system Vim on
      macOS Mojave 10.14.6 it says "version 8.0.1365", but :version [6]
      says "8.0 [...] Included patches: 1-503, 505-680, 682-1283, 1365".
 [8]: https://ftp.nluug.nl/pub/vim/patches/8.0/8.0.1459
 [9]: https://vimhelp.org/autocmd.txt.html#DirChanged
[10]: Even without these patches, Terminal is updated as soon as the
      user switches Vim windows or buffers.
[11]: https://ftp.nluug.nl/pub/vim/patches/8.0/8.0.1596
[12]: https://vimhelp.org/autocmd.txt.html#TerminalOpen
[13]: https://ftp.nluug.nl/pub/vim/patches/8.2/8.2.2128
[14]: https://vimhelp.org/autocmd.txt.html#VimSuspend
[15]: Without this patch, Terminal's state becomes stale when Vim is
      suspended, unless the subsequent process updates it.
[16]: https://vimhelp.org/autocmd.txt.html#VimResume
[17]: https://vimhelp.org/starting.txt.html#load-plugins
[18]: https://vimhelp.org/repeat.txt.html#packages
[19]: https://github.com/tpope/vim-pathogen
[20]: https://vimhelp.org/options.txt.html#%27runtimepath%27


SPDX-License-Identifier: MIT

Copyright 2021 Lawrence Velazquez
