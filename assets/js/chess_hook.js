import { Chess } from 'chess.js'
import { Chessground } from 'chessground'

const ChessHook = {
  mounted() {
    // Initialize chess.js for move validation
    this.chess = new Chess()
    this.chess.clear()

    // Create a 3x6 board config for Chessground
    const config = {
      fen: '8/8/8/8/8/8 w - - 0 1', // empty board
      coordinates: false, // hide a-h, 1-8 labels
      viewOnly: false,
      movable: {
        free: false, // require valid moves
        color: 'both',
        dests: new Map(), // legal move destinations
        showDests: true, // show dots on valid destinations
      },
      draggable: {
        enabled: true,
        showGhost: true,
      },
      events: {
        move: this.onMove.bind(this),
      },
      dimensions: {
        width: 6,
        height: 3,
      }
    }

    // Mount Chessground
    this.ground = Chessground(this.el, config)
    
    // Set up initial position from LiveView state
    this.syncBoardFromLiveView()
  },

  updated() {
    // LiveView updated our assigns; sync the board
    this.syncBoardFromLiveView()
  },

  // Map your game_map to Chessground position
  syncBoardFromLiveView() {
    const pieces = {}
    const gameMap = this.el.dataset.gameMap
    if (!gameMap) return

    // Parse the game map and convert to Chessground format
    const map = JSON.parse(gameMap)
    Object.entries(map).forEach(([row, cols]) => {
      Object.entries(cols).forEach(([col, piece]) => {
        if (piece === 0 || piece === 'x') return
        const square = this.toSquare(col, row)
        pieces[square] = this.toPiece(piece)
      })
    })

    // Update Chessground
    this.ground.set({ pieces })
    this.updateLegalMoves()
  },

  // Convert your piece notation to Chessground's
  toPiece(value) {
    switch(value) {
      case 'P': return { role: 'knight', color: 'black' }
      case 'K': return { role: 'knight', color: 'white' }
      case 'B': return { role: 'bishop', color: 'white' }
      case 'R': return { role: 'rook', color: 'white' }
      default: return null
    }
  },

  // Map your H1-C3 notation to Chessground's a1-h8
  toSquare(col, row) {
    const colMap = { H: 'a', G: 'b', F: 'c', E: 'd', D: 'e', C: 'f' }
    return `${colMap[col]}${row}`
  },

  // Map Chessground's a1-h8 back to your H1-C3
  fromSquare(square) {
    const [col, row] = square.split('')
    const colMap = { a: 'H', b: 'G', c: 'F', d: 'E', e: 'D', f: 'C' }
    return { col: colMap[col], row }
  },

  // When Chessground reports a move
  onMove(orig, dest) {
    const from = this.fromSquare(orig)
    const to = this.fromSquare(dest)
    
    // Get the piece type that moved
    const pieces = this.ground.state.pieces
    const piece = pieces.get(orig)
    if (!piece) return

    // Convert to your move format (e.g., "Ph1h3")
    const pieceMap = {
      knight: { black: 'P', white: 'K' },
      bishop: { white: 'B' },
      rook: { white: 'R' }
    }
    const pieceChar = pieceMap[piece.role][piece.color]
    const move = `${pieceChar}${from.col.toLowerCase()}${from.row}${to.col.toLowerCase()}${to.row}`

    // Send to LiveView
    this.pushEvent("select_position", { 
      row: from.row, 
      col: from.col, 
      val: pieceChar 
    })
    this.pushEvent("select_position", { 
      row: to.row, 
      col: to.col, 
      val: '0'  // destination must be empty
    })
  },

  // Update legal moves in Chessground
  updateLegalMoves() {
    const dests = new Map()
    // TODO: Use chess.js to compute legal moves for the selected piece
    this.ground.set({ movable: { dests } })
  }
}

export default ChessHook