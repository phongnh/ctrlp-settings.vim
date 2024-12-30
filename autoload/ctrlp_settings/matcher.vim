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

function! ctrlp_settings#matcher#match(items, str, limit, mmode, ispath, crfile, regex) abort
    " let g:_input_items = a:items
    " let g:_limit = a:limit
    " let g:_ispath = a:ispath
    " let g:_mmode = a:mmode

    if empty(a:str)
        call clearmatches()
        return a:items[:(a:limit)]
    endif

    call timer_stop(s:timer)

    if a:regex
        let s:timer = timer_start(
                    \ 10,
                    \ {t -> [clearmatches(), matchadd('CtrlPMatch', a:str), hlexists('CtrlPLinePre') ? matchadd('CtrlPLinePre', '^>') : '', execute('redraw')]},
                    \ { 'repeat': 0 }
                    \ )
        return filter(copy(a:items), 'v:val =~ a:str')
    endif

    if ctrlp#call('s:curtype') ==# 'buf'
        let s:timer = timer_start(
                    \ 10,
                    \ {t -> [clearmatches(), s:HighlightDefault(a:str), hlexists('CtrlPLinePre') ? matchadd('CtrlPLinePre', '^>') : '', execute('redraw')]},
                    \ { 'repeat': 0 }
                    \ )
        return matchfuzzy(a:items, a:str, { 'limit': a:limit })
    endif

    let l:line_prefix_len = s:GetLinePrefixLen(a:ispath)
    let [l:items, l:list_of_char_positions, _] = matchfuzzypos(a:items, a:str, { 'limit': a:limit })

    " let g:_curtype = ctrlp#call('s:curtype')
    " let g:_raw_items = copy(l:items)
    " let g:_items = l:items
    " let g:_detailed_items = l:items->mapnew({idx, item -> [item, l:list_of_char_positions[idx], s:ConvertCharPositions(l:list_of_char_positions[idx])]})
    " let g:_list_of_char_positions = l:list_of_char_positions
    " let g:_highlight_positions = s:HighlightPositions(l:items, l:list_of_char_positions, l:line_prefix_len)

    let s:timer = timer_start(
                \ 10,
                \ {t -> [clearmatches(), s:HighlightPositions(l:items, l:list_of_char_positions, l:line_prefix_len), hlexists('CtrlPLinePre') ? matchadd('CtrlPLinePre', '^>') : '', execute('redraw')]},
                \ { 'repeat': 0 }
                \ )

    return l:items
endfunction

function s:Esc(str) abort
    return '\c' . substitute(tolower(a:str), '.', '\0[^\0]\\{-}', 'g')
endfunction

function! s:GetLinePrefixLen(ispath) abort
    let l:len = len(get(g:, 'ctrlp_line_prefix', '> '))
    if a:ispath && get(g:, 'ctrlp_devicons_len', 0)
        let l:len += g:ctrlp_devicons_len
    elseif a:ispath && exists('g:ctrlp_formatline_func') && match(g:ctrlp_formatline_func, 'nerdfont#find\|WebDevIconsGetFileTypeSymbol') > -1
        " DevIcons (4) and Space (1)
        let l:len += 4 + 1
    endif
    return l:len
endfunction

"Copied and modified code from https://github.com/Donaldttt/fuzzyy/blob/3fa5c1ca430afb033e69d373af5e4c22d8107315/autoload/utils/selector.vim#L138
function! s:ConvertCharPositions(char_positions) abort
    let l:result = []
    let l:start = a:char_positions[0]
    let l:end = l:start
    let l:len = 1
    for l:idx in range(1, len(a:char_positions) - 1)
        let l:pos = a:char_positions[l:idx]
        if l:pos == (l:end + 1)
            let l:len += 1
        else
            if l:len > 1
                call add(l:result, [l:start, l:len])
            else
                call add(l:result, [l:start])
            endif
            let l:start = l:pos
            let l:end = l:start
            let l:len = 1
        endif
        let l:end = l:pos
    endfor
    if l:len > 1
        call add(l:result, [l:start, l:len])
    else
        call add(l:result, [l:start])
    endif
    return l:result
endfunction

function! s:HighlightPositions(items, list_of_char_positions, line_prefix_len) abort
    let l:result = []
    let l:total_items = len(a:items)
    for l:idx in range(len(a:list_of_char_positions))
        let l:char_positions = a:list_of_char_positions[l:idx]
        " TODO: Check CtrlP's position is bottom/top and its order is btt/ttb,
        "       to calculate line number to highlight
        let l:linenr = l:total_items - (l:idx + 1) + 1
        let l:item = a:items[l:linenr - 1]
        for l:position in s:ConvertCharPositions(l:char_positions)
            let l:byteidx = byteidx(l:item, l:position[0]) + 1
            if len(l:position) == 2
                let l:bytecount = byteidx(l:item, l:position[0] + l:position[1]) + 1 - l:byteidx
                call add(l:result, [l:linenr, a:line_prefix_len + l:byteidx, l:bytecount])
            else
                call add(l:result, [l:linenr, a:line_prefix_len + l:byteidx])
            end
        endfor
    endfor
    call matchaddpos('CtrlPMatch', l:result)
endfunction

" Copied and modified from https://github.com/ctrlpvim/ctrlp.vim/blob/7c972cb19c8544c681ca345c64ec39e04f4651cc/autoload/ctrlp.vim#L2597
function! s:BuildPattern(lst) abort
    let pat = a:lst[0]
    if get(g:, 'ctrlp_match_natural_name', 0) == 1
        for item in range(1, len(a:lst) - 1)
            let c = a:lst[item - 1]
            let pat .= (c == '/' ? '[^/]\{-}' : '[^'.c.'/]\{-}').a:lst[item]
        endfor
    else
        for item in range(1, len(a:lst) - 1)
            let pat .= '[^'.a:lst[item - 1].']\{-}'.a:lst[item]
        endfor
    endif
    return pat
endfunction

" Copied and modified from https://github.com/ctrlpvim/ctrlp.vim/blob/7c972cb19c8544c681ca345c64ec39e04f4651cc/autoload/ctrlp.vim#L701
function! s:SplitPattern(str) abort
    let lst = split(a:str, '\zs')
    if exists('+shellslash') && !&shellslash
        cal map(lst, 'escape(v:val, ''\'')')
    endif
    for each in ['^', '$', '.']
        cal map(lst, 'escape(v:val, each)')
    endfor
    let pat = ''
    if !empty(lst)
        let pat = s:BuildPattern(lst)
    endif
    return escape(pat, '~')
endfunction

" Copied and modified from https://github.com/ctrlpvim/ctrlp.vim/blob/7c972cb19c8544c681ca345c64ec39e04f4651cc/autoload/ctrlp.vim#L2008
function! s:HighlightDefault(str) abort
    let l:smartcase = &smartcase && a:str =~ '\u' ? '\C' : ''

    let pat = s:SplitPattern(a:str)

    " get original characters so we can rebuild pat
    let chars = split(pat, '\[\^\\\?.\]\\{-}')

    " Build a pattern like /a.*b.*c/ from abc (but with .\{-} non-greedy
    " matchers instead)
    let pat = join(chars, '.\{-}')
    " Ensure we match the last version of our pattern
    let ending = '\(.*'.pat.'\)\@!'
    " Case sensitive?
    let beginning = (l:smartcase == '' ? '\c' : '\C') . '^.*'

    for i in range(len(chars))
        " Surround our current target letter with \zs and \ze so it only
        " actually matches that one letter, but has all preceding and trailing
        " letters as well.
        " \zsa.*b.*c
        " a\(\zsb\|.*\zsb)\ze.*c
        let charcopy = copy(l:chars)
        if i == 0
            let charcopy[i] = '\zs'.charcopy[i].'\ze'
            let middle = join(charcopy, '.\{-}')
        else
            let before = join(charcopy[0:i-1], '.\{-}')
            let after = join(charcopy[i+1:-1], '.\{-}')
            let c = charcopy[i]
            " for abc, match either ab.\{-}c or a.*b.\{-}c in that order
            let cpat = '\(\zs'.c.'\|'.'.*\zs'.c.'\)\ze.*'
            let middle = before.cpat.after
        endif

        " Now we matchadd for each letter, the basic form being:
        " ^.*\zsx\ze.*$, but with our pattern we built above for the letter,
        " and a negative lookahead ensuring that we only highlight the last
        " occurrence of our letters. We also ensure that our matcher is case
        " insensitive or sensitive depending.
        call matchadd('CtrlPMatch', beginning.middle.ending)
    endfor
endfunction
