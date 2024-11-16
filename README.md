FPGA transciever  
Author: Wojciech Miskowicz  
Date: 16 Nov 2024

This project aims for showing advanced testing methods. 
Module simple_rx recieves data of interface GMII, validates and sends to output of interface AXI-Stream.


Testbench consist of DUT, driver, monitor, scoreboard and some additional classes and interfaces.
Data is sent by driver, recieved in monitor and compared in scoreboard, which prints summary at the end of simulation.  
This allows efficient testing without reading waveforms.
