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

let s:ctrlp_follow_symlinks   = 0

function! s:ctrlp_fallback() abort
    if executable('rg')
        if s:ctrlp_follow_symlinks == 0
            return 'rg %s --color=never --hidden --files'
        else
            return 'rg %s --color=never --hidden --follow --files'
        endif
    elseif executable('ag')
        if s:ctrlp_follow_symlinks == 0
            return 'ag %s --nocolor --hidden -l -g ""'
        else
            return 'ag %s --nocolor --hidden --follow -l -g ""'
        endif
    elseif executable('pt')
        if s:ctrlp_follow_symlinks == 0
            return 'pt %s --nocolor --hidden -l -g='
        else
            return 'pt %s --nocolor --hidden --follow -l -g='
        endif
    elseif has('win32') || has('win64')
        return 'dir %s /-n /b /s /a-d'
    else
        if s:ctrlp_follow_symlinks == 0
            return 'find %s -type f'
        else
            return 'find -L %s -type f'
        endif
    endif
endfunction

let s:ctrlp_user_command = {
            \ 'types': {
            \   1: ['.git', 'cd %s && git ls-files . --cached --others --exclude-standard'],
            \   2: ['.hg',  'hg --cwd %s locate -I .'],
            \ },
            \ 'fallback': s:ctrlp_fallback()
            \ }

let g:ctrlp_use_caching  = 0
let g:ctrlp_user_command = deepcopy(s:ctrlp_user_command)

let s:ctrlp_use_vcs_command = 0

function! s:toggle_ctrlp_user_command() abort
    unlet g:ctrlp_user_command

    if s:ctrlp_use_vcs_command == 0
        let s:ctrlp_use_vcs_command = 1
        let g:ctrlp_user_command = s:ctrlp_fallback()
        echo 'CtrlP is using command `' . g:ctrlp_user_command . '`!'
    else
        let s:ctrlp_use_vcs_command = 0
        let g:ctrlp_user_command = deepcopy(s:ctrlp_user_command)
        let g:ctrlp_user_command['fallback'] = s:ctrlp_fallback()
        echo 'CtrlP is using command from VCS!'
    endif
endfunction

command! -nargs=0 ToggleCtrlPUserCommand call <SID>toggle_ctrlp_user_command()

function! s:toggle_ctrlp_follow_symlinks() abort
    let msg = ''
    if s:ctrlp_follow_symlinks == 0
        let s:ctrlp_follow_symlinks = 1
        let msg = 'CtrlP follows symlinks!'
    else
        let s:ctrlp_follow_symlinks = 0
        let msg = 'CtrlP does not follow symlinks!'
    endif

    if type(g:ctrlp_user_command) == type({})
        let g:ctrlp_user_command['fallback'] = s:ctrlp_fallback()
    else
        let g:ctrlp_user_command = s:ctrlp_fallback()
        let msg .= ' `' . g:ctrlp_user_command . '`'
    endif

    echo msg
endfunction

command! -nargs=0 ToggleCtrlPFollowSymlinks call <SID>toggle_ctrlp_follow_symlinks()
nnoremap <silent> =oA :ToggleCtrlPFollowSymlinks<CR>
nnoremap <silent> coA :ToggleCtrlPFollowSymlinks<CR>

let g:loaded_ctrlp_settings_vim = 1
