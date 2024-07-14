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

function! ctrlp_settings#toogle_follow_symlinks() abort
    if g:ctrlp_follow_symlinks == 0
        let g:ctrlp_follow_symlinks = 1
        echo 'CtrlP follows symlinks!'
    else
        let g:ctrlp_follow_symlinks = 0
        echo 'CtrlP does not follow symlinks!'
    endif
    call ctrlp_settings#command#init()
endfunction

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
function! ctrlp_settings#match(items, str, limit, mmode, ispath, crfile, regex) abort
    call clearmatches()

    if empty(a:str)
        call matchadd('CtrlPLinePre', '^>')
        return copy(a:items)
    endif

    let [l:items, l:list_of_char_positions, _] = matchfuzzypos(a:items, a:str, { 'limit': a:limit })

    " let g:_raw_items = copy(l:items)
    " let g:_items = l:items
    " let g:_detailed_items = l:items->mapnew({idx, item -> [item, l:list_of_char_positions[idx], s:ConvertCharPositions(l:list_of_char_positions[idx])]})
    " let g:_list_of_char_positions = l:list_of_char_positions
    " let g:_highlight_positions = s:HighlightPositions(l:items, l:list_of_char_positions)

    call matchaddpos('CtrlPMatch', s:HighlightPositions(l:items, l:list_of_char_positions))
    call matchadd('CtrlPLinePre', '^>')

    return l:items
endfunction

function! s:GetLinePrefixLen() abort
    let l:len = len(get(g:, 'ctrlp_line_prefix', '> '))
    if get(g:, 'ctrlp_devicons_len', 0)
        let l:len += g:ctrlp_devicons_len
    elseif exists('g:ctrlp_formatline_func') && match(g:ctrlp_formatline_func, 'nerdfont#find\|WebDevIconsGetFileTypeSymbol') > -1
        " DevIcons (4) and Space (1)
        let l:len += 4 + 1
    endif
    return l:len
endfunction

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

function! s:HighlightPositions(items, list_of_char_positions) abort
    let l:result = []
    let l:total_items = len(a:items)
    let l:line_prefix_len = s:GetLinePrefixLen()
    for [l:idx, l:char_positions] in items(a:list_of_char_positions)
        let l:item = a:items[l:idx]
        " TODO: Check CtrlP's position is bottom/top and its order is btt/ttb,
        "       to calculate number to highlight
        let l:linenr = l:total_items - (l:idx + 1) + 1
        for l:position in s:ConvertCharPositions(l:char_positions)
            let l:byteidx = byteidx(l:item, l:position[0]) + 1
            if len(l:position) == 2
                let l:bytecount = byteidx(l:item, l:position[0] + l:position[1]) + 1 - l:byteidx
                call add(l:result, [l:linenr, l:line_prefix_len + l:byteidx, l:bytecount])
            else
                call add(l:result, [l:linenr, l:line_prefix_len + l:byteidx])
            end
        endfor
    endfor
    return l:result
endfunction
