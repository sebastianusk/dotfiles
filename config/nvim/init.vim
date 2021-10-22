" set clipboard enabled
set clipboard^=unnamed,unnamedplus

" add spaces in TABS
set softtabstop=2
set expandtab " convert tab into spaces

" UI Config
set hidden
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

set lazyredraw
set showmatch
set backspace=indent,eol,start

set shiftround " When shifting lines, round the indentation to the nearest multiple of “shiftwidth.”
set shiftwidth=4 " When shifting, indent using four spaces.
set smarttab " Insert “tabstop” number of spaces when the “tab” key is pressed.
set tabstop=2 " Indent using four spaces.

set display+=lastline " Always try to show a paragraph’s last line.
set encoding=utf-8 " Use an encoding that supports unicode.
set linebreak " Avoid wrapping a line in the middle of a word.
set scrolloff=1 " The number of screen lines to keep above and below the cursor.
set sidescrolloff=5 " The number of screen columns to keep to the left and right of the cursor.
syntax on " add syntax enabled
set wrap " enable line wrapping

" Search
set incsearch
set hlsearch
set ignorecase
set smartcase

" put leader cd to change directory
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>

" Automatic write
set autowrite

" map esc key
imap jk <Esc>

" map leader
let mapleader = ","

" enable folding
set foldmethod=syntax
set foldlevel=99

filetype plugin indent on

" Vim Plug
call plug#begin('~/.vim/plugged')

Plug 'itchyny/lightline.vim'

" fzf
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Color Schemes
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
Plug 'udalov/kotlin-vim'

" Python
Plug 'nvie/vim-flake8'
Plug 'Vimjas/vim-python-pep8-indent'
Plug 'tmhedberg/SimpylFold'

" autopair bracket
Plug 'jiangmiao/auto-pairs'
" rainbow the bracket
Plug 'luochen1990/rainbow'

" coc.nvim - completer and language
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" polygot - syntax highlight
Plug 'sheerun/vim-polyglot'

" Git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" tmux
Plug 'christoomey/vim-tmux-navigator'

" Tagbar
Plug 'majutsushi/tagbar'

" Easymotion
Plug 'easymotion/vim-easymotion'

" snippet
Plug 'honza/vim-snippets'

" multiple cursors
Plug 'terryma/vim-multiple-cursors'

" fold
Plug 'pedrohdz/vim-yaml-folds'

" prisma
Plug 'pantharshit00/vim-prisma'

" leetcode
Plug 'ianding1/leetcode.vim'

" base64
Plug 'christianrondeau/vim-base64'

" for editing html tag
Plug 'mattn/emmet-vim'

" Initialize plugin system
call plug#end()

" NERDTree
" show hidden files
let NERDTreeShowHidden=1

" rainbow active
let g:rainbow_active = 1

" Key Commands
map <leader>\ :NERDTreeToggle<CR>
map <leader>\| :TagbarToggle<CR>

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" open NERDTree on directory
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" close vim when only NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

nmap <leader>n :NERDTreeFind<CR>
let NERDTreeMapOpenSplit='x'
let NERDTreeMapOpenVSplit='v'

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
set statusline+=%#warningmsg#
set statusline+=\ %{LinterStatus()}
set statusline+=%*
set statusline+=%{FugitiveStatusline()}

" make it easier to make it easier to edit vim rc
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" abbrevation
iabbrev @@ sebastianus.kurniawan@gmail.com

" setup search file using ctrl P
nnoremap <silent> <expr> <C-P> (expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":Files\<cr>"

" setup search string using ctrl F
nnoremap <silent> <expr> <C-F> (expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":Rg\<cr>"

" setup search tag using leader t
nnoremap <Leader>t :BTags<CR>
nnoremap <Leader>m :Marks<CR>

" CoC
" use <Tab> and <S-Tab> to navigate, use enter to select
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" use enter when no selected to complete
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    CocAction
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of LS, ex: coc-tsserver
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search snippets
nnoremap <silent><nowait> <space>s  :<C-u>CocList snippets<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>y  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>

" Use <C-l> for trigger snippet expand.
imap <C-l> <Plug>(coc-snippets-expand)

" Use <C-j> for select text for visual placeholder of snippet.
vmap <C-j> <Plug>(coc-snippets-select)

" Use <C-j> for jump to next placeholder, it's default of coc.nvim
let g:coc_snippet_next = '<c-m>'

" Use <C-k> for jump to previous placeholder, it's default of coc.nvim
let g:coc_snippet_prev = '<c-S-m>'

" Use <C-j> for both expand and jump (make expand higher priority.)
imap <C-j> <Plug>(coc-snippets-expand-jump)

" Use <leader>x for convert visual selected code to snippet
xmap <leader>x  <Plug>(coc-convert-snippet)

" Ale
let g:ale_disable_lsp = 1
let g:ale_fix_on_save = 1
let g:ale_sign_error = '●'
let g:ale_sign_warning = '.'
let g:ale_fixers = {
\    '*': ['remove_trailing_lines', 'trim_whitespace'],
\    'javascript': ['eslint'],
\    'typescript': ['eslint'],
\    'graphql': ['eslint'],
\    'vue': ['eslint'],
\    'scss': ['prettier'],
\    'css': ['prettier'],
\    'html': ['prettier'],
\    'json': ['prettier'],
\    'jsonc': ['prettier'],
\    'java': ['google_java_format'],
\    'terraform': ['terraform'],
\    'dart': ['dartfmt'],
\    'php': ['php_cs_fixer']
\}
let g:ale_fix_on_save = 1
nmap <leader>f <Plug>(ale_fix)

" Git
nmap <leader>gs :G<CR>
nmap <leader>gd :Gdiffsplit<CR>
nmap <leader>gc :Git commit<CR>
nmap <leader>gh :Glog -10 -- %<CR>

autocmd BufNewFile,BufRead *.go setlocal noexpandtab tabstop=4 shiftwidth=4
autocmd BufNewFile,BufRead *.java setlocal noexpandtab tabstop=4 shiftwidth=4

colors zenburn

" auto pair
let g:AutoPairsFlyMode = 0

map <leader>2 :set softtabstop=2 shiftwidth=2<CR>
map <leader>4 :set softtabstop=4 shiftwidth=4<CR>


let g:tagbar_type_yaml = {
    \ 'ctagstype' : 'yaml',
    \ 'kinds' : [
        \ 'a:anchors',
        \ 's:section',
        \ 'e:entry'
    \ ],
  \ 'sro' : '.',
    \ 'scope2kind': {
      \ 'section': 's',
      \ 'entry': 'e'
    \ },
    \ 'kind2scope': {
      \ 's': 'section',
      \ 'e': 'entry'
    \ },
    \ 'sort' : 0
    \ }


let g:indentLine_char = '⦙'
let g:indentLine_enabled = 1

nmap <silent> <leader>aj :ALENext<cr>
nmap <silent> <leader>ak :ALEPrevious<cr>

let g:lightline = {
      \ 'component_function': {
        \ 'filename': 'LightlineFilename'
        \}
      \}
function! LightlineFilename()
  return expand('%')
endfunction
