# PerlScott

## Introduction

Fully functioning (hopefully) Scott Adams adventure game interpreter, written in Perl.

## Development background of the interpreter

This was painstakingly converted to Perl from the version 4.6 TRS-80 Level II Basic source code, which was published in the December 1980 issue of Byte Magazine (page 192). Perl was chosen as the language to use, because it had the most variation in possible syntax, allowing you to write both "basic style" code initially and more structured code as the code was gradually refactored.

## Changes from the original

The 4.6 version in Byte Magazine doesn't support many of the features in latest versions of the interpreter (8.5?). To play games newer than "Adventureland" and "Pirate Adventure", some changes and additions needed to be made.

Changes:

- Game data file loading changed to accomodate the newer "standard" format files
- Replace \` with " for quotes
- Removed references to Adventure Land #4.6, since the Perl interpreter is different enough to make it meaningless

Additions:

- Numerical counters, and required conditions and commands for using them
- Alternate room registers, and required commands for using them
- Commands for printing the entered noun, and for printing a newline
- Command for "waiting" for one second (for dramatical effect, presumably)
- Conditions for determining if an object is in its' starting location or not
- Hard-coded full direction noun text for games (such as #4 Voodoo Castle) that don't have full text filled in

## Dependencies

To run, PerlScott requires Perl 5, and the following Perl modules to be installed:

- Readonly (in Ubuntu, `sudo apt install libreadonly-perl`)
- Carp
- English
- Getopt::Long

Please note that some, or all of these may already be installed in your system.
