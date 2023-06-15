let g:ctrlp_file_root_markers = [
            \ 'Gemfile',
            \ 'rebar.config',
            \ 'mix.exs',
            \ 'Cargo.toml',
            \ 'shard.yml',
            \ 'go.mod',
            \ '.root',
            \ ]

let g:ctrlp_root_markers = ['.git', '.hg', '.svn', '.bzr', '_darcs'] + g:ctrlp_file_root_markers

let s:ctrlp_ignored_root_dirs = [
            \ '/',
            \ '/root',
            \ '/Users',
            \ '/home',
            \ '/usr',
            \ '/usr/local',
            \ '/opt',
            \ '/etc',
            \ '/var',
            \ expand('~'),
            \ ]

function! ctrlp_settings#find_project_dir(starting_dir) abort
    if empty(a:starting_dir)
        return ''
    endif

    let l:root_dir = ''

    for l:root_marker in g:ctrlp_root_markers
        if index(g:ctrlp_file_root_markers, l:root_marker) > -1
            let l:root_dir = findfile(l:root_marker, a:starting_dir . ';')
        else
            let l:root_dir = finddir(l:root_marker, a:starting_dir . ';')
        endif

        if l:root_dir == l:root_marker
            let l:root_dir = '.'
        else
            let l:root_dir = substitute(l:root_dir, l:root_marker . '$', '', '')
        endif

        if strlen(l:root_dir)
            let l:root_dir = fnamemodify(l:root_dir, ':p:h')
            break
        endif
    endfor

    if empty(l:root_dir) || index(s:ctrlp_ignored_root_dirs, l:root_dir) > -1
        if index(s:ctrlp_ignored_root_dirs, getcwd()) > -1
            let l:root_dir = a:starting_dir
        elseif stridx(a:starting_dir, getcwd()) == 0
            let l:root_dir = getcwd()
        else
            let l:root_dir = a:starting_dir
        endif
    endif

    return fnamemodify(l:root_dir, ':p:h:~')
endfunction

function! ctrlp_settings#ctrlp_all(dir) abort
    try
        let g:ctrlp_user_command = g:ctrlp_find_all_command
        execute 'CtrlP' a:dir
    finally
        let g:ctrlp_user_command = g:ctrlp_find_command
    endtry
endfunction

function! ctrlp_settings#mru_cwd_files(dir) abort
    let current = g:ctrlp_mruf_relative
    try
        let g:ctrlp_mruf_relative = 1
        call ctrlp#init('mru', { 'dir': a:dir })
    finally
        let g:ctrlp_mruf_relative = current
    endtry
endfunction
