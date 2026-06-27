const columns = ['H', 'G', 'F', 'E', 'D', 'C']

const columnIndex = (col) => columns.indexOf(col)

const cellValue = (cell) => cell?.dataset.val ?? ''

const isOpenCell = (cell) => cellValue(cell) === '0'

const isBlockedCell = (cell) => cellValue(cell) === 'x'

const isPieceCell = (cell) => cell && !isBlockedCell(cell) && !isOpenCell(cell)

const positionFor = (cell) => ({
  row: Number(cell.dataset.row),
  col: cell.dataset.col,
  val: cellValue(cell)
})

const pathIsClear = (board, from, to, stepCol, stepRow) => {
  let col = columnIndex(from.col) + stepCol
  let row = from.row + stepRow

  while (col !== columnIndex(to.col) || row !== to.row) {
    const between = board.querySelector(
      `td[data-row="${row}"][data-col="${columns[col]}"]`
    )

    if (!between || !isOpenCell(between)) return false

    col += stepCol
    row += stepRow
  }

  return true
}

const isLegalDestination = (board, fromCell, toCell) => {
  if (!fromCell || !toCell || fromCell === toCell || !isOpenCell(toCell)) return false

  const from = positionFor(fromCell)
  const to = positionFor(toCell)
  const deltaCol = columnIndex(to.col) - columnIndex(from.col)
  const deltaRow = to.row - from.row
  const absCol = Math.abs(deltaCol)
  const absRow = Math.abs(deltaRow)

  switch (from.val) {
    case 'P':
    case 'K':
      return (absCol === 2 && absRow === 1) || (absCol === 1 && absRow === 2)
    case 'B':
      return (
        absCol === absRow &&
        pathIsClear(board, from, to, Math.sign(deltaCol), Math.sign(deltaRow))
      )
    case 'R':
      if (absCol !== 0 && absRow !== 0) return false

      return pathIsClear(
        board,
        from,
        to,
        Math.sign(deltaCol),
        Math.sign(deltaRow)
      )
    default:
      return false
  }
}

const ChessHook = {
  mounted() {
    this.selectedCell = null
    this.hoveredCell = null
    this.dragging = false
    this.pointerStart = null

    this.onPointerDown = (event) => {
      const cell = event.target.closest('td[data-row][data-col]')
      if (!cell) return

      if (this.selectedCell && cell !== this.selectedCell) {
        this.tryMoveTo(cell)
        return
      }

      if (!isPieceCell(cell)) {
        this.clearSelection()
        return
      }

      event.preventDefault()
      this.selectCell(cell)
      this.dragging = true
      this.pointerStart = { x: event.clientX, y: event.clientY }
      this.el.setPointerCapture?.(event.pointerId)
    }

    this.onPointerMove = (event) => {
      if (!this.dragging || !this.selectedCell) return

      const cell = this.cellFromPoint(event.clientX, event.clientY)
      this.setHoveredCell(cell)
    }

    this.onPointerUp = (event) => {
      if (!this.dragging) return

      this.dragging = false
      this.el.releasePointerCapture?.(event.pointerId)

      const endCell = this.cellFromPoint(event.clientX, event.clientY)
      const movedEnough = this.pointerMoved(event)
      this.pointerStart = null

      if (movedEnough && endCell) this.tryMoveTo(endCell)

      this.setHoveredCell(null)
    }

    this.onPointerCancel = () => {
      this.dragging = false
      this.pointerStart = null
      this.setHoveredCell(null)
    }

    this.el.addEventListener('pointerdown', this.onPointerDown)
    this.el.addEventListener('pointermove', this.onPointerMove)
    this.el.addEventListener('pointerup', this.onPointerUp)
    this.el.addEventListener('pointercancel', this.onPointerCancel)
  },

  updated() {
    this.clearSelection()
  },

  destroyed() {
    this.el.removeEventListener('pointerdown', this.onPointerDown)
    this.el.removeEventListener('pointermove', this.onPointerMove)
    this.el.removeEventListener('pointerup', this.onPointerUp)
    this.el.removeEventListener('pointercancel', this.onPointerCancel)
  },

  cellFromPoint(x, y) {
    return document.elementFromPoint(x, y)?.closest('td[data-row][data-col]')
  },

  pointerMoved(event) {
    if (!this.pointerStart) return false

    const deltaX = Math.abs(event.clientX - this.pointerStart.x)
    const deltaY = Math.abs(event.clientY - this.pointerStart.y)

    return deltaX > 6 || deltaY > 6
  },

  selectCell(cell) {
    this.clearSelection()
    this.selectedCell = cell
    cell.classList.add('selected')
    this.highlightLegalMoves()
  },

  clearSelection() {
    this.selectedCell?.classList.remove('selected')
    this.selectedCell = null
    this.clearLegalMoves()
    this.setHoveredCell(null)
  },

  highlightLegalMoves() {
    this.clearLegalMoves()

    this.el.querySelectorAll('td[data-row][data-col]').forEach((cell) => {
      if (isLegalDestination(this.el, this.selectedCell, cell)) {
        cell.classList.add('legal-move')
      }
    })
  },

  clearLegalMoves() {
    this.el.querySelectorAll('td.legal-move').forEach((cell) => {
      cell.classList.remove('legal-move')
    })
  },

  setHoveredCell(cell) {
    this.hoveredCell?.classList.remove('drop-hover', 'drop-invalid')
    this.hoveredCell = null

    if (!cell || cell === this.selectedCell) return

    this.hoveredCell = cell
    cell.classList.add(
      isLegalDestination(this.el, this.selectedCell, cell) ? 'drop-hover' : 'drop-invalid'
    )
  },

  tryMoveTo(cell) {
    if (!this.selectedCell) return

    if (!isLegalDestination(this.el, this.selectedCell, cell)) {
      if (isPieceCell(cell)) {
        this.selectCell(cell)
      }

      return
    }

    const from = positionFor(this.selectedCell)
    const to = positionFor(cell)
    this.clearSelection()

    this.pushEvent('move_piece', {
      from_row: String(from.row),
      from_col: from.col,
      val: from.val,
      to_row: String(to.row),
      to_col: to.col
    })
  }
}

export default ChessHook
