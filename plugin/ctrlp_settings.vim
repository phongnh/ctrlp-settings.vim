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
let g:ctrlp_mruf_relative       = 0
let g:ctrlp_mruf_exclude        = '.git/.*\|/var/folders/.*\|/private/.*'
let g:ctrlp_use_caching         = get(g:, 'ctrlp_use_caching', 0) " rg/fd is enough fast, we don't need cache
let g:ctrlp_max_files           = 0
let g:ctrlp_max_depth           = 10
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_match_current_file  = get(g:, 'ctrlp_match_current_file', 1)

" Only update the match window after typing's been stop for 250ms
let g:ctrlp_lazy_update = get(g:, 'ctrlp_lazy_update', 0)

" BufferTag
let g:ctrlp_buftag_types = {
            \ 'crystal': '--language-force=crystal',
            \ }

let g:ctrlp_find_tool       = get(g:, 'ctrlp_find_tool', 'fd')
let g:ctrlp_follow_symlinks = get(g:, 'ctrlp_follow_symlinks', get(g:, 'ctrlp_follow_links', 0))

function! s:build_find_command() abort
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

function! s:build_find_all_command() abort
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

" Redefine CtrlPRoot with working path mode 'ra' instead of 'r'
command! -bar CtrlPRoot call ctrlp#init('fil', { 'mode': 'ra' })
command! -nargs=? -complete=dir CtrlPAll call ctrlp_settings#ctrlp_all(<q-args>)
command! -nargs=? -complete=dir CtrlPMRUCwdFiles call ctrlp_settings#mru_cwd_files(<q-args>)

function! s:toggle_ctrlp_follow_symlinks() abort
    if g:ctrlp_follow_symlinks == 0
        let g:ctrlp_follow_symlinks = 1
        echo 'CtrlP follows symlinks!'
    else
        let g:ctrlp_follow_symlinks = 0
        echo 'CtrlP does not follow symlinks!'
    endif
    call s:build_ctrlp_user_command()
endfunction

command! ToggleCtrlPFollowSymlinks call <SID>toggle_ctrlp_follow_symlinks()

function! s:build_ctrlp_user_command()
    if get(g:, 'ctrlp_use_vcs_tool', 1)
        let g:ctrlp_user_command = {
                    \ 'types': {
                    \   1: ['.git', 'cd %s && git ls-files . --cached --others --exclude-standard'],
                    \   2: ['.hg',  'hg --cwd %s locate -I .'],
                    \ },
                    \ 'fallback': s:build_find_command(),
                    \ }
    else
        let g:ctrlp_user_command = s:build_find_command()
    endif
endfunction

function! s:setup_ctrlp_settings() abort
    call s:build_find_all_command()
    call s:build_ctrlp_user_command()
endfunction

augroup CtrlPSettings
    autocmd!
    autocmd VimEnter * call <SID>setup_ctrlp_settings()
augroup END

let g:loaded_ctrlp_settings_vim = 1
