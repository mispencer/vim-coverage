# Copyright 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Python-only helpers for vim-coverage."""

import os, os.path
from pycobertura import Cobertura

def GetCoverageCoberturaLines(paths, source_file):
  """Get (covered, uncovered) lines for source_file from coverage.cobertura.xml files at paths.
  """
  prev_cwd = os.getcwd()
  source_file = os.path.abspath(source_file)
  covered_lines = []
  uncovered_lines = []
  for path in paths:
    cov = Cobertura(path)
    files = cov.files();
    #print("Source files: "+source_file);
    match_files = list(filter(lambda item: source_file.endswith(item), files))
    if match_files:
        match_file = min(match_files, key=len)
        #print("Match: "+path+" - "+source_file+" - "+match_file);
        #print("Pre: "+str(len(covered_lines))+"-"+str(len(uncovered_lines)));
        covered_lines = covered_lines + cov.hit_statements(match_file)
        uncovered_lines = uncovered_lines + cov.missed_statements(match_file)
        #print("Post: "+str(len(covered_lines))+"-"+str(len(uncovered_lines)));
    #else:
        #print("No Match: "+path+" - "+source_file);
  #print("PreC: "+str(len(covered_lines))+"-"+str(len(uncovered_lines)));
  covered_lines = list(set(covered_lines))
  uncovered_lines = list(set([item for item in uncovered_lines if item not in covered_lines]))
  #print("PostC: "+str(len(covered_lines))+"-"+str(len(uncovered_lines)));
  return (covered_lines, uncovered_lines)
