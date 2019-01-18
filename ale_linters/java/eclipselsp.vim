" Author: Horacio Sanson <https://github.com/hsanson>
" Description: Support for the Eclipse language server https://github.com/eclipse/eclipse.jdt.ls

call ale#Set('java_eclipselsp_path', 'eclipse.jdt.ls/org.eclipse.jdt.ls.product/target/repository')
call ale#Set('java_eclipselsp_executable', 'java')
call ale#Set('java_eclipselsp_data_path', '')

function! ale_linters#java#eclipselsp#Executable(buffer) abort
    return ale#Var(a:buffer, 'java_eclipselsp_executable')
endfunction

function! ale_linters#java#eclipselsp#TargetPath(buffer) abort
    return ale#Var(a:buffer, 'java_eclipselsp_path')
endfunction

function! ale_linters#java#eclipselsp#JarPath(buffer) abort
    let l:path = ale_linters#java#eclipselsp#TargetPath(a:buffer)

    return l:path . '/plugins/org.eclipse.equinox.launcher_1.5.200.v20180922-1751.jar'
endfunction

function! ale_linters#java#eclipselsp#DataPath(buffer) abort
    let l:data = ale#Var(a:buffer, 'java_eclipselsp_data_path')

    if !empty(l:data)
      return l:data
    endif

    return ale#java#FindProjectRoot(a:buffer)
endfunction

function! ale_linters#java#eclipselsp#ConfigurationPath(buffer) abort
    let l:path = ale_linters#java#eclipselsp#TargetPath(a:buffer)

    if has('win32')
      return l:path . '/config_win'
    elseif has('macunix')
      return l:path . '/config_mac'
    else
      return l:path . '/config_linux'
    endif
endfunction

function! ale_linters#java#eclipselsp#VersionCheck(version_lines) abort
    let l:version = []

    for l:line in a:version_lines
        let l:match = matchlist(l:line, '\(\d\+\)\.\(\d\+\)\.\(\d\+\)')

        if !empty(l:match)
            let l:version = [l:match[1] + 0, l:match[2] + 0, l:match[3] + 0]
            break
        endif
    endfor

    return l:version
endfunction

function! ale_linters#java#eclipselsp#Command(buffer) abort
    let l:executable = ale_linters#java#eclipselsp#Executable(a:buffer)

    if empty(l:executable)
        return ''
    endif

    let l:version_lines = split(system(ale#Escape(l:executable) . ' -version'), '\n')

    let l:version = ale_linters#java#eclipselsp#VersionCheck(l:version_lines)

    let l:cmd = [ ale#Escape(l:executable),
      \ '-Declipse.application=org.eclipse.jdt.ls.core.id1',
      \ '-Dosgi.bundles.defaultStartLevel=4',
      \ '-Declipse.product=org.eclipse.jdt.ls.core.product',
      \ '-Dlog.level=ALL',
      \ '-noverify',
      \ '-Xmx1G',
      \ '-jar',
      \ ale_linters#java#eclipselsp#JarPath(a:buffer),
      \ '-configuration',
      \ ale_linters#java#eclipselsp#ConfigurationPath(a:buffer),
      \ '-data',
      \ ale_linters#java#eclipselsp#DataPath(a:buffer)
      \ ]

    if ale#semver#GTE(l:version, [1, 9])
      call add(l:cmd, '--add-modules=ALL-SYSTEM')
      call add(l:cmd, '--add-opens java.base/java.util=ALL-UNNAMED')
      call add(l:cmd, '--add-opens java.base/java.lang=ALL-UNNAMED')
    endif

    return join(l:cmd, ' ')
endfunction

call ale#linter#Define('java', {
\   'name': 'eclipselsp',
\   'lsp': 'stdio',
\   'executable_callback': 'ale_linters#java#eclipselsp#Executable',
\   'command_callback': 'ale_linters#java#eclipselsp#Command',
\   'language': 'java',
\   'project_root_callback': 'ale#java#FindProjectRoot',
\})
