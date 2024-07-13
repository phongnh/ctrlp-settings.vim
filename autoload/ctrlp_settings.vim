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

    let l:size = len(l:list_of_char_positions)
    let l:prefix_len = len(get(g:, 'ctrlp_line_prefix', '> '))
    " TODO: Check CtrlP's position is bottom/top and its order is btt/ttb,
    "       to calculate number to highlight
    let l:positions = l:list_of_char_positions->mapnew(
                \ {idx, char_positions -> char_positions->mapnew(
                \   {_, pos -> [l:size - idx, pos + 1 + l:prefix_len]})}
                \ )
    for l:pos in l:positions
        call matchaddpos('CtrlPMatch', l:pos)
    endfor

    call matchadd('CtrlPLinePre', '^>')

    return l:items
endfunction
