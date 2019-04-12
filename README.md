# Tetris, in x86

This is a game of Tetris written in x86 assembly. It was originally written as a means of learning more about the x86 instruction set.

There are two versions.

## DOS Version
The DOS version is a 16-bit COM executible. It uses mode 13h for all drawing, writing directly to address 0xA000 to plot. The index written for each pixel determines the color in a 256-indexed color palette.

Interrupts are used for other functionality like random number generation, and keyboard interaction. For random numbers, it uses the modulus of the current system time. The game keeps going until pieces reach the top of the screen.

The keys i,j,k, and l are used to move the pieces.

This is built using the A86 assembler.

## Win32 Version
This version is a 32-bit Win32 executible. It uses GDI to draw indexed-color-style shaded regions, and contains the usual things of interactive Win32 programs- creation of a window, a message handler, handling of paint events.

The original resolution of the game is preserved at 320x200; the display is scaled up in this port for suitability on newer displays. The Windows version also includes
* Different colors for the different pieces
* Fixed a bug where rows would sometimes not get cleared correctly
* Added a ‘next piece’ UI
* When you get game over instead of crashing it displays a message and you can press Escape to start again

The keys i, j, k, and l or alternatively the arrow keys are used to move the pieces.

This is built using a Visual Studio 2018 solution which invokes MASM.
