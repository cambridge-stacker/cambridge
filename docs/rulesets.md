Rulesets
========

A **ruleset** is a set of rules that apply to any game mode.

A ruleset consists of the following things:

 * A *rotation system*, which defines how pieces move and rotate.
 * A *lock delay reset system*, which defines how pieces lock when they can no longer move or rotate.

If you're used to Nullpomino, you may notice a few things missing from that definition. For example, piece previews, hold queues, and randomizers have been moved to being game-specific rules, rather than rules that are changeable with the ruleset you use. Soft and hard drop behaviour is also game-specific now, so that times can be more plausibly compared across rulesets.


Rotation system
---------------
A rotation system defines the following things:
 * The block offsets of each piece orientation.
 * The wall or floor kicks that will be attempted for each type of rotation.

There are three main classes/families of rotation systems:

* **ARIKA**, commonly known as ARS.
  * **ARIKA-CLASSIC**, commonly known as Classic ARS.
  * **ARIKA-TI**, commonly known as Ti-ARS, or "ARS with floorkicks".
* **STANDARD**, commonly known as SRS.
  * **STANDARD**, or normal SRS.
  * **STANDARD-EXP**, known as SRS-X in its original Heboris incarnation.
  * **STANDARD-WORLD**, known as World Rule in TGM3.
* **CLASSIC**, commonly known as ORS or NRS (Nintendo). Also houses some traditional rotation systems.
  * **CLASSIC-1989**, the no-wallkick system used by NES Tetris.
  * **CLASSIC-1984**, the Electonika-60 system, where the I piece is one space higher than in CLASSIC-1989.
  * **CLASSIC-SEGA**, the original Sega rotation system that spawned Arika.
  * **CLASSIC-TENGEN**, the weird one with orientation problems.
