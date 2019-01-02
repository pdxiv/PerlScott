# TI99/4A file format information

Information derived taken from the Bunyon interpreter code (<http://www.ifarchive.org/if-archive/scott-adams/interpreters/bunyon/bunyon-0.3.tar.bz2>).

A lot of important information is still missing, to piece together the whole picture.

## Data header

This contains basic fundamental information about the game data.

| Offset | Datatype | Description |
| ------ | -------- | ----------- |
| 0x8A0 | UINT8 | Number of objects |
| 0x8A1 | UINT8 | Number of verbs |
| 0x8A2 | UINT8 | Number of nouns |
| 0x8A3 | UINT8 | The red room (dead room) |
| 0x8A4 | UINT8 | Max number of items can be carried |
| 0x8A5 | UINT8 | Room to start in |
| 0x8A6 | UINT8 | Number of treasures |
| 0x8A7 | UINT8 | Number of letters in commands |
| 0x8A8 | UINT16 | Max number of turns light lasts |
| 0x8AA | UINT8 | Location of where to store treasures |
| 0x8AB | UINT8 | !?! not known. |
| 0x8AC | UINT16 | Pointer to object table |
| 0x8AE | UINT16 | Pointer to original items |
| 0x8B0 | UINT16 | Pointer to link table from noun to object |
| 0x8B2 | UINT16 | Pointer to object descriptions |
| 0x8B4 | UINT16 | Pointer to message pointers |
| 0x8B6 | UINT16 | Pointer to room exits table |
| 0x8B8 | UINT16 | Pointer to room descr table |
| 0x8BA | UINT16 | Pointer to noun table |
| 0x8BC | UINT16 | Pointer to verb table |
| 0x8BE | UINT16 | Pointer to explicit action table |
| 0x8C0 | UINT16 | Pointer to implicit actions |
| 0x8C2 | UINT16 | Saved room |
| 0x8C4 | UINT16[2] | Nul1 |
| 0x8C8 | UINT16 | Saved timer |
| 0x8CA | UINT16[14] | Nul2 |
| 0x8E6 | UINT16 | Save area |
| 0x8E8 | UINT16[4] | Nul3 |
| 0x8F0 | UINT16 | Dynamic part of file |
