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

function! s:ctrlp_rg_command() abort
    if s:ctrlp_follow_symlinks
        return 'rg %s --color=never --hidden --follow --files'
    else
        return 'rg %s --color=never --hidden --files'
    endif
endfunction

function! s:ctrlp_ag_command() abort
    if s:ctrlp_follow_symlinks == 0
        return 'ag %s --nocolor --hidden -l -g ""'
    else
        return 'ag %s --nocolor --hidden --follow -l -g ""'
    endif
endfunction

function! s:ctrlp_pt_command() abort
    if s:ctrlp_follow_symlinks
        return 'pt %s --nocolor --hidden --follow -l -g='
    else
        return 'pt %s --nocolor --hidden -l -g='
    endif
endfunction

function! s:ctrlp_dir_command() abort
    return 'dir %s /-n /b /s /a-d'
endfunction

function! s:ctrlp_find_command() abort
    if s:ctrlp_follow_symlinks
        return 'find -L %s -type f'
    else
        return 'find %s -type f'
    endif
endfunction

function! s:ctrlp_autodetect_command() abort
    if executable('rg')
        let fallback_command = s:ctrlp_rg_command()
    elseif executable('ag')
        let fallback_command = s:ctrlp_ag_command()
    elseif executable('pt')
        let fallback_command = s:ctrlp_pt_command()
    elseif has('win64') || has('win32')
        let fallback_command = s:ctrlp_dir_command()
    else
        let fallback_command = s:ctrlp_find_command()
    endif

    let autodetect_command = {
                \ 'types': {
                \   1: ['.git', 'cd %s && git ls-files . --cached --others --exclude-standard'],
                \   2: ['.hg',  'hg --cwd %s locate -I .'],
                \ },
                \ 'fallback': fallback_command
                \ }

    return autodetect_command
endfunction

let g:ctrlp_use_caching  = 0
let g:ctrlp_user_command = s:ctrlp_autodetect_command()

function! s:detect_available_commands() abort
    let s:ctrlp_available_commands = ['autodetect']
    if executable('rg')
        call add(s:ctrlp_available_commands, 'rg')
    endif
    if executable('ag')
        call add(s:ctrlp_available_commands, 'ag')
    endif
    if executable('pt')
        call add(s:ctrlp_available_commands, 'pt')
    endif
    call add(s:ctrlp_available_commands, 'find')
endfunction

call s:detect_available_commands()

function! s:list_available_commands(A, L, P) abort
    return join(s:ctrlp_available_commands, "\n")
endfunction

let s:ctrlp_current_command = 'autodetect'

function! s:change_ctrlp_user_command(command) abort
    if index(s:ctrlp_available_commands, a:command) == -1
        return
    endif

    let s:ctrlp_current_command = a:command

    if a:command ==# 'autodetect'
        let g:ctrlp_user_command = s:ctrlp_autodetect_command()
    elseif a:command ==# 'rg'
        let g:ctrlp_user_command = s:ctrlp_rg_command()
    elseif a:command ==# 'ag'
        let g:ctrlp_user_command = s:ctrlp_ag_command()
    elseif a:command ==# 'pt'
        let g:ctrlp_user_command = s:ctrlp_pt_command()
    else
        let g:ctrlp_user_command = s:ctrlp_find_command()
    endif

    if a:command ==# 'autodetect'
        echo 'CtrlP user command is autodetected!'
    else
        echo 'CtrlP is using command `' . g:ctrlp_user_command . '`!'
    endif
endfunction

command! -nargs=1 -complete=custom,<SID>list_available_commands ChangeCtrlPUserCommand call <SID>change_ctrlp_user_command(<q-args>)

function! s:cycle_ctrlp_user_command(bang) abort
    if a:bang
        let s:ctrlp_current_command = 'autodetect'
    else
        let idx = index(s:ctrlp_available_commands, s:ctrlp_current_command)
        let s:ctrlp_current_command = get(s:ctrlp_available_commands, idx + 1, 'autodetect')
    endif
    call s:change_ctrlp_user_command(s:ctrlp_current_command)
endfunction

command! -nargs=0 -bang CycleCtrlPUserCommand call <SID>cycle_ctrlp_user_command(<bang>0)

nnoremap <silent> =op :CycleCtrlPUserCommand<CR>

let g:loaded_ctrlp_settings_vim = 1
