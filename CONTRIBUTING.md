Coding conventions
------------------

* Use tabs to indent, spaces to align.
	* Specifically, spaces should not appear at the beginning of a line, and tabs should not appear _except_ at the beginning of a line.
	* The sole exception is in a multiline `if` statement; the initial `if` should have four spaces before it to align it with an `elseif` on the next line. For example:

```lua
	    if self.level <  900 then return 12
	elseif self.level < 1200 then return 8
	else return 6 end
```

* Comments at the end of lines of code must be one line long. Multi-line comments must appear in their own block.

```lua
	if self.piece:isDropBlocked(self.grid) then
		-- for bottomed out pieces, decrease the drop bonus if they stall on dropping it
		self.drop_bonus = math.min(self.drop_bonus - 1, 0) -- by 1 point per frame
	else                                                            
		if piece_dy >= 1 then                                       -- basically
			self.drop_bonus = self.drop_bonus + piece_dy * 20       -- this sort of
		end                                                         -- multiline comment
		self.drop_bonus = self.drop_bonus + 1                       -- is completely
	end                                                             -- unacceptable
```

* Use `snake_case` for variables, `camelCase` for functions.


Contributor's License Agreement
-------------------------------

By contributing source code or other assets (e.g. music, artwork, graphics) to Cambridge, through a pull request or otherwise, you provide me with a non-exclusive, royalty-free, worldwide, perpetual license to use, copy, modify, distribute, sublicense, publicly perform, and create derivative works of the assets for any purpose.

You also waive all moral rights to your contributions insofar as they are used in the Cambridge repository or in any code or works deriving therefrom.

(Notwithstanding the above clause, I will still make my best effort to provide sufficient attribution to all contributions. At the very least you'll get documentation of your contributions under SOURCES, and probably a special place in the credit roll as well.)
