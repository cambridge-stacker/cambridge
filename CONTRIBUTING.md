Coding conventions
------------------

* Use tabs to indent, spaces to align.
	* Specifically, spaces should not appear at the beginning of a line, and tabs should not appear _except_ at the beginning of a line.
	* The sole exception is in a multiline `if` statement; the initial `if` should have four spaces before it to align it with an `elseif` on the next line. For example:

```lua
	---- 4 spaces
	    if self.level <  900 then return 12
	elseif self.level < 1200 then return 8
	else return 6 end
```

* Comments at the end of lines of code must be one line long. Multi-line comments must appear in their own block.

```lua
	if self.piece:isDropBlocked(self.grid) then
		-- this is a comment that appears in a block of its own, separate from any code
		-- consecutive multiline comments must have the same indentation level and
		-- not appear next on the same line as actual code
		self.drop_bonus = math.min(self.drop_bonus - 1, 0) -- comments at the end of a line must stay on that line
	else                                                            
		if piece_dy >= 1 then                                       -- basically
			self.drop_bonus = self.drop_bonus + piece_dy * 20       -- this sort of
		end                                                         -- multiline comment
		self.drop_bonus = self.drop_bonus + 1                       -- is completely
	end                                                             -- unacceptable
```

* Use `snake_case` for variables, `camelCase` for functions.

```lua
	function MyGameMode:on_activate_bleep_bloop()
		-- no, bad, use "onActivateBleepBloop"
		local bleepBloopFrames = 240
		-- this is also bad, use "bleep_bloop_frames"
		local bleep_bloop_bonus = self.lock_delay * 150
		self.bleepBloopSubscore = self.bleepBloopSubscore + bleep_bloop_bonus
		-- member variables are also variables, this should be "bleep_bloop_subscore"
	end
```


Contributor's License Agreement
-------------------------------

By contributing source code or other assets (e.g. music, artwork, graphics) to Cambridge, through a pull request or otherwise, you provide me with a non-exclusive, royalty-free, worldwide, perpetual license to use, copy, modify, distribute, sublicense, publicly perform, and create derivative works of the assets for any purpose.

You also waive all moral rights to your contributions insofar as they are used in the Cambridge repository or in any code or works deriving therefrom.

(Notwithstanding the above clause, I will still make my best effort to provide sufficient attribution to all contributions. At the very least you'll get documentation of your contributions under SOURCES, and probably a special place in the credit roll as well.)
