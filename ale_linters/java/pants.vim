" Author: Andrew Lazarus
" Description: Lints java files using pants

call ale#Set('java_pants_executable', 'pants')
call ale#Set('java_pants_root', '')

function! ale_linters#java#pants#PantsRoot(buffer) abort
    let l:root = ale#Var(a:buffer, 'java_pants_root')

    if empty(l:root)
      let l:root = ale#java#FindProjectRoot(a:buffer)
    endif

    return l:root
endfunction

function! ale_linters#java#pants#GetDir(buffer) abort
    return fnamemodify(getcwd(), ':s?'. ale_linters#java#pants#PantsRoot(a:buffer) .'/??')
endfunction

function! ale_linters#java#pants#GetCommand(buffer) abort
    return '%e compile ' . ale#Escape(ale_linters#java#pants#GetDir(a:buffer)) . '::'
endfunction

function! ale_linters#java#pants#Handle(buffer, lines) abort
    " Look for lines like the following.
    "
    " Main.java:13: warning: [deprecation] donaught() in Testclass has been deprecated
    " Main.java:16: error: ';' expected
    let l:directory = ale_linters#java#pants#PantsRoot(a:buffer)
    let l:pattern = '\v^(\s*)(\S.*):(\d+): (.+):(.+)$'
    let l:col_pattern = '\v^(\s*\^)$'
    let l:symbol_pattern = '\v^ +symbol: *(class|method) +([^ ]+)'
    let l:output = []

    for l:match in ale#util#GetMatches(a:lines, [l:pattern, l:col_pattern, l:symbol_pattern])
        "echom join(l:match, " -|- ")
        "echom ale#path#GetAbsPath(l:directory, l:match[1])
        if empty(l:match[3]) && empty(l:match[4])
            let l:output[-1].col = len(l:match[1]) - l:output[-1].offset
        elseif empty(l:match[4])
            " Add symbols to 'cannot find symbol' errors.
            if l:output[-1].text is# 'error: cannot find symbol'
                let l:output[-1].text .= ': ' . l:match[2]
            endif
        else
            call add(l:output, {
            \   'filename': ale#path#GetAbsPath(l:directory, l:match[2]),
            \   'lnum': l:match[3] + 0,
            \   'text': l:match[4] . ':' . l:match[5],
            \   'type': l:match[4] is# 'error' ? 'E' : 'W',
            \   'offset': len(l:match[1]),
            \})
        endif
        "echom '--------------'
    endfor

    return l:output
endfunction

call ale#linter#Define('java', {
\   'name': 'pants',
\   'executable_callback': ale#VarFunc('java_pants_executable'),
\   'command_callback': 'ale_linters#java#pants#GetCommand',
\   'callback': 'ale_linters#java#pants#Handle',
\   'lint_file': 1,
\})
