if globpath(&rtp, 'plugin/ctrlp.vim') == ''
    echohl WarningMsg | echomsg 'ctrlp.vim is not found.' | echohl none
    finish
endif

if get(g:, 'loaded_ctrlp_settings_vim', 0)
    finish
endif

let g:ctrlp_match_window      = 'max:20'
let g:ctrlp_map               = ''
let g:ctrlp_working_path_mode = 'w'
let g:ctrlp_reuse_window      = 'startify'
let g:ctrlp_prompt_mappings   = { 'MarkToOpen()': ['<C-z>', '<C-@>'], }

let s:ctrlp_follow_symlinks = 0
function! s:toggle_ctrlp_follow_symlinks() abort
    if s:ctrlp_follow_symlinks == 0
        let s:ctrlp_follow_symlinks = 1
        echo 'CtrlP follows symlinks!'
    else
        let s:ctrlp_follow_symlinks = 0
        echo 'CtrlP does not follow symlinks!'
    endif
endfunction

command! -nargs=0 ToggleCtrlPFollowSymlinks call <SID>toggle_ctrlp_follow_symlinks()
nnoremap <silent> =oP :ToggleCtrlPFollowSymlinks<CR>

function! s:detect_available_commands() abort
    let s:ctrlp_available_commands = ['autodetect']
    for cmd in ['rg', 'ag', 'pt', 'fd']
        if executable(cmd)
            call add(s:ctrlp_available_commands, cmd)
        endif
    endfor
    if has('win64') || has('win32')
        call add(s:ctrlp_available_commands, 'dir')
    endif
    call add(s:ctrlp_available_commands, 'find')
endfunction

call s:detect_available_commands()

function! s:ctrlp_rg_command() abort
    let cmd = 'rg %s --color=never --no-ignore-vcs --hidden %s --files'
    let cmd = printf(cmd, '%s', s:ctrlp_follow_symlinks ? '--follow' : '')
    return substitute(cmd, '  ', ' ', 'g')
endfunction

function! s:ctrlp_ag_command() abort
    let cmd = 'ag %s --nocolor --skip-vcs-ignores --hidden %s -l -g ""'
    let cmd = printf(cmd, '%s', s:ctrlp_follow_symlinks ? '--follow' : '')
    return substitute(cmd, '  ', ' ', 'g')
endfunction

function! s:ctrlp_pt_command() abort
    let cmd = 'pt %s --nocolor --home-ptignore --skip-vcs-ignores --hidden %s -l -g='
    let cmd = printf(cmd, '%s', s:ctrlp_follow_symlinks ? '--follow' : '')
    return substitute(cmd, '  ', ' ', 'g')
endfunction

function! s:ctrlp_fd_command() abort
    let cmd = 'fd --color=never --no-ignore-vcs --hidden %s --type file . %s'
    let cmd = printf(cmd, s:ctrlp_follow_symlinks ? '--follow' : '', '%s')
    return substitute(cmd, '  ', ' ', 'g')
endfunction

function! s:ctrlp_dir_command() abort
    return 'dir %s /-n /b /s /a-d'
endfunction

function! s:ctrlp_find_command() abort
    let ignores = '-path "*/.git/*" -o -path "*/.hg/*" -o -path "*/.svn/*" -o -path "*/gems/*" -o -path "*/.gems/*" -o -path "*/node_modules/*" -o -path "*.DS_Store"'
    let cmd = 'find %s %s ' . ignores . ' -prune -o -type f -print'
    let cmd = printf(cmd, s:ctrlp_follow_symlinks ? '-L' : '', '%s')
    return substitute(cmd, '  ', ' ', 'g')
endfunction

function! s:ctrlp_autodetect_command() abort
    let fallback_command = s:build_user_command(s:ctrlp_available_commands[1])

    let autodetect_command = {
                \ 'types': {
                \   1: ['.git', 'cd %s && git ls-files . --cached --others --exclude-standard'],
                \   2: ['.hg',  'hg --cwd %s locate -I .'],
                \ },
                \ 'fallback': fallback_command
                \ }

    return autodetect_command
endfunction

function! s:build_user_command(command) abort
    if a:command ==# 'rg'
        return s:ctrlp_rg_command()
    elseif a:command ==# 'ag'
        return s:ctrlp_ag_command()
    elseif a:command ==# 'pt'
        return s:ctrlp_pt_command()
    elseif a:command ==# 'fd'
        return s:ctrlp_fd_command()
    elseif a:command ==# 'dir'
        return s:ctrlp_dir_command()
    else
        return s:ctrlp_find_command()
    endif
endfunction

let g:ctrlp_use_caching  = 0
let g:ctrlp_user_command = s:ctrlp_autodetect_command()

let s:default_command = 'autodetect'
let s:ctrlp_current_command = s:default_command

function! s:change_ctrlp_user_command(command) abort
    if index(s:ctrlp_available_commands, a:command) == -1
        return
    endif

    let s:ctrlp_current_command = a:command

    if a:command ==# s:default_command
        let g:ctrlp_user_command = s:ctrlp_autodetect_command()
        echo 'CtrlP user command is autodetected!'
    else
        let g:ctrlp_user_command = s:build_user_command(a:command)
        if a:command ==# 'find'
            let msg = 'CtrlP is using `find %s %s -type f`!'
            let msg = printf(msg, s:ctrlp_follow_symlinks ? '-L' : '', '%s')
            echo substitute(msg, '  ', ' ', 'g')
        else
            echo 'CtrlP is using command `' . g:ctrlp_user_command . '`!'
        endif
    endif
endfunction

function! s:list_available_commands(A, L, P) abort
    return join(s:ctrlp_available_commands, "\n")
endfunction

command! -nargs=1 -complete=custom,<SID>list_available_commands ChangeCtrlPUserCommand call <SID>change_ctrlp_user_command(<q-args>)

function! s:cycle_ctrlp_user_command(bang) abort
    if a:bang
        let s:ctrlp_current_command = s:default_command
    else
        let idx = index(s:ctrlp_available_commands, s:ctrlp_current_command)
        let s:ctrlp_current_command = get(s:ctrlp_available_commands, idx + 1, s:default_command)
    endif
    call s:change_ctrlp_user_command(s:ctrlp_current_command)
endfunction

command! -nargs=0 -bang CycleCtrlPUserCommand call <SID>cycle_ctrlp_user_command(<bang>0)

nnoremap <silent> =op :CycleCtrlPUserCommand<CR>

let g:loaded_ctrlp_settings_vim = 1
