# camFlowAq
A MATLAB video acquisition toolbox originally developed for monochrome scientific GenICam cameras.

Now works with webcams!

The camFlowAq.m is a class file that you can add to your MATLAB userpath.

Start by loading a camera in a new project folder by running:

cam = camFlowAq('gentl',1,'Mono8')

Tested with JAI Spark 5000-M USB and Matlab 2019a. 

The cheat sheet summarises the methods available for the class.

The jaiAq.mlx is a live script with further instructions. You can find installation help for using the JAI cameras in MATLAB here.

Currently under development.
