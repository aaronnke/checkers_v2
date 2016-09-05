# README

A simple checkers game with an AI which uses minimax search.

<b>Details:</b>

* Lookahead is set to 4. This means AI thinks 4 moves ahead.

* Evaluation function is based on board state(pawn count, king count, position, exposure). Weights are far from properly adjusted.

* You can only undo 1 move at a time.

* You must eat when you can.

* It's quite laggy on heroku.
