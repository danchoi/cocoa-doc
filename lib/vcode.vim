" This project tries to turn Vim into a useful iOS development tool.
" Maintainer: Daniel Choi <dhchoi@gmail.com>
" License: MIT License (c) 2011 Daniel Choi

if exists("g:VcodeLoaded") || &cp || version < 700
  finish
endif
let g:VcodeLoaded = 1

let mapleader = ','
let s:client_script = 'vcode_client '

function! s:common_mappings()
  nnoremap <buffer> <leader>c :call <SID>list_classes()<cr>
endfunction

function! s:create_list_window()
  new list_window
  wincmd p 
  close
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal modifiable
  setlocal textwidth=0
  setlocal nowrap
  setlocal number
  setlocal foldcolumn=0
  setlocal nospell
  " setlocal noreadonly
  " hi CursorLine cterm=NONE ctermbg=darkred ctermfg=white guibg=darkred guifg=white 
  setlocal cursorline
  " we need to find the window later
  let s:listbufnr = bufnr('')
  let s:listbufname = bufname('')
  call s:common_mappings()

endfunction


function! s:open_selection_window(selectionlist, buffer_name, prompt)
  let s:selectionlist = a:selectionlist 
  call s:focus_window(s:listbufnr)
  exec "leftabove split ".a:buffer_name
  setlocal textwidth=0
  setlocal completefunc=CompleteFunction
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal modifiable
  resize 1
  inoremap <silent> <buffer> <cr> <Esc>:call <SID>select_folder_or_feed()<CR> 
  call setline(1, a:prompt)
  let s:prompt = a:prompt
  normal $
  call feedkeys("a\<c-x>\<c-u>\<c-p>", 't')
endfunction

function! CompleteFunction(findstart, base)
  if a:findstart
    let start = len(s:prompt) 
    return start
  else
    let base = s:trimString(a:base)
    if (base == '')
      return s:selectionlist
    else
      let res = []
      for m in s:selectionlist
        if m =~ '\c' . base 
          call add(res, m)
        endif
      endfor
      return res
    endif
  endif
endfun

" selection window pick
function! s:select_selection()
  " let selection = s:trimString(join(split(getline(line('.')), ":")[1:-1], ":"))
  let selection = getline('.')[len(s:prompt):]
  close
  call s:focus_window(s:listbufnr)
  if (selection == '') " no selection
    return
  end
  call s:fetch_items(selection)
endfunction

function! s:fetch_items(selection)
  " take different actions depending on whether a feed or folder?
  call s:focus_window(s:itembufnr)
  call clearmatches()
  call s:focus_window(s:listbufnr)
  call clearmatches()
  if exists("s:selectionlist") && index(s:selectionlist, a:selection) == -1
    return
  end
  if s:selectiontype == "folder"
    let command = s:list_folder_items_command 
  else
    let command = s:list_feed_items_command
  endif
  let command .= winwidth(0) . ' ' .shellescape(a:selection)
  let s:last_fetch_command = command " in case user later updates the feed in place
  let s:last_selection = a:selection
  let res = system(command)
  call s:display_items(res)
  normal G
  call s:focus_window(s:itembufnr)
  close
  normal z-
  " call s:show_item_under_cursor(0)
  " call s:focus_window(s:listbufnr)
endfunction



