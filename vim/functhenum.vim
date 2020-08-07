" replace decimal under cursor or the visual selection with a different
" number format (hex, binary, etc.)

" TODO: the matching amounts to 'word contains', is that what we want?
let s:pattern = {
    \ 'binary':  '\v(<[0-1]{8}\s?)+',
    \ 'hex':     '\v<\x*>',
    \ 'float':   '\v<\d+\.\d+>',
    \ 'decimal': '\v<\d+>',
    \ 'octal':   '\v<\o+>'
\}

let s:selectors = {
    \ 2:   'binary',
    \ 8:   'octal',
    \ 10:  'decimal',
    \ '≈': 'float',
    \ 16:  'hex',
    \ 'nope': 'noop'
\}

function! FuncTheNum(mode) abort "{{{
    let word = <SID>word(a:mode)
    echom "Considering converting: " . word
    let conversions = <SID>conversions(word)

    if empty(conversions)
        echo "No conversion possible"
        return
    endif

    let noop = "nope"
    let conversions[noop] = word

    let input_msg = "Convert from:\n"
    for selector in keys(conversions)
        let input_msg .= printf("(%s) %s\n", selector, s:selectors[selector])
    endfor
    let choice = input(input_msg)
    redraw
    if choice == noop
        return
    elseif !index(keys(conversions), string(choice))
        echoerr "Invalid choice: " . choice
        return
    endif

    let conversion = conversions[choice]
    let input_msg = "Convert to:\n"
    for item in items(conversion)
        let selector = item[0]
        let input_msg .= printf("(%s) %s\n", selector, item[1])
    endfor
    let choice = input(input_msg)
    redraw

    if !index(keys(conversion), string(choice))
        echoerr "Invalid choice: " . choice
        return
    endif

    let newword = conversion[choice]
    " for now just replace the fist occurrence of input word
    execute 'substitute/' . word . '/' . newword . '/'
endfunction "}}}

" Read word from visual selection or under cursor {{{
function! s:word(mode) abort
    if a:mode == 'n'
        let word = expand("<cWORD>")
        execute "normal! viw\<Esc>"
    elseif a:mode == 'v'
        let save_reg = getreg('a', 1, 1)
        let save_reg_type = getregtype('a')
        execute "normal! \<Esc>gv\"ay"
        call setreg('a', '', 'ac')
        let word = @a
        call setreg('a', save_reg, save_reg_type)
    else
        echoerr "invalid mode (" . a:mode . ")"
    endif
    return word
endfunction "}}}

" Possible conversions for word, depending on input format {{{
function! s:conversions(word) abort
    let conversions = {}
    if a:word =~ s:pattern['binary']
        let decimal = <SID>binary2decimal(a:word)
        let conversions['2'] = {8: <SID>decimal2octal(decimal), 10: decimal, 16: <SID>decimal2hex(decimal)}
    endif

    if a:word =~ s:pattern['octal']
        let decimal = <SID>octal2decimal(a:word)
        let conversions['8'] = {2: <SID>decimal2binary(decimal), 8: <SID>decimal2octal(decimal), 10: decimal, 16: <SID>decimal2hex(decimal)}
    endif

    if a:word =~ s:pattern['decimal']
        let conversions[10] = {2: printf("%08b", a:word), 8: printf("%o", a:word), 16: printf("%04X", a:word)}
    endif

    if a:word =~ s:pattern['float']
        let decimal = round(a:word)
        let conversions['≈'] = {'≈': decimal, 2: <SID>decimal2binary(decimal), 8: <SID>decimal2octal(decimal), 10: decimal, 16: <SID>decimal2hex(decimal)}
    endif

    if a:word =~ s:pattern['hex']
        let decimal = <SID>hex2decimal(a:word)
        let conversions['16'] = {2: <SID>decimal2binary(decimal), 8: <SID>decimal2octal(decimal), 10: decimal}
    endif

    return conversions
endfunction "}}}

" Convert from decimal {{{
function! s:decimal2byte(num) abort
    return printf("%02c", a:num)
endfunction

function! s:decimal2binary(num) abort
    return printf("%08b", a:num)
endfunction

function! s:decimal2octal(num) abort
    return printf("%o", a:num)
endfunction

function! s:decimal2hex(num) abort
    return printf("%04X", a:num)
endfunction
" }}}

" Convert to decimal {{{
function! s:binary2decimal(num) abort
    return str2nr(a:num, 2)
endfunction

function! s:octal2decimal(num) abort
    return str2nr(a:num, 8)
endfunction

function! s:hex2decimal(num) abort
    return str2nr(a:num, 16)
endfunction "}}}

nnoremap <Leader>num :call FuncTheNum('n')<CR>
xnoremap <Leader>num :call FuncTheNum('v')<CR>
