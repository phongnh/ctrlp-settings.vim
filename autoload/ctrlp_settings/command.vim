function! s:BuildUserCommand()
    if exists('g:ctrlp_find_command')
        if get(g:, 'ctrlp_use_vcs_tool', 0)
            let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files --cached --others --exclude-standard', g:ctrlp_find_command]
        else
            let g:ctrlp_user_command = g:ctrlp_find_command
        endif
    else
        let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files --cached --others --exclude-standard']
    endif
endfunction

function! s:BuildFindCommand() abort
    if executable('fd')
        let g:ctrlp_find_command = 'fd --base-directory %s --type file --color never --hidden'
        let g:ctrlp_find_command .= (g:ctrlp_follow_symlinks ? ' --follow' : '')
        let g:ctrlp_find_command .= (g:ctrlp_find_no_ignore_vcs ? ' --no-ignore-vcs' : '')
    elseif executable('rg')
        let g:ctrlp_find_command = 'rg %s --files --color never --ignore-dot --ignore-parent --hidden'
        let g:ctrlp_find_command .= (g:ctrlp_follow_symlinks ? ' --follow' : '')
        let g:ctrlp_find_command .= (g:ctrlp_find_no_ignore_vcs ? ' --no-ignore-vcs' : '')
    endif
endfunction

function! s:BuildFindAllCommand() abort
    if executable('fd')
        let g:ctrlp_find_all_command = 'fd --base-directory %s --type file --color never --no-ignore --exclude .git --hidden --follow'
    elseif executable('rg')
        let g:ctrlp_find_all_command = 'rg %s --files --color never --no-ignore --exclude .git --hidden --follow'
    endif
endfunction

function! ctrlp_settings#command#init() abort
    call s:BuildFindCommand()
    call s:BuildFindAllCommand()
    call s:BuildUserCommand()
endfunction
