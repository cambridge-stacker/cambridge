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

There are four rotation systems currently supported:

* Cambridge
* Classic ARS
* Ti-ARS
* SRS