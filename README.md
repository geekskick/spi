# SPI Master
To simulate this using ghdl use the build script in /scripts. It will build all modules and then run any simulations and put a gtkwave file in the directory it was run from. There is a constraint whereby the test bench files must be called `*_tb.vhd` and the entities in there must be called `*_tb` for the entity to work

## Issues
1. Currently in burst mode there is an extra clock tick between the two transactions.

## Todo
1. Adjustable CPHA
2. Adjustable CPOL
