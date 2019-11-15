if globpath(&rtp, 'plugin/ctrlp.vim') == ''
    echohl WarningMsg | echomsg 'ctrlp.vim is not found.' | echohl none
    finish
endif

let g:loaded_ctrlp_settings_vim = 0

if get(g:, 'loaded_ctrlp_settings_vim', 0)
    finish
endif

let g:ctrlp_match_window      = 'max:20'
let g:ctrlp_working_path_mode = 'w'
let g:ctrlp_reuse_window      = 'startify'
let g:ctrlp_prompt_mappings   = { 'MarkToOpen()': ['<C-z>', '<C-@>'], }

let g:ctrlp_use_caching         = 0 " rg/ag is enough fast, we don't need cache
let g:ctrlp_max_files           = 0
let g:ctrlp_clear_cache_on_exit = 0

let g:ctrlp_find_tool       = get(g:, 'ctrlp_find_tool', 'rg')
let s:ctrlp_follow_symlinks = get(g:, 'ctrlp_follow_symlinks', 0)

let s:default_command = 'vcs'

function! s:detect_ctrlp_available_commands() abort
    let s:ctrlp_available_commands = [s:default_command]
    for cmd in ['rg', 'ag', 'fd']
        if executable(cmd)
            call add(s:ctrlp_available_commands, cmd)
        endif
    endfor
    if has('win64') || has('win32')
        call add(s:ctrlp_available_commands, 'dir')
    endif
    call add(s:ctrlp_available_commands, 'find')
endfunction

function! s:detect_ctrlp_current_command() abort
    let idx = index(s:ctrlp_available_commands, g:ctrlp_find_tool)
    if idx == -1
        let idx = 0
    endif
    let s:ctrlp_current_command = get(s:ctrlp_available_commands, idx, s:default_command)
endfunction

function! s:ctrlp_rg_command() abort
    if s:ctrlp_follow_symlinks == 0
        return 'rg %s --color=never --no-ignore-vcs --hidden --files'
    else
        return 'rg %s --color=never --no-ignore-vcs --hidden --follow --files'
    endif
endfunction

function! s:ctrlp_ag_command() abort
    if s:ctrlp_follow_symlinks == 0
        return 'ag %s --nocolor --skip-vcs-ignores --hidden -l -g ""'
    else
        return 'ag %s --nocolor --skip-vcs-ignores --hidden --follow -l -g ""'
    endif
endfunction

function! s:ctrlp_fd_command() abort
    if s:ctrlp_follow_symlinks == 0
        return 'fd --color=never --no-ignore-vcs --hidden --type file . %s'
    else
        return 'fd --color=never --no-ignore-vcs --hidden --follow --type file . %s'
    endif
endfunction

function! s:ctrlp_dir_command() abort
    return 'dir %s /-n /b /s /a-d'
endfunction

let s:find_ignores = '-path "*/.git/*" -o -path "*/.hg/*" -o -path "*/.svn/*"'
let s:find_ignores .= ' -o -path "*/gems/*" -o -path "*/.gems/*"'
let s:find_ignores .= ' -o -path "*/node_modules/*" -o -path "*/.built/*" -o -path "*.DS_Store"'

function! s:ctrlp_find_command(...) abort
    let include_ignores = get(a:, 1, 1)
    let ignores = ' '
    if include_ignores
        let ignores .= s:find_ignores . ' '
    endif
    if s:ctrlp_follow_symlinks == 0
        return 'find %s' . ignores . '-prune -o -type f -print'
    else
        return 'find -L %s' . ignores . '-prune -o -type f -print'
    endif
endfunction

function! s:build_user_command(command) abort
    if a:command ==# 'rg'
        return s:ctrlp_rg_command()
    elseif a:command ==# 'ag'
        return s:ctrlp_ag_command()
    elseif a:command ==# 'fd'
        return s:ctrlp_fd_command()
    elseif a:command ==# 'dir'
        return s:ctrlp_dir_command()
    else
        return s:ctrlp_find_command()
    endif
endfunction

function! s:ctrlp_vcs_command() abort
    let user_command = {
                \ 'types': {
                \   1: ['.git', 'cd %s && git ls-files . --cached --others --exclude-standard'],
                \   2: ['.hg',  'hg --cwd %s locate -I .'],
                \ },
                \ }

    " There is other command like rg, ag, fd, dir or find
    if len(s:ctrlp_available_commands) > 1
        let user_command['fallback'] = s:build_user_command(s:ctrlp_available_commands[1])
    endif

    return user_command
endfunction

function! s:set_ctrlp_user_comand(command) abort
    if a:command ==# s:default_command
        let g:ctrlp_user_command = s:ctrlp_vcs_command()
    else
        let g:ctrlp_user_command = s:build_user_command(a:command)
    endif
    let s:ctrlp_current_command = a:command
endfunction

function! s:print_ctrlp_current_command_info() abort
    if s:ctrlp_current_command ==# s:default_command
        echo 'CtrlP is using VCS command (git/hg)!'
    elseif s:ctrlp_current_command ==# 'find'
        echo 'CtrlP is using command `' . s:ctrlp_find_command(0) . '`!'
    else
        echo 'CtrlP is using command `' . g:ctrlp_user_command . '`!'
    endif
endfunction

command! -nargs=0 PrintCtrlPCurrentCommandInfo call <SID>print_ctrlp_current_command_info()

function! s:change_ctrlp_user_command(bang, command) abort
    " Reset to default command
    if a:bang
        let new_command = s:default_command
    elseif strlen(a:command)
        if index(s:ctrlp_available_commands, a:command) == -1
            return
        endif
        let new_command = a:command
    else
        let idx = index(s:ctrlp_available_commands, s:ctrlp_current_command)
        let new_command = get(s:ctrlp_available_commands, idx + 1, s:default_command)
    endif

    call s:set_ctrlp_user_comand(new_command)
    call s:print_ctrlp_current_command_info()
endfunction

function! s:list_ctrlp_available_commands(A, L, P) abort
    return join(s:ctrlp_available_commands, "\n")
endfunction

command! -nargs=? -bang -complete=custom,<SID>list_ctrlp_available_commands ChangeCtrlPUserCommand call <SID>change_ctrlp_user_command(<bang>0, <q-args>)

function! s:toggle_ctrlp_follow_symlinks() abort
    if s:ctrlp_follow_symlinks == 0
        let s:ctrlp_follow_symlinks = 1
        echo 'CtrlP follows symlinks!'
    else
        let s:ctrlp_follow_symlinks = 0
        echo 'CtrlP does not follow symlinks!'
    endif
    call s:set_ctrlp_user_comand(s:ctrlp_current_command)
endfunction

command! -nargs=0 ToggleCtrlPFollowSymlinks call <SID>toggle_ctrlp_follow_symlinks()

call s:detect_ctrlp_available_commands()
call s:detect_ctrlp_current_command()
call s:set_ctrlp_user_comand(s:ctrlp_current_command)

let g:loaded_ctrlp_settings_vim = 1
