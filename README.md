# Tetris, in x86

This is a game of Tetris written in x86. It was originally written as a means of learning more about the x86 instruction set.

There are two versions.

## DOS Version
The DOS version is a 16-bit COM executible. It uses mode 13h for all drawing, writing directly to the mapped address to plot. The index written for each pixel determines the color in a 256-indexed color palette.

Interrupts are used for other functionality like random number generation, and keyboard interaction. For random numbers, it uses the modulus of the current system time. The game keeps going until pieces reach the top of the screen.

The keys i,j,k, and l are used to move the pieces.

This is built using [A86](https://eji.com/a86/).

## Win32 Version
This version is a 32-bit Win32 executable. It uses GDI to draw indexed-color-style shaded regions, and contains the usual things of interactive Win32 programs- creation of a window, a message handler, handling of paint events.

The original resolution of the game is preserved at 320x200; the display is scaled up in this port for suitability on newer displays. The Windows version also includes
* Different colors for the different pieces
* Fixed a bug where rows would sometimes not get cleared correctly
* Added a ‘next piece’ UI
* When you get game over instead of crashing it displays a message and you can press Escape to start again

Some details of the port are discussed in [this post](http://cml-a.com/content/2018/05/14/tetris-in-x68-resurrecting-old-source/).

The keys i, j, k, and l or alternatively the arrow keys are used to move the pieces.

This is built using a Visual Studio 2018 solution which invokes MASM.


![Example image](https://raw.githubusercontent.com/clandrew/tetrisx86/master/Preview/Preview.gif "Example image")

