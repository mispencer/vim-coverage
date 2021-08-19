" Copyright 2017 Google Inc. All rights reserved.
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"     http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.

"{{{ Init

let s:plugin = maktaba#plugin#Get('coverage')

""
" Directories under which to shallowly search for cobertura data files.
"
" Temporary, to be removed in https://github.com/google/vim-coverage/issues/42
if !has_key(s:plugin.globals, '_cobertura_temp_search_paths')
  let s:plugin.globals._cobertura_temp_search_paths = ['.\**']
endif

""
" A list of |glob()| expressions representing cobertura info files.
" Files must be in the format produced by cobertura's geninfo utility.
"
" Temporary, to be removed in https://github.com/google/vim-coverage/issues/42
if !has_key(s:plugin.globals, '_cobertura_temp_file_patterns')
  let s:plugin.globals._cobertura_temp_file_patterns = [
        \ 'coverage.cobertura.xml',
        \ ]
endif

"}}}

"{{{ coverage.py provider

function! s:GetCoverageFile() abort
  let l:paths = join(map(copy(s:plugin.globals._cobertura_temp_search_paths), {k, v -> fnamemodify(v, ":p")}), ';')
  let l:info_files = []
  for l:cobertura_file_pattern in s:plugin.globals._cobertura_temp_file_patterns
    call extend(
          \ l:info_files,
          \ findfile(l:cobertura_file_pattern, fnamemodify(l:paths, ":p"), -1))
  endfor
  return l:info_files
endfunction

let s:imported_python = 0

function! coverage#cobertura#GetCoberturaProvider() abort
  let l:provider = {
      \ 'name': 'cobertura'}

  function l:provider.IsAvailable(unused_filename) abort
    return 1
  endfunction

  function l:provider.GetCoverage(filename) abort
    if !s:imported_python
      try
        call maktaba#python#ImportModule(s:plugin, 'vim_coverage_cobertura')
      catch /ERROR.*/
          throw maktaba#error#NotFound(
              \ "Couldn't import Cobertura coverage module (%s). " .
              \ 'Install the pycobertura package and try again.', v:exception)
      endtry
      let s:imported_python = 1
    endif

    let l:cov_files = s:GetCoverageFile()
    if empty(l:cov_files)
      throw maktaba#error#NotFound(
          \ 'No coverage.cobertura.xml file found. ')
    endif

    let cov_files = l:cov_files
    let l:coverage_data = py3eval(
        \ 'vim_coverage_cobertura.GetCoverageCoberturaLines(vim.eval("cov_files"), vim.eval("a:filename"))',
        \)
    let [l:covered_lines, l:uncovered_lines] = l:coverage_data

    return coverage#CreateReport(l:covered_lines, l:uncovered_lines, [])
  endfunction

  return l:provider
endfunction

"}}}
