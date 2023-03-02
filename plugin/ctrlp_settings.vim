if globpath(&rtp, 'plugin/ctrlp.vim') == ''
    echohl WarningMsg | echomsg 'ctrlp.vim is not found.' | echohl none
    finish
endif

if get(g:, 'loaded_ctrlp_settings_vim', 0)
    finish
endif

let g:ctrlp_prompt_mappings   = {
            \ 'MarkToOpen()':        ['<C-z>', '<C-@>'],
            \ 'PrtClearCache()':     ['<F5>', '<C-_>', '!'],
            \ 'PrtDeleteEnt()':      ['<F7>', '<C-q>'],
            \ 'ToggleMRURelative()': ['<F2>', '?'],
            \ 'YankLine()':          [],
            \ }

let g:ctrlp_match_window        = 'max:12,results:50'
let g:ctrlp_working_path_mode   = 0
let g:ctrlp_reuse_window        = 'nofile\|startify'
let g:ctrlp_mruf_relative       = 1
let g:ctrlp_tilde_homedir       = get(g:, 'ctrlp_tilde_homedir', 1)
let g:ctrlp_use_caching         = get(g:, 'ctrlp_use_caching', 0) " rg/fd is enough fast, we don't need cache
let g:ctrlp_max_files           = 0
let g:ctrlp_max_depth           = 10
let g:ctrlp_clear_cache_on_exit = get(g:, 'ctrlp_clear_cache_on_exit', 0)
let g:ctrlp_match_current_file  = get(g:, 'ctrlp_match_current_file', 1)

" Only update the match window after typing's been stop for 250ms
let g:ctrlp_lazy_update = get(g:, 'ctrlp_lazy_update', 0)

let s:ctrlp_available_commands = filter(['fd', 'rg'], 'executable(v:val)')

" Redefine CtrlPRoot with working path mode 'ra' instead of 'r'
command! -bar CtrlPRoot call ctrlp#init('fil', { 'mode': 'ra' })

command! -bar CtrlPSmartRoot execute 'CtrlP' ctrlp_settings#find_project_dir(expand('%:p:h'))

let s:ctrlp_user_command = {
                \ 'types': {
                \   1: ['.git', 'cd %s && git ls-files . --cached --others --exclude-standard'],
                \   2: ['.hg',  'hg --cwd %s locate -I .'],
                \ },
                \ }

if empty(s:ctrlp_available_commands)
    let g:ctrlp_user_command = deepcopy(s:ctrlp_user_command)
    command! -nargs=? -complete=dir CtrlPAll :CtrlP <args>
    finish
endif

let g:ctrlp_find_tool       = get(g:, 'ctrlp_find_tool', 'fd')
let g:ctrlp_follow_symlinks = get(g:, 'ctrlp_follow_symlinks', get(g:, 'ctrlp_follow_links', 0))
let s:ctrlp_follow_symlinks = g:ctrlp_follow_symlinks

let s:find_commands = {
            \ 'fd': 'fd --base-directory %s --type file --color never --no-ignore-vcs --hidden --strip-cwd-prefix',
            \ 'rg': 'rg %s --files --color never --no-ignore-vcs --ignore-dot --ignore-parent --hidden',
            \ }

let s:find_all_commands = {
            \ 'fd': 'fd --base-directory %s --type file --color never --no-ignore --hidden --follow --strip-cwd-prefix',
            \ 'rg': 'rg %s --files --color never --no-ignore --hidden --follow',
            \ }

function! s:build_find_command() abort
    let l:cmd = s:find_commands[s:ctrlp_current_command]
    if s:ctrlp_follow_symlinks == 1
        let l:cmd .= ' --follow'
    endif
    return l:cmd
endfunction

function! s:build_find_all_command() abort
    let l:cmd = s:find_all_commands[s:ctrlp_current_command]
    return l:cmd
endfunction

function! s:detect_ctrlp_current_command() abort
    let idx = index(s:ctrlp_available_commands, g:ctrlp_find_tool)
    let s:ctrlp_current_command = get(s:ctrlp_available_commands, idx > -1 ? idx : 0)
endfunction

function! s:build_ctrlp_user_command() abort
    let g:ctrlp_user_command = s:build_find_command()
endfunction

function! s:build_ctrlp_user_command_with_vcs() abort
    let g:ctrlp_user_command = deepcopy(s:ctrlp_user_command)
    let g:ctrlp_user_command['fallback'] = s:build_find_command()
endfunction

function! s:print_ctrlp_current_command_info() abort
    if type(g:ctrlp_user_command) == type({})
        echo 'CtrlP is using VCS with fallback command `' . g:ctrlp_user_command['fallback'] . '`!'
    else
        echo 'CtrlP is using command `' . g:ctrlp_user_command . '`!'
    endif
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
    elseif type(g:ctrlp_user_command) != type({})
        let idx = index(s:ctrlp_available_commands, s:ctrlp_current_command)
        let s:ctrlp_current_command = get(s:ctrlp_available_commands, idx + 1, s:ctrlp_available_commands[0])
    endif
    call s:build_ctrlp_user_command()
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
    call s:build_ctrlp_user_command()
endfunction

command! ToggleCtrlPFollowSymlinks call <SID>toggle_ctrlp_follow_symlinks()

function! s:ctrlp_all(dir) abort
    try
        let g:ctrlp_user_command = s:build_find_all_command()
        execute 'CtrlP' a:dir
    finally
        call s:build_ctrlp_user_command()
    endtry
endfunction

command! -nargs=? -complete=dir CtrlPAll call <SID>ctrlp_all(<q-args>)

call s:detect_ctrlp_current_command()

if get(g:, 'ctrlp_use_vcs_tool', 1)
    call s:build_ctrlp_user_command_with_vcs()
else
    call s:build_ctrlp_user_command()
endif

let g:loaded_ctrlp_settings_vim = 1
