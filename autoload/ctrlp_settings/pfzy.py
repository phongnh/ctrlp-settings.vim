import os
import sys
import traceback
import vim
import asyncio
from pfzy import fuzzy_match

def pfzy_match():
    needle = vim.eval("s:pfzy_needle")
    haystacks = vim.eval("s:pfzy_haystacks")
    return asyncio.run(fuzzy_match(needle, haystacks))
