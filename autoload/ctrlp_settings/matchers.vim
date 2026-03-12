function! ctrlp_settings#matchers#GetLinePrefixLen(ispath) abort
    let l:len = len(get(g:, 'ctrlp_line_prefix', '> '))
    if a:ispath
        if get(g:, 'ctrlp_devicons_len', 0)
            let l:len += g:ctrlp_devicons_len
        elseif exists('g:ctrlp_formatline_func') && match(g:ctrlp_formatline_func, 'nerdfont#find\|WebDevIconsGetFileTypeSymbol') > -1
            " DevIcons (1) and Space (1)
            let g:ctrlp_devicons_len = 1 + 1
            let l:len += g:ctrlp_devicons_len
        endif
    endif
    return l:len
endfunction

" Reset all matcher caches - useful for manual cache clearing
function! ctrlp_settings#matchers#reset_all() abort
    try
        call ctrlp_settings#matchers#matchfuzzy#reset()
    catch
    endtry
    try
        call ctrlp_settings#matchers#matchfuzzypos#reset()
    catch
    endtry
endfunction

function ctrlp_settings#matchers#Esc(str) abort
    return '\c' . substitute(tolower(a:str), '.', '\0[^\0]\\{-}', 'g')
endfunction

function! ctrlp_settings#matchers#HighlightPositions(items, list_of_char_positions, line_prefix_len) abort
    let l:result = []
    let l:total_items = len(a:items)
    
    " Pre-calculate line numbers to avoid repeated arithmetic
    let l:max_positions = len(a:list_of_char_positions)
    
    for l:idx in range(l:max_positions)
        let l:char_positions = a:list_of_char_positions[l:idx]
        
        " Skip empty position lists early
        if empty(l:char_positions)
            continue
        endif
        
        " TODO: Check CtrlP's position is bottom/top and its order is btt/ttb,
        "       to calculate line number to highlight
        let l:linenr = l:total_items - l:idx
        let l:item = a:items[l:linenr - 1]
        
        " Convert char positions to ranges once
        let l:positions = s:ConvertCharPositions(l:char_positions)
        
        " Pre-allocate result size hint for better performance
        for l:position in l:positions
            let l:byteidx = byteidx(l:item, l:position[0]) + 1
            if len(l:position) == 2
                let l:bytecount = byteidx(l:item, l:position[0] + l:position[1]) + 1 - l:byteidx
                call add(l:result, [l:linenr, a:line_prefix_len + l:byteidx, l:bytecount])
            else
                call add(l:result, [l:linenr, a:line_prefix_len + l:byteidx])
            endif
        endfor
    endfor
    
    " Single matchaddpos call is more efficient than multiple calls
    if !empty(l:result)
        call matchaddpos('CtrlPMatch', l:result)
    endif
endfunction

"Copied and modified code from https://github.com/Donaldttt/fuzzyy/blob/3fa5c1ca430afb033e69d373af5e4c22d8107315/autoload/utils/selector.vim#L138
function! s:ConvertCharPositions(char_positions) abort
    let l:result = []
    let l:pos_count = len(a:char_positions)
    
    " Early return for empty or single position
    if l:pos_count == 0
        return l:result
    elseif l:pos_count == 1
        return [[a:char_positions[0]]]
    endif
    
    let l:start = a:char_positions[0]
    let l:end = l:start
    let l:len = 1
    
    for l:idx in range(1, l:pos_count - 1)
        let l:pos = a:char_positions[l:idx]
        if l:pos == (l:end + 1)
            let l:len += 1
            let l:end = l:pos
        else
            " Add previous range
            call add(l:result, l:len > 1 ? [l:start, l:len] : [l:start])
            let l:start = l:pos
            let l:end = l:pos
            let l:len = 1
        endif
    endfor
    
    " Add final range
    call add(l:result, l:len > 1 ? [l:start, l:len] : [l:start])
    
    return l:result
endfunction

" Copied and modified from https://github.com/ctrlpvim/ctrlp.vim/blob/7c972cb19c8544c681ca345c64ec39e04f4651cc/autoload/ctrlp.vim#L2008
function! ctrlp_settings#matchers#HighlightDefault(str) abort
    let l:smartcase = &smartcase && a:str =~ '\u' ? '\C' : ''

    let l:pat = s:SplitPattern(a:str)

    " get original characters so we can rebuild pat
    let l:chars = split(l:pat, '\[\^\\\?.\]\\{-}')

    " Early return if no chars to highlight
    if empty(l:chars)
        return
    endif

    " Build a pattern like /a.*b.*c/ from abc (but with .\{-} non-greedy
    " matchers instead)
    let l:pat = join(l:chars, '.\{-}')
    " Ensure we match the last version of our pattern
    let l:ending = '\(.*' .. l:pat .. '\)\@!'
    " Case sensitive?
    let l:beginning = (l:smartcase == '' ? '\c' : '\C') .. '^.*'

    let l:char_count = len(l:chars)
    for l:i in range(l:char_count)
        " Surround our current target letter with \zs and \ze so it only
        " actually matches that one letter, but has all preceding and trailing
        " letters as well.
        " \zsa.*b.*c
        " a\(\zsb\|.*\zsb)\ze.*c
        let l:charcopy = copy(l:chars)
        if l:i == 0
            let l:charcopy[l:i] = '\zs' .. l:charcopy[l:i] .. '\ze'
            let l:middle = join(l:charcopy, '.\{-}')
        else
            let l:before = join(l:charcopy[0:l:i-1], '.\{-}')
            let l:after = join(l:charcopy[l:i+1:-1], '.\{-}')
            let l:c = l:charcopy[l:i]
            " for abc, match either ab.\{-}c or a.*b.\{-}c in that order
            let l:cpat = '\(\zs' .. l:c .. '\|' .. '.*\zs' .. l:c .. '\)\ze.*'
            let l:middle = l:before .. l:cpat .. l:after
        endif

        " Now we matchadd for each letter, the basic form being:
        " ^.*\zsx\ze.*$, but with our pattern we built above for the letter,
        " and a negative lookahead ensuring that we only highlight the last
        " occurrence of our letters. We also ensure that our matcher is case
        " insensitive or sensitive depending.
        call matchadd('CtrlPMatch', l:beginning .. l:middle .. l:ending)
    endfor
endfunction

" Copied and modified from https://github.com/ctrlpvim/ctrlp.vim/blob/7c972cb19c8544c681ca345c64ec39e04f4651cc/autoload/ctrlp.vim#L701
function! s:SplitPattern(str) abort
    let l:lst = split(a:str, '\zs')
    if exists('+shellslash') && !&shellslash
        cal map(l:lst, 'escape(v:val, ''\'')')
    endif
    for l:each in ['^', '$', '.']
        cal map(l:lst, 'escape(v:val, l:each)')
    endfor
    let l:pat = ''
    if !empty(l:lst)
        let l:pat = s:BuildPattern(l:lst)
    endif
    return escape(l:pat, '~')
endfunction

" Copied and modified from https://github.com/ctrlpvim/ctrlp.vim/blob/7c972cb19c8544c681ca345c64ec39e04f4651cc/autoload/ctrlp.vim#L2597
function! s:BuildPattern(lst) abort
    let l:pat = a:lst[0]
    if get(g:, 'ctrlp_match_natural_name', 0) == 1
        for l:item in range(1, len(a:lst) - 1)
            let l:c = a:lst[l:item - 1]
            let l:pat ..= (l:c == '/' ? '[^/]\{-}' : '[^' .. l:c .. '/]\{-}') .. a:lst[l:item]
        endfor
    else
        for l:item in range(1, len(a:lst) - 1)
            let l:pat ..= '[^' .. a:lst[l:item - 1] .. ']\{-}' .. a:lst[l:item]
        endfor
    endif
    return l:pat
endfunction
