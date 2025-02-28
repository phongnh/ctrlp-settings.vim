" A matching function for CtrlP using pfzy (pip3 install pfzy -break-system-packages)
" Arguments:
" |
" +- a:items  : The full list of items to search in.
" |
" +- a:str    : The string entered by the user.
" |
" +- a:limit  : The max height of the match window. Can be used to limit
" |             the number of items to return.
" |
" +- a:mmode  : The match mode. Can be one of these strings:
" |             + "full-line": match the entire line.
" |             + "filename-only": match only the filename.
" |             + "first-non-tab": match until the first tab char.
" |             + "until-last-tab": match until the last tab char.
" |
" +- a:ispath : Is 1 when searching in file, buffer, mru, mixed, dir, and
" |             rtscript modes. Is 0 otherwise.
" |
" +- a:crfile : The file in the current window. Should be excluded from the
" |             results when a:ispath == 1.
" |
" +- a:regex  : In regex mode: 1 or 0.

let s:timer = 0

unsilent execute 'py3file ' . escape(expand('<sfile>:p:h'), '\') . '/pfzy.py'

function! ctrlp_settings#pfzy#match(items, str, limit, mmode, ispath, crfile, regex) abort
    if empty(a:str)
        call clearmatches()
        return a:items[:(a:limit)]
    endif

    call timer_stop(s:timer)

    if a:regex
        let s:timer = timer_start(
                    \ 10,
                    \ { t -> [clearmatches(), matchadd('CtrlPMatch', a:str), hlexists('CtrlPLinePre') ? matchadd('CtrlPLinePre', '^>') : '', execute('redraw')] },
                    \ { 'repeat': 0 }
                    \ )
        return filter(copy(a:items), 'v:val =~ a:str')
    endif

    if ctrlp#call('s:curtype') ==# 'buf'
        let s:timer = timer_start(
                    \ 10,
                    \ { t -> [clearmatches(), ctrlp_settings#utils#HighlightDefault(a:str), hlexists('CtrlPLinePre') ? matchadd('CtrlPLinePre', '^>') : '', execute('redraw')] },
                    \ { 'repeat': 0 }
                    \ )
        return matchfuzzy(a:items, a:str, { 'limit': a:limit })
    endif

    " pass arguments to pfzy_match function in pfzy.py
    let s:pfzy_needle = a:str
    let s:pfzy_haystacks = a:items
    let l:result = py3eval("pfzy_match()")
    let l:result = l:result[:(a:limit)]
    let l:items = []
    let l:list_of_char_positions = []
    for row in l:result
        call add(l:items, row['value'])
        call add(l:list_of_char_positions, row['indices']))
    endfor

    let l:line_prefix_len = ctrlp_settings#utils#GetLinePrefixLen(a:ispath)
    let s:timer = timer_start(
                \ 10,
                \ { t -> [clearmatches(), ctrlp_settings#utils#HighlightPositions(l:items, l:list_of_char_positions, l:line_prefix_len), hlexists('CtrlPLinePre') ? matchadd('CtrlPLinePre', '^>') : '', execute('redraw')] },
                \ { 'repeat': 0 }
                \ )
    return l:items
endfunction
