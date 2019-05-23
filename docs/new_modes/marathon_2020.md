Marathon 2020
=============

To celebrate the coming of the year 2020, I've created a new "extended Tetris the Grand Master" mode where the level counter goes up twice as far as normal, all the way up to 2020.


Gameplay
--------

The goal of this game is to reach the end at level 2020.

Every piece placed increases the level by 1, and every line cleared also increases the level by 1, with bonuses for large numbers of lines:

| Lines cleared | Levels advanced |
|---------------|-----------------|
| 1 | 1 |
| 2 | 2 |
| 3 | 4 |
| 4 | 6 |

When the current level reaches one less than the level at the bottom of the display (usually a multiple of 100), the level will not advance until a line is cleared.


Levels
------

Each section is 100 levels long, except for the last section, whose levels go from 1900 all the way to 2020.

However, it is possible to be stopped early on if you do not play fast enough.


### Torikans

There are certain checkpoints at which your current time will be checked and you will be stopped if your time is over a set objective time.

| Level | Time limit |
|-------|------------|
|   500 |   6:00.00  |
|   900 |   8:30.00  |
|  1000 |   8:45.00  |
|  1500 |  11:30.00  |
|  1900 |  13:15.00  |

At levels 500, 1000, and 1500, you will be stopped immediately if your time is not under the objective.

At levels 900 and 1900, the next section will be capped at 999 or 1999 respectively, and you will get a short credit roll when the section is over.


Speed
-----

Marathon 2020 gets faster in two different, independent ways, the gravity curve and the delay curve.

The gravity curve is always the same at a particular level, while the delay curve can vary based on your previous section time.

### Gravity Curve

The gravity curve is the same as it is in the original TGM and TAP.

### Delay Curve

The delay curve is shown as in the following table. Line ARE is always equal to ARE.

If your time in a particular section from 0 to 70 is smaller than the "cool" requirement at that level, your delay curve will be bumped up an extra level at the end of the section.

The delay curve always advances at least 1 level past level 500, and if you get a section cool when the level is past 500, it will advance 2 levels instead.

| Level | ARE  | Lock | DAS  | Line | Cool |
|-------|------|------|------|------|------|
|0|27|30|15|40|45.00|
|100|24|30|12|25|41.50|
|200|21|30|12|25|38.50|
|300|18|30|9|20|35.00|
|400|16|30|9|15|32.50|
|500|14|30|8|12|29.20|
|600|12|26|8|12|27.20|
|700|10|22|8|8|24.80|
|800|8|19|7|8|22.80|
|900|6|17|7|6|20.60|
|1000|6|15|6|6|19.60|
|1100|6|15|6|4|19.40|
|1200|6|15|6|4|19.40|
|1300|5|15|5|4|18.40|
|1400|5|15|5|2|18.20|
|1500|4|15|4|2|16.20|
|1600|4|13|4|2|16.20|
|1700|4|11|4|2|16.20|
|1800|4|10|4|2|16.20|
|1900|4|9|4|2|16.20|
|2000|4|8|3|2|15.20|

In order to get a section cool, your 0-70 section time must be below the cutoff *and* no more than 2 seconds slower than your previous 0-70 time.


Grading
-------




### Basic grades

Internally, the grade counter is a number that can range from 0 to 30.

At the beginning of the game, it starts at 0. To increase it, you must bring an internal grade point counter past a certain threshold.

The threshold is set at 50 points for the first grade, then 100 more points for the next grade, then 150 points for the grade after that, and so on. You reach the maximum level of 30 at a total of 23,250 points.

A table of the thresholds in grade points required to reach each level is provided below:

Grade|Threshold
-|-
0|0
1|50
2|150
3|300
4|500
5|750
6|1050
7|1400
8|1800
9|2250
10|2750
11|3300
12|3900
13|4550
14|5250
15|6000
16|6800
17|7650
18|8550
19|9500
20|10500
21|11550
22|12650
23|13800
24|15000
25|16250
26|17550
27|18900
28|20300
29|21750
**30**|**23250**

Points are given according to a different scale, the point level. The point level is calculated by taking your current actual level, and adding (100 * the delay level) to it.

The points given for clearing certain amounts of lines is given as follows:

Level| x1 | x2 | x3 | x4
-|-|-|-|-
0|10|20|30|40
100|10|20|30|40
200|10|20|30|48
300|10|20|30|60
400|10|20|36|72
500|10|21|42|84
600|10|24|48|96
700|10|27|54|108
800|10|30|60|120
900|11|33|66|140
1000|12|36|72|160
1100|13|39|81|180
1200|14|42|90|200
1300|15|45|99|220
1400|16|48|108|240
1500|17|52|117|260
1600|18|56|126|280
1700|19|60|135|300
1800|20|64|144|320
1900|21|68|153|340
2000|22|72|162|360
2100|23|76|171|380
2200|24|80|180|400
2300|25|84|189|420
2400|26|88|198|440
2500|27|92|207|460
2600|28|96|216|480
2700|29|100|225|500
2800|30|104|234|520
2900|31|108|243|540
3000|32|112|252|560
3100|33|116|261|580
3200|34|120|270|600
3300|35|124|279|620
3400|36|128|288|640
3500|37|132|297|660
3600|38|136|306|680
3700|39|140|315|700
3800|40|144|324|720
3900|41|148|333|740

Past level 1000, a 4-line clear will always give (30 * current grade), regardless of point level.

The remaining 20 grades come from section cools. Every section cool you get boosts your score by one grade. There are no regrets.

Points are also taken away with the time it takes to lock down a piece. The delay counter starts at 0, and increases by (current grade + 2) every frame. When the counter reaches or exceeds 240, it resets to 0, and 1 grade point is taken away.

Grades are based on the maximum grade points achieved. Once a grade has been attained, it cannot be lost even if grade points drop below the threshold for that grade.



Stats
-----

* Fewest number of lines/pieces to reach 2020: 1263 pieces / 505 lines [all Tetrises]

* Most number of lines/pieces to reach 2020: 1448 pieces / 572 lines [all singles / doubles, full board]
