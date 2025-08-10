import { Chess } from 'chess.js'

// Non-invasive validation hook: only blocks the second click if chess.js deems the move illegal.
// Otherwise it lets the existing LiveView click flow run unchanged.
const ChessHook = {
  mounted() {
    this.start = null
    this.boardTable = this.el.querySelector('table')
    // Optional visual cue that hook is active
    // this.el.style.outline = '2px solid #f39c12'

    // Click-to-move validator (non-invasive)
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

    // Disable native image drag to avoid macOS “save image” behavior
    this.onNativeDragStartBlock = (evt) => { evt.preventDefault() }

    // Drag-and-drop support (pointer-driven, not HTML5 DnD)
    this.drag = null
    this.hoverTd = null
    this.onPointerDown = (evt) => {
      evt.preventDefault()
      const td = evt.target.closest('td')
      if (!td) return
      const val = td.getAttribute('phx-value-val')
      if (!val || val === '0' || val === 'x') return
      const row = td.getAttribute('phx-value-row')
      const col = td.getAttribute('phx-value-col')
      const img = td.querySelector('img')
      if (!row || !col || !img) return
      // start drag
      const rect = img.getBoundingClientRect()
      const ghost = img.cloneNode(true)
      // Ensure the ghost image keeps the same on-screen size as the original
      ghost.style.position = 'fixed'
      ghost.style.width = `${rect.width}px`
      ghost.style.height = `${rect.height}px`
      ghost.style.maxWidth = 'none'
      ghost.style.maxHeight = 'none'
      ghost.style.left = `${evt.clientX - (rect.width / 2)}px`
      ghost.style.top = `${evt.clientY - (rect.height / 2)}px`
      ghost.style.pointerEvents = 'none'
      ghost.style.opacity = '0.95'
      ghost.style.zIndex = '9999'
      ghost.style.objectFit = 'contain'
      ghost.style.border = 'none'
      document.body.appendChild(ghost)
      this.drag = {
        start: { row, col, val },
        ghost,
        offsetX: rect.width / 2,
        offsetY: rect.height / 2
      }
      // block native drag on the image
      img.addEventListener('dragstart', this.onNativeDragStartBlock, { once: true })
      window.addEventListener('pointermove', this.onPointerMove)
      window.addEventListener('pointerup', this.onPointerUp, { once: true })
      window.addEventListener('pointercancel', this.onPointerCancel, { once: true })
    }

    this.onPointerMove = (evt) => {
      if (!this.drag) return
      const { ghost, offsetX, offsetY } = this.drag
      ghost.style.left = `${evt.clientX - offsetX}px`
      ghost.style.top = `${evt.clientY - offsetY}px`

      // highlight hovered cell
      const td = document.elementFromPoint(evt.clientX, evt.clientY)?.closest('td')
      if (td !== this.hoverTd) {
        if (this.hoverTd) this.hoverTd.classList.remove('drop-hover')
        if (td) td.classList.add('drop-hover')
        this.hoverTd = td || null
      }
    }

    this.onPointerUp = (evt) => {
      if (!this.drag) return
      const { start, ghost } = this.drag
      const td = document.elementFromPoint(evt.clientX, evt.clientY)?.closest('td')
      if (!td) {
        ghost.remove()
        if (this.hoverTd) this.hoverTd.classList.remove('drop-hover')
        this.hoverTd = null
        this.drag = null
        return
      }
      const row = td.getAttribute('phx-value-row')
      const col = td.getAttribute('phx-value-col')
      const val = td.getAttribute('phx-value-val')
      const finish = { row, col, val }
      const isValid = this.validateWithChess(start, finish)
      if (!isValid) {
        td.animate([{ backgroundColor: '#ffdddd' }, { backgroundColor: '' }], { duration: 300 })
      }
      // Always simulate the existing two-click flow so the server can display
      // the same "Illegal move" feedback on invalid drops
      this.pushEvent('select_position', { row: start.row, col: start.col, val: start.val })
      this.pushEvent('select_position', { row, col, val })
      ghost.remove()
      if (this.hoverTd) this.hoverTd.classList.remove('drop-hover')
      this.hoverTd = null
      this.drag = null
    }

    this.onPointerCancel = () => {
      if (!this.drag) return
      this.drag.ghost.remove()
      if (this.hoverTd) this.hoverTd.classList.remove('drop-hover')
      this.hoverTd = null
      this.drag = null
    }

    this.el.addEventListener('click', this.onClick, true)
    this.attachListeners()
    this.refreshDraggablePieces()
  },

  destroyed() {
    if (this.onClick) this.el.removeEventListener('click', this.onClick, true)
    this.detachListeners()
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
  ,
  updated() {
    // LiveView re-render may replace DOM; re-bind listeners and re-enable draggables
    this.detachListeners()
    this.boardTable = this.el.querySelector('table')
    this.attachListeners()
    this.refreshDraggablePieces()
  },

  refreshDraggablePieces() {
    const tds = this.boardTable?.querySelectorAll('tbody td') || []
    tds.forEach((td) => {
      const val = td.getAttribute('phx-value-val')
      const img = td.querySelector('img')
      if (!img) return
      const isPiece = val && val !== '0' && val !== 'x'
      // Make both the img and the td draggable to avoid browser “download image” default
      if (isPiece) {
        // disable native dnd; we use pointer-driven drag
        img.setAttribute('draggable', 'false')
        td.setAttribute('draggable', 'false')
        img.style.cursor = 'grab'
      } else {
        img.setAttribute('draggable', 'false')
        td.setAttribute('draggable', 'false')
        img.style.cursor = 'default'
      }
    })
  }
  ,
  attachListeners() {
    if (!this.boardTable) return
    // Pointer-driven drag only
    this.boardTable.addEventListener('pointerdown', this.onPointerDown, true)
  },
  detachListeners() {
    if (!this.boardTable) return
    this.boardTable.removeEventListener('pointerdown', this.onPointerDown, true)
  }
}

export default ChessHook

