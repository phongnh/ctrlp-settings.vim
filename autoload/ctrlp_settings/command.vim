function! ctrlp_settings#command#build_user_command()
    if get(g:, 'ctrlp_use_vcs_tool', 1)
        let g:ctrlp_user_command = {
                    \ 'types': {
                    \   1: ['.git', 'cd %s && git ls-files . --cached --others --exclude-standard'],
                    \   2: ['.hg',  'hg --cwd %s locate -I .'],
                    \ },
                    \ 'fallback': ctrlp_settings#command#build_find_command(),
                    \ }
    else
        let g:ctrlp_user_command = ctrlp_settings#command#build_find_command()
    endif
endfunction

function! ctrlp_settings#command#build_find_command() abort
    let find_commands = {
                \ 'fd': 'fd --base-directory %s --type file --color never --no-ignore-vcs --hidden --strip-cwd-prefix',
                \ 'rg': 'rg %s --files --color never --no-ignore-vcs --ignore-dot --ignore-parent --hidden',
                \ }

    if g:ctrlp_find_tool ==# 'rg' && executable('rg')
        let g:ctrlp_find_command = find_commands['rg']
    else
        let g:ctrlp_find_command = find_commands['fd']
    endif

    let g:ctrlp_find_command .= (g:ctrlp_follow_symlinks ? ' --follow' : '')

    return g:ctrlp_find_command
endfunction

function! ctrlp_settings#command#build_find_all_command() abort
    let find_all_commands = {
                \ 'fd': 'fd --base-directory %s --type file --color never --no-ignore --hidden --follow --strip-cwd-prefix',
                \ 'rg': 'rg %s --files --color never --no-ignore --hidden --follow',
                \ }

    if g:ctrlp_find_tool ==# 'rg' && executable('rg')
        let g:ctrlp_find_all_command = find_all_commands['rg']
    else
        let g:ctrlp_find_all_command = find_all_commands['fd']
    endif

    return g:ctrlp_find_all_command
endfunction

function! ctrlp_settings#command#init() abort
    call ctrlp_settings#command#build_find_all_command()
    call ctrlp_settings#command#build_user_command()
endfunction
