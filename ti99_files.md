# Scott Adams TI99/4A format

## Introduction

This is an attempt to document the "FIAD" files available on The Interactive Fiction Archive. (<http://www.ifarchive.org/indexes/if-archiveXscott-adamsXgamesXti99.html>)

Some of the information derived from the Bunyon interpreter code (<http://www.ifarchive.org/if-archive/scott-adams/interpreters/bunyon/bunyon-0.3.tar.bz2>).

The focus of the documentation is to get enough data to enable conversion of the "FIAD" files to a TRS-80 text-based format, or to be able to adapt an existing interpreter to read these files. Any data in the files that is deemed irrelevant for actually playing the game files is ignored by this document.

## Data header

This contains basic fundamental information about the game data. Subtract 0x0380 (896) from the pointer values, to get the actual location of the corresponding field in the file.

| Offset | Datatype | Description |
| ------ | -------- | ----------- |
| 0x08a0 | uint8 | Number of objects |
| 0x08a1 | uint8 | Number of verbs |
| 0x08a2 | uint8 | Number of nouns |
| 0x08a3 | uint8 | The red room (dead room) |
| 0x08a4 | uint8 | Max number of items can be carried |
| 0x08a5 | uint8 | Room to start in |
| 0x08a6 | uint8 | Number of treasures |
| 0x08a7 | uint8 | Number of letters in commands |
| 0x08a8 | uint16 | Max number of turns light lasts |
| 0x08aa | uint8 | Location of where to store treasures |
| 0x08ab | uint8 | Always zero |
| 0x08ac | uint16 | Pointer to object table (always 0x0c62) |
| 0x08ae | uint16 | Pointer to original items |
| 0x08b0 | uint16 | Pointer to link table from noun to object |
| 0x08b2 | uint16 | Pointer to object descriptions |
| 0x08b4 | uint16 | Pointer to message pointers |
| 0x08b6 | uint16 | Pointer to room exits table |
| 0x08b8 | uint16 | Pointer to room descr table |
| 0x08ba | uint16 | Pointer to noun table |
| 0x08bc | uint16 | Pointer to verb table |
| 0x08be | uint16 | Pointer to explicit action table |
| 0x08c0 | uint16 | Pointer to implicit actions |

## Object table

## Original item locations

## Noun to object link table

## Object descriptions

## Message pointers

## Room exit table

## Room description table

## Noun table

## Verb table

## Explicit action table

## Implicit action table
