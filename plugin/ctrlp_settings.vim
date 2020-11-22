if globpath(&rtp, 'plugin/ctrlp.vim') == ''
    echohl WarningMsg | echomsg 'ctrlp.vim is not found.' | echohl none
    finish
endif

if get(g:, 'loaded_ctrlp_settings_vim', 0)
    finish
endif

let g:ctrlp_match_window      = 'max:15,results:50'
let g:ctrlp_working_path_mode = 'w'
let g:ctrlp_reuse_window      = 'startify'
let g:ctrlp_prompt_mappings   = { 'MarkToOpen()': ['<C-z>', '<C-@>'], }

let g:ctrlp_use_caching         = 0 " rg is enough fast, we don't need cache
let g:ctrlp_max_files           = 0
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_match_current_file  = get(g:, 'ctrlp_match_current_file', 1)

" Only update the match window after typing's been stop for 250ms
let g:ctrlp_lazy_update = 1

let s:ctrlp_available_commands = filter(['rg', 'fd'], 'executable(v:val)')

if empty(s:ctrlp_available_commands)
    let g:ctrlp_user_command = {
                \ 'types': {
                \   1: ['.git', 'cd %s && git ls-files . --cached --others --exclude-standard'],
                \   2: ['.hg',  'hg --cwd %s locate -I .'],
                \ },
                \ }
    finish
endif

let g:ctrlp_find_tool       = get(g:, 'ctrlp_find_tool', 'rg')
let gctrlp_follow_symlinks  = get(g:, 'ctrlp_follow_symlinks', 0)
let s:ctrlp_follow_symlinks = g:ctrlp_follow_symlinks

let s:find_commands = {
            \ 'rg': 'rg %s --files --color never --no-ignore-vcs --ignore-dot --ignore-parent --hidden',
            \ 'fd': 'fd . %s --type file --color never --no-ignore-vcs --hidden',
            \ }

function! s:detect_ctrlp_current_command() abort
    let idx = index(s:ctrlp_available_commands, g:ctrlp_find_tool)
    let s:ctrlp_current_command = get(s:ctrlp_available_commands, idx > -1 ? idx : 0)
endfunction

function! s:build_user_command(...) abort
    let l:user_command = s:find_commands[s:ctrlp_current_command]
    if s:ctrlp_follow_symlinks == 1
        let l:user_command .= ' --follow'
    endif
    let g:ctrlp_user_command = l:user_command
endfunction

function! s:print_ctrlp_current_command_info() abort
    echo 'CtrlP is using command `' . g:ctrlp_user_command . '`!'
endfunction

command! PrintCtrlPCurrentCommandInfo call <SID>print_ctrlp_current_command_info()

function! s:change_ctrlp_user_command(bang, command) abort
    " Reset to default command
    if a:bang
        call s:detect_ctrlp_current_command()
    elseif strlen(a:command)
        if index(s:ctrlp_available_commands, a:command) == -1
            return
        endif
        let s:ctrlp_current_command = a:command
    else
        let idx = index(s:ctrlp_available_commands, s:ctrlp_current_command)
        let s:ctrlp_current_command = get(s:ctrlp_available_commands, idx + 1, s:ctrlp_available_commands[0])
    endif
    call s:build_user_command()
    call s:print_ctrlp_current_command_info()
endfunction

function! s:list_ctrlp_available_commands(...) abort
    return s:ctrlp_available_commands
endfunction

command! -nargs=? -bang -complete=customlist,<SID>list_ctrlp_available_commands ChangeCtrlPUserCommand call <SID>change_ctrlp_user_command(<bang>0, <q-args>)

function! s:toggle_ctrlp_follow_symlinks() abort
    if s:ctrlp_follow_symlinks == 0
        let s:ctrlp_follow_symlinks = 1
        echo 'CtrlP follows symlinks!'
    else
        let s:ctrlp_follow_symlinks = 0
        echo 'CtrlP does not follow symlinks!'
    endif
    call s:build_user_command()
endfunction

command! ToggleCtrlPFollowSymlinks call <SID>toggle_ctrlp_follow_symlinks()

call s:detect_ctrlp_current_command()
call s:build_user_command()

let g:loaded_ctrlp_settings_vim = 1
