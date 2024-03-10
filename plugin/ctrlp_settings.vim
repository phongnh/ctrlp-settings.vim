if globpath(&rtp, 'plugin/ctrlp.vim') == ''
    echohl WarningMsg | echomsg 'ctrlp.vim is not found.' | echohl none
    finish
endif

if get(g:, 'loaded_ctrlp_settings_vim', 0)
    finish
endif

let g:ctrlp_prompt_mappings   = {
            \ 'MarkToOpen()':        ['<C-z>', '<C-@>'],
            \ 'PrtClearCache()':     ['<F5>', '<C-_>', ';'],
            \ 'PrtDeleteEnt()':      ['<F7>', '<C-q>'],
            \ 'ToggleMRURelative()': ['<F2>', '`', '~'],
            \ 'YankLine()':          [],
            \ }

let g:ctrlp_match_window        = 'max:12,results:50'
let g:ctrlp_working_path_mode   = 0
let g:ctrlp_reuse_window        = 'nofile\|startify\|alpha\|dashboard'
let g:ctrlp_mruf_relative       = 0
let g:ctrlp_mruf_exclude        = '.git/.*\|/var/folders/.*\|/private/.*'
let g:ctrlp_use_caching         = get(g:, 'ctrlp_use_caching', 0) " rg/fd is enough fast, we don't need cache
let g:ctrlp_max_files           = 0
let g:ctrlp_max_depth           = 10
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_match_current_file  = get(g:, 'ctrlp_match_current_file', 1)

" Only update the match window after typing's been stop for 250ms
let g:ctrlp_lazy_update = get(g:, 'ctrlp_lazy_update', 0)

" Root markers
let g:ctrlp_root_markers = ['.git', '.hg', '.svn', '.bzr', '_darcs'] + get(g:, 'ctrlp_file_root_markers', [
            \ 'Gemfile',
            \ 'rebar.config',
            \ 'mix.exs',
            \ 'Cargo.toml',
            \ 'shard.yml',
            \ 'go.mod',
            \ '.root',
            \ ])

" BufferTag
let g:ctrlp_buftag_types = {
            \ 'crystal': '--language-force=crystal',
            \ }

let g:ctrlp_find_tool       = get(g:, 'ctrlp_find_tool', 'fd')
let g:ctrlp_find_ignore_vcs = get(g:, 'ctrlp_find_ignore_vcs', 1)
let g:ctrlp_follow_symlinks = get(g:, 'ctrlp_follow_symlinks', get(g:, 'ctrlp_follow_links', 0))

call ctrlp_settings#command#init()

" Redefine CtrlPRoot with working path mode 'ra' instead of 'r'
command! -bar CtrlPRoot call ctrlp#init('fil', { 'mode': 'ra' })
command! -nargs=? -complete=dir CtrlPAll call ctrlp_settings#ctrlp_all(<q-args>)
command! -nargs=? -complete=dir CtrlPMRUCwdFiles call ctrlp_settings#mru_cwd_files(<q-args>)
command! ToggleCtrlPFollowSymlinks call ctrlp_settings#toggle_follow_symlinks()

let g:loaded_ctrlp_settings_vim = 1
