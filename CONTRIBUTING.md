Contributor's License Agreement
-------------------------------

By contributing source code or other assets (e.g. music, artwork, graphics) to Cambridge, through a pull request or otherwise, you provide me with a non-exclusive, royalty-free, worldwide, perpetual license to use, copy, modify, distribute, sublicense, publicly perform, and create derivative works of the assets for any purpose.

You also waive all moral rights to your contributions insofar as they are used in the Cambridge repository or in any code or works deriving therefrom.

(Notwithstanding the above clause, I will still make my best effort to provide sufficient attribution to all contributions. At the very least you'll get documentation of your contributions under SOURCES, and probably a special place in the credit roll as well.)


Git / Repo conventions
----------------------

In general, use `kebab-case` for branch names. Also, make sure they're concise and descriptive - like 2 or 3 words is usually good.

```
* badbeef (badBranchName) This branch name is bad.
| * defaced (another_bad_branch_name) This branch name is also bad because it uses snake case.
|/
| * deadcab (generic) This branch name isn't very descriptive.
|/
| * bac0040 (this-long-winded-branch-name-that-could-be-its-own-commit-message) Self-explanatory.
|/
| * 600db01 (good-branch-name) This branch name is good.
|/
* 0000420 (HEAD -> master, tag: v0.6.9) This is a sexy root commit.
```

The top line of a commit message should generally be one full sentence long, without too many subordinate clauses. Don't sweat 50/72, but try not go over about 100 characters either.
* If the message starts with a verb, it should be written in the past tense, as a description of what the commit _did_ to the commit tree. (e.g. _Made_ a change, _Fixed_ a bug, _Added_ a feature)
* Alternatively, include a description (in the present tense) of what is now true thanks to this commit. (e.g. "The Puyo Puyo mode can now support up to 50 players.")

```
* 800000d (message-too-long) Made multiplayer stuff play well with the new v0.2.5 server by fixing a problem the client was having with sending multiple 4-KB packets within 2 milliseconds of each other.
| * defaced (not-descriptive-enough) Fixed stuff.
|/
| * bad0003 (present-tense) Lengthens the retry period of the server connection to 15 seconds.
|/
| * bad0004 (imperative-mood) Force the credit roll to end after 67 seconds if no input is detected.
|/
| * 600d001 (good-commit-summary) Made the Jenny Marathon mode not top out randomly at level 600.
| * 600d002 (also-good) Backgrounds don't suck anymore.
|/
* 1234567 (HEAD -> master, tag: v0.4.2) Updated docs in preparation for a new release.
```

When making pull requests, always include:

* A title that works well as a commit title, since that's what's going to appear when it's merged.
* A full description of the problem that the pull request solves or the feature that it implements.
	* If the whole purpose of the pull request is to resolve a particular issue and nothing else, "Fixes #[issue number]" counts as a full description. Otherwise if there's anything else in the pull request, make a short note of "also [did this other thing]".


Coding conventions
------------------

Use tabs to indent, spaces to align.

* Specifically, spaces should not appear at the beginning of a line, and tabs should not appear _except_ at the beginning of a line.
* If you're aligning multiline if-statements, the initial "if", "elseif" or "else" should be flush left with the indentation level, with spaces padding the gap to the next word as necessary. For example:

```lua
	if     self.level <  900 then return 12
	elseif self.level < 1200 then return  8
	else                          return  6
	end
```

Comments at the end of lines of code must be one line long. Multi-line comments must appear in their own block.

```lua
	if not self.piece:isDropBlocked(self.grid) then
		-- this is a comment that appears in a block of its own, separate from any code
		-- consecutive multiline comments must have the same indentation level and
		-- not appear next on the same line as actual code
		self.drop_bonus = 0 -- comments at the end of a line must stay on that line
	else                                                            
		if piece_dy >= 1 then                                       -- basically
			self.drop_bonus = self.drop_bonus + piece_dy * 20       -- this sort of
		end                                                         -- multiline comment
		self.drop_bonus = self.drop_bonus + 1                       -- is completely
	end                                                             -- unacceptable
```

Use `snake_case` for variables, `camelCase` for functions.

```lua
	function MyGameMode:on_activate_bleep_bloop()
		-- no, bad, use "onActivateBleepBloop"
		
		local bleepBloopFrames = 240
		-- this is also bad, use "bleep_bloop_frames"
		
		local bleep_bloop_bonus = self.lock_delay * 150
		self.bleepBloopSubscore = self.bleepBloopSubscore + bleep_bloop_bonus
		-- this should be self."bleep_bloop_subscore", member variables are also variables
	end
```
