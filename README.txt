To simulate this using ghdl use the build script in /scripts. It will build all modules and then run any simulations and put a gtkwave file in the directory it was run from. There is a constraint whereby the test bench files must be called *_tb.vhd and the entities in there must be called *_tb for the script to work

Issues:
    1. On asserting send it takes two clock ticks to actually start clocking the data out. I want this to be one - I think it's to do with the clocking and state changing being in their own processes. I need to have a proper think about it and separate out the combinatorial logic to make things easier
