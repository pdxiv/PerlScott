# PerlScott

## Introduction

Fully functioning (hopefully) Scott Adams adventure game interpreter, written in Perl.

## Development background of the interpreter

This was painstakingly converted to Perl from the version 4.6 TRS-80 Level II Basic source code, which was published in the December 1980 issue of Byte Magazine (page 192). Perl was chosen as the language to use, because it had the most variation in possible syntax, allowing you to write both "basic style" code initially and more structured code as the code was gradually refactored.

## Changes from the original

The 4.6 version in Byte Magazine doesn't support many of the features in latest versions of the engine (8.3?). To play games newer than "Adventureland" and "Pirate Adventure", some changes and additions needed to be made.

Changes:

- Game data file loading changed to accomodate the newer "standard" format files

Additions:

- Numerical counters, and required conditions and commands for using them
- Alternate room registers, and required commands for using them
- Commands for printing the entered noun, and for printing a newline
- Command for "waiting" for one second (for dramatical effect, presumably)
- Conditions for determining if an object is in its' starting location or not
