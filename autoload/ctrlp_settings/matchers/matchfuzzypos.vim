" A matching function for CtrlP using matchfuzzypos function
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
let s:is_buf_mode = -1
let s:line_prefix_len = -1
let s:last_mode = ''

function! ctrlp_settings#matchers#matchfuzzypos#match(items, str, limit, mmode, ispath, crfile, regex) abort
    " Detect mode changes and reset cache automatically
    let l:current_mode = ctrlp#call('s:curtype')
    if s:last_mode !=# l:current_mode
        call ctrlp_settings#matchers#matchfuzzypos#reset()
        let s:last_mode = l:current_mode
    endif

    if empty(a:str)
        call clearmatches()
        return a:items[:(a:limit)]
    endif

    " Early return for regex mode - avoid timer overhead
    if a:regex
        if s:timer
            call timer_stop(s:timer)
        endif
        let s:timer = timer_start(
                    \ 10,
                    \ { t -> [clearmatches(), matchadd('CtrlPMatch', a:str), hlexists('CtrlPLinePre') ? matchadd('CtrlPLinePre', '^>') : '', execute('redraw')] },
                    \ { 'repeat': 0 }
                    \ )
        return filter(copy(a:items), 'v:val =~ a:str')
    endif

    " Cache buffer mode check to avoid repeated function calls
    if s:is_buf_mode == -1
        let s:is_buf_mode = (l:current_mode ==# 'buf') ? 1 : 0
    endif

    if s:is_buf_mode
        if s:timer
            call timer_stop(s:timer)
        endif
        let s:timer = timer_start(
                    \ 10,
                    \ { t -> [clearmatches(), ctrlp_settings#matchers#HighlightDefault(a:str), hlexists('CtrlPLinePre') ? matchadd('CtrlPLinePre', '^>') : '', execute('redraw')] },
                    \ { 'repeat': 0 }
                    \ )
        return matchfuzzy(a:items, a:str, { 'limit': a:limit })
    endif

    " Perform fuzzy matching with limit
    let [l:items, l:list_of_char_positions, l:_] = matchfuzzypos(a:items, a:str, { 'limit': a:limit })

    " Cache line prefix length calculation
    if s:line_prefix_len == -1
        let s:line_prefix_len = ctrlp_settings#matchers#GetLinePrefixLen(a:ispath)
    endif

    if s:timer
        call timer_stop(s:timer)
    endif
    let s:timer = timer_start(
                \ 10,
                \ { t -> [clearmatches(), ctrlp_settings#matchers#HighlightPositions(l:items, l:list_of_char_positions, s:line_prefix_len), hlexists('CtrlPLinePre') ? matchadd('CtrlPLinePre', '^>') : '', execute('redraw')] },
                \ { 'repeat': 0 }
                \ )
    return l:items
endfunction

" Reset cache when switching modes
function! ctrlp_settings#matchers#matchfuzzypos#reset() abort
    let s:is_buf_mode = -1
    let s:line_prefix_len = -1
    " Note: s:last_mode is intentionally not reset to track mode changes
endfunction
