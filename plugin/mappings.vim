let g:python_debug_mode = 0
nnoremap <localleader>d :call vim_pdb#Python_debug(0)<cr>
nnoremap <localleader>D :call vim_pdb#Python_debug(1)<cr>
