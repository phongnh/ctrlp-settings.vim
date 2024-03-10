function! s:BuildUserCommand()
    if g:ctrlp_use_ignore_vcs > 1
        let g:ctrlp_user_command = {
                    \ 'types': {
                    \   1: ['.git', 'cd %s && git ls-files . --cached --others --exclude-standard'],
                    \   2: ['.hg',  'hg --cwd %s locate -I .'],
                    \ },
                    \ 'fallback': s:BuildFindCommand(),
                    \ }
    else
        let g:ctrlp_user_command = s:BuildFindCommand()
    endif
endfunction

function! s:BuildFindCommand() abort
    let find_commands = {
                \ 'fd': 'fd --base-directory %s --type file --color never --hidden --strip-cwd-prefix',
                \ 'rg': 'rg %s --files --color never --ignore-dot --ignore-parent --hidden',
                \ }

    if g:ctrlp_find_tool ==# 'rg' && executable('rg')
        let g:ctrlp_find_command = find_commands['rg']
    else
        let g:ctrlp_find_command = find_commands['fd']
    endif

    let g:ctrlp_find_command .= (g:ctrlp_use_ignore_vcs ? '--ignore-vcs' : '--no-ignore-vcs')
    let g:ctrlp_find_command .= (g:ctrlp_follow_symlinks ? ' --follow' : '')

    return g:ctrlp_find_command
endfunction

function! s:BuildFindAllCommand() abort
    let find_all_commands = {
                \ 'fd': 'fd --base-directory %s --type file --color never --no-ignore --exclude .git --hidden --follow --strip-cwd-prefix',
                \ 'rg': 'rg %s --files --color never --no-ignore --exclude .git --hidden --follow',
                \ }

    if g:ctrlp_find_tool ==# 'rg' && executable('rg')
        let g:ctrlp_find_all_command = find_all_commands['rg']
    else
        let g:ctrlp_find_all_command = find_all_commands['fd']
    endif

    return g:ctrlp_find_all_command
endfunction

function! ctrlp_settings#command#init() abort
    call s:BuildFindAllCommand()
    call s:BuildUserCommand()
endfunction
