import strutils, re

# Code adapted from https://xmonader.github.io/nimdays/day16_asciitables.html
# Adjusted to remove styling, extra padding and header

const COLUMN_WIDTH = 18

type Cell* = object
    leftpad*: int
    rightpad: int
    pad*: int
    text*: string

proc newCell*(text: string, leftpad = 1, rightpad = 1, pad = 0): ref Cell =
    result = new Cell
    result.pad = pad
    if pad != 0:
        result.leftpad = pad
        result.rightpad = pad
    else:
        result.leftpad = leftpad
        result.rightpad = rightpad
    result.text = text

proc len*(this: ref Cell): int =
    let pureString = replace(
        replace(this.text, re"\x1B\[[0-9]*m"),
        re"\xE2\x97\x8F|\xC2|\xB0C",
        "."
        )
    result = this.leftpad +
             pureString.len +
             this.rightpad

proc `$`*(this: ref Cell): string =
    result = " ".repeat(this.leftpad) & this.text & " ".repeat(this.rightpad)

type AsciiTable* = object
    rows: seq[seq[string]]
    widths: seq[int]
    suggestedWidths: seq[int]

proc newAsciiTable*(): ref AsciiTable =
    result = new AsciiTable
    result.widths = newSeq[int]()
    result.suggestedWidths = newSeq[int]()
    result.rows = newSeq[seq[string]]()

proc columnsCount*(this: ref AsciiTable): int =
    result = 0

    for i in 1..<this.rows.len:
        if this.rows[i].len > result:
            result = this.rows[i].len

proc calculateWidths(this: ref AsciiTable) =
    var colsWidths = newSeq[int]()
    for i in 0..<this.columnsCount():
        colsWidths.add(COLUMN_WIDTH)

    this.widths = colsWidths

proc addRow*(this: ref AsciiTable, row: seq[string]) =
    this.rows.add(row)

proc render*(this: ref AsciiTable): string =
    this.calculateWidths()
    for r in this.rows:
        for colidx, c in r:
            let cell = newCell(c, leftpad = 0, rightpad = 2)
            result &= $cell & " ".repeat(max(COLUMN_WIDTH-cell.len, 0))
        if r != this.rows[this.rows.len-1]:
            result &= "\n"

proc printTable*(this: ref AsciiTable) =
    echo this.render()
