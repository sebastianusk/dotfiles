" set clipboard enabled
set clipboard=unnamed


" add spaces in TABS
set tabstop=2
set softtabstop=2
set expandtab " convert tab into spaces

" UI Config
set laststatus=2 " Always display the status bar.
set ruler " Always show cursor position.
set wildmenu " Display command line’s tab complete options as a menu.
set tabpagemax=50 " Maximum number of tab pages that can be opened from the command line.
set cursorline " Highlight the line currently under cursor.
set number " Show line numbers on the sidebar.
set relativenumber " Show line number on the current line and relative numbers on all other lines.
set noerrorbells " Disable beep on errors.
set visualbell " Flash the screen instead of beeping on errors.
set mouse=a " Enable mouse for scrolling and resizing.
set title " Set the window’s title, reflecting the file currently being edited.
set cursorline
set background=dark " set the color scheme
let g:solarized_diffmode="high"
colorscheme solarized

filetype plugin indent on
set lazyredraw
set showmatch
set backspace=indent,eol,start

set shiftround " When shifting lines, round the indentation to the nearest multiple of “shiftwidth.”
set shiftwidth=4 " When shifting, indent using four spaces.
set smarttab " Insert “tabstop” number of spaces when the “tab” key is pressed.
set tabstop=4 " Indent using four spaces.

set display+=lastline " Always try to show a paragraph’s last line.
set encoding=utf-8 " Use an encoding that supports unicode.
set linebreak " Avoid wrapping a line in the middle of a word.
set scrolloff=1 " The number of screen lines to keep above and below the cursor.
set sidescrolloff=5 " The number of screen columns to keep to the left and right of the cursor.
syntax enable " add syntax enabled
set wrap " enable line wrapping

" Search
set incsearch
set hlsearch
set ignorecase
set smartcase

" Automatic change directory
set autochdir

" split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>



" map esc key
imap jk <Esc>

" map leader
let mapleader = ","

" enable folding
set foldmethod=indent
set foldlevel=99
let g:SimpylFold_docstring_preview=1

" Vim Plug
call plug#begin('~/.vim/plugged')

" Airline (status bar)
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" fzf
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Color Schemes
Plug 'flazz/vim-colorschemes'
Plug 'altercation/vim-colors-solarized'
Plug 'jnurmine/zenburn'

" NERDTree
Plug 'scrooloose/nerdtree'

" NERD Commenter
Plug 'scrooloose/nerdcommenter'

" Surround
Plug 'tpope/vim-surround'

" ale for lint
Plug 'dense-analysis/ale'

" Language
Plug 'leafgarland/typescript-vim'
Plug 'udalov/kotlin-vim'
Plug 'dart-lang/dart-vim-plugin'

" Python
Plug 'nvie/vim-flake8'
Plug 'Vimjas/vim-python-pep8-indent'

" Javascript
Plug 'pangloss/vim-javascript'
Plug 'moll/vim-node'

" coc.nvim - completer and language
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Git
Plug 'tpope/vim-fugitive'

" tmux
Plug 'christoomey/vim-tmux-navigator'

" fold
Plug 'tmhedberg/SimpylFold'

" Initialize plugin system
call plug#end()

" NERDTree
" show hidden files
let NERDTreeShowHidden=1

" Key Commands
map <C-\> :NERDTreeToggle<CR>

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" open NERDTree on directory
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" close vim when only NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

function! LinterStatus() abort
    let l:counts = ale#statusline#Count(bufnr(''))
    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors
    return l:counts.total == 0 ? 'OK' : printf(
        \   '%d⨉ %d⚠ ',
        \   all_non_errors,
        \   all_errors
        \)
endfunction

" status line
set statusline+=%=
set statusline+=\ %{LinterStatus()}
set statusline+=%#warningmsg#
set statusline+=%*
set statusline+=%{FugitiveStatusline()}

" make it easier to make it easier to edit vim rc
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" abbrevation
iabbrev @@ sebastianus.kurniawan@gmail.com

" setup open files using ctrl p
nnoremap <silent> <expr> <C-P> (expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":Files\<cr>"

" setup search string using ctrl F
nnoremap <silent> <expr> <C-F> (expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":Rg\<cr>"

" CoC
" use <Tab> and <S-Tab> to navigate, use enter to select
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" use enter when no selected to complete
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Ale
let g:ale_fix_on_save = 1
let g:ale_sign_error = '●'
let g:ale_sign_warning = '.'

" Git
nmap <leader>gs :G<CR>
nmap <leader>gd :Gdiffsplit<CR>
nmap <leader>gc :Git commit<CR>
nmap <leader>gh :diffget //3<CR>
nmap <leader>gl :diffget //2<CR>

