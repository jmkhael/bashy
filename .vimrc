set nocompatible
set term=ansi
set tabstop=4       " number of visual spaces per TAB
set softtabstop=4   " number of spaces in tab when editing
set expandtab       " tabs are spaces
set number          " show line numbers
set cursorline      " highlight current line
set showmatch       " highlight matching [{()}]
set incsearch       " search as characters are entered
set hlsearch        " highlight matches
set visualbell      " Blink cursor on error instead of beeping (grr)

syntax on           " Turn on syntax highlighting
set ruler           " Show file stats

" Disable Background Color Erase (BCE) so that color schemes
" render properly when inside 256-color tmux and GNU screen.
if &term =~ '256color'
    set t_ut=
endif
