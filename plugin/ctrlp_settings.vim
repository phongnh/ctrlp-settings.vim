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
let g:ctrlp_follow_symlinks   = 0

function! s:ctrlp_fallback() abort
    if executable('rg')
        if g:ctrlp_follow_symlinks == 0
            return 'rg %s --color=never --hidden --files -g ""'
        else
            return 'rg %s --color=never --hidden --follow --files -g ""'
        endif
    elseif executable('ag')
        if g:ctrlp_follow_symlinks == 0
            return 'ag %s --nocolor --hidden -l -g ""'
        else
            return 'ag %s --nocolor --hidden --follow -l -g ""'
        endif
    elseif executable('pt')
        if g:ctrlp_follow_symlinks == 0
            return 'pt %s --nocolor --hidden -l -g='
        else
            return 'pt %s --nocolor --hidden --follow -l -g='
        endif
    elseif has('win32') || has('win64')
        return 'dir %s /-n /b /s /a-d'
    else
        if g:ctrlp_follow_symlinks == 0
            return 'find %s -type f'
        else
            return 'find -L %s -type f'
        endif
    endif
endfunction

let g:ctrlp_use_caching  = 0
let g:ctrlp_user_command = {
            \ 'types': {
            \   1: ['.git', 'cd %s && git ls-files . --cached --others --exclude-standard'],
            \   2: ['.hg',  'hg --cwd %s locate -I .'],
            \ },
            \ 'fallback': s:ctrlp_fallback()
            \ }

function! s:toggle_ctrlp_follow_symlinks() abort
    if g:ctrlp_follow_symlinks == 0
        let g:ctrlp_follow_symlinks = 1
        echo 'CtrlP follows symlinks!'
    else
        let g:ctrlp_follow_symlinks = 0
        echo 'CtrlP does not symlinks!'
    endif

    let g:ctrlp_user_command['fallback'] = s:ctrlp_fallback()
endfunction

command! -nargs=0 ToggleCtrlPFollowSymlinks call <SID>toggle_ctrlp_follow_symlinks()
nnoremap <silent> =oA :ToggleCtrlPFollowSymlinks<CR>
nnoremap <silent> coA :ToggleCtrlPFollowSymlinks<CR>

let g:loaded_ctrlp_settings_vim = 1
