import { Chess } from 'chess.js'

// Non-invasive validation hook: only blocks the second click if chess.js deems the move illegal.
// Otherwise it lets the existing LiveView click flow run unchanged.
const ChessHook = {
  mounted() {
    this.start = null
    this.boardTable = this.el.querySelector('table')
    // Optional visual cue that hook is active
    // this.el.style.outline = '2px solid #f39c12'

    this.onClick = (evt) => {
      const td = evt.target.closest('td')
      if (!td) return
      // Phoenix sets these as attributes; reuse them instead of adding new data-*
      const row = td.getAttribute('phx-value-row')
      const col = td.getAttribute('phx-value-col')
      const val = td.getAttribute('phx-value-val')
      if (!row || !col) return

      if (!this.start) {
        // First click: remember and allow LiveView to process as usual
        this.start = { row, col, val }
        return
      }

      // Second click: validate with chess.js before allowing server to handle it
      const finish = { row, col, val }
      const isValid = this.validateWithChess(this.start, finish)
      if (!isValid) {
        // Block the invalid second click so server does not process it
        evt.preventDefault()
        evt.stopPropagation()
        // Brief highlight to signal invalid
        td.animate([{ backgroundColor: '#ffdddd' }, { backgroundColor: '' }], { duration: 300 })
      }
      this.start = null
    }

    this.el.addEventListener('click', this.onClick, true)
  },

  destroyed() {
    if (this.onClick) this.el.removeEventListener('click', this.onClick, true)
  },

  validateWithChess(start, finish) {
    // Destination must be empty and not blocked (your server enforces this too)
    if (!finish || finish.val === 'x' || finish.val !== '0') return false

    // Build a chess.js board reflecting the current grid
    const chess = new Chess()
    chess.clear()

    const tds = this.boardTable.querySelectorAll('tbody td')
    tds.forEach((cell) => {
      const c = cell.getAttribute('phx-value-col')
      const r = cell.getAttribute('phx-value-row')
      const v = cell.getAttribute('phx-value-val')
      if (!c || !r || !v) return

      const square = this.toSquare(c, r)
      switch (v) {
        case 'P': // player black knight
          chess.put({ type: 'n', color: 'b' }, square)
          break
        case 'K': // white knight
          chess.put({ type: 'n', color: 'w' }, square)
          break
        case 'B': // white bishop
          chess.put({ type: 'b', color: 'w' }, square)
          break
        case 'R': // white rook
          chess.put({ type: 'r', color: 'w' }, square)
          break
        case 'x': // blocked cell: add an unmovable blocker (friendly to both movers)
          // Use a black pawn as a rigid blocker; knights can jump, others cannot pass/land
          chess.put({ type: 'p', color: 'b' }, square)
          break
        default:
          // '0' empty
          break
      }
    })

    const from = this.toSquare(start.col, start.row)
    const to = this.toSquare(finish.col, finish.row)

    // chess.js will reject sliding through pieces, which fixes the rook bug
    const legal = chess.moves({ square: from, verbose: true }).some((m) => m.to === to)
    return legal
  },

  toSquare(col, row) {
    return `${String(col).toLowerCase()}${row}`
  }
}

export default ChessHook

