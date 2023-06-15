function! ctrlp_settings#ctrlp_all(dir) abort
    try
        let g:ctrlp_user_command = g:ctrlp_find_all_command
        execute 'CtrlP' a:dir
    finally
        let g:ctrlp_user_command = g:ctrlp_find_command
    endtry
endfunction

function! ctrlp_settings#mru_cwd_files(dir) abort
    let current = g:ctrlp_mruf_relative
    try
        let g:ctrlp_mruf_relative = 1
        call ctrlp#init('mru', { 'dir': a:dir })
    finally
        let g:ctrlp_mruf_relative = current
    endtry
endfunction
