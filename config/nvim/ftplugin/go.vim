" run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction

nmap <leader>b <C-u>call <SID>build_go_files()<CR>
nmap <leader>r <Plug>(go-run)
nmap <leader>t <Plug>(go-test)
nmap <Leader>c <Plug>(go-coverage-toggle)
nmap <Leader>d<space> :GoDebugBreakpoint<CR>
nmap <Leader>dd :GoDebugStart .
nmap <Leader>ds :GoDebugStop<CR>

let g:go_debug_mappings = {
      \ '(go-debug-continue)': {'key': 'c', 'arguments': '<nowait>'},
      \ '(go-debug-next)': {'key': 'n', 'arguments': '<nowait>'},
      \ '(go-debug-step)': {'key': 's'},
      \ '(go-debug-print)': {'key': 'p'},
  \}

let g:go_debug_windows = {
      \ 'vars':       'rightbelow 60vnew',
      \ 'stack':      'rightbelow 10new',
\ }

" autocmd BufWritePre *.go :silent call CocAction('runCommand', 'editor.action.organizeImport')
