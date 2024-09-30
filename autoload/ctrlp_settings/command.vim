let s:find_commands = {
            \ 'fd': 'fd --base-directory %s --type file --color never --hidden',
            \ 'rg': 'rg %s --files --color never --ignore-dot --ignore-parent --hidden',
            \ }

let s:find_all_commands = {
            \ 'fd': 'fd --base-directory %s --type file --color never --no-ignore --exclude .git --hidden --follow',
            \ 'rg': 'rg %s --files --color never --no-ignore --exclude .git --hidden --follow',
            \ }

function! s:BuildUserCommand()
    if get(g:, 'ctrlp_use_vcs_tool', 0)
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
    let g:ctrlp_find_command = s:find_commands[g:ctrlp_find_tool ==# 'rg' ? 'rg' : 'fd']
    let g:ctrlp_find_command .= (g:ctrlp_follow_symlinks ? ' --follow' : '')
    let g:ctrlp_find_command .= (g:ctrlp_find_no_ignore_vcs ? ' --no-ignore-vcs' : '')
    return g:ctrlp_find_command
endfunction

function! s:BuildFindAllCommand() abort
    let g:ctrlp_find_all_command = s:find_all_commands[g:ctrlp_find_tool ==# 'rg' ? 'rg' : 'fd']
    return g:ctrlp_find_all_command
endfunction

function! ctrlp_settings#command#init() abort
    call s:BuildFindAllCommand()
    call s:BuildUserCommand()
endfunction
