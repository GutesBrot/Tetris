//
//  ContentView.swift
//  Tetris
//
//  Created by ClaraDiederichsen on 11.12.2024.
//

import SwiftUI

struct ContentView: View {
    // Game state variables
    @State private var gameGrid = Array(repeating: Array(repeating: 0, count: 10), count: 20)
    @State private var score = 0
    @State private var currentTetrimino = Tetrimino(type: .I)
    @State private var gameOver = false
    @State private var gameTimer: Timer?

    var body: some View {
        VStack {
            // Score Display
            Text("Score: \(score)")
                .font(.headline)
                .padding()

            // Game Grid
            GridStack(rows: 20, columns: 10) { row, col in
                Rectangle()
                    .foregroundColor(cellColor(row: row, col: col))
                    .border(Color.black, width: 0.5)
            }
            .aspectRatio(10/20, contentMode: .fit)
            .frame(width: 200, height: 400) // Adjusted size
            .padding()

            // Controls
            HStack {
                Button(action: { moveTetrimino("left") }) {
                    Text("←")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                Button(action: rotateTetrimino) {
                    Text("⟳")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                Button(action: { moveTetrimino("right") }) {
                    Text("→")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                Button(action: { moveTetrimino("down") }) {
                    Text("↓")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
            }
            .padding()

            // Restart Game
            if gameOver {
                Button("Restart") {
                    restartGame()
                }
                .padding()
                .background(Color.green)
                .cornerRadius(8)
                .foregroundColor(.white)
            }
        }
        .padding()
        .onAppear {
            startGame()
        }
    }

    // Game logic functions
    func startGame() {
        gameOver = false
        score = 0
        gameGrid = Array(repeating: Array(repeating: 0, count: 10), count: 20)
        spawnNewTetrimino()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            moveTetrimino("down")
        }
    }

    func restartGame() {
        gameTimer?.invalidate()
        startGame()
    }

    func spawnNewTetrimino() {
        currentTetrimino = Tetrimino(type: .random)
        if !isValidMove(tetrimino: currentTetrimino, grid: gameGrid, newRow: currentTetrimino.position.row, newCol: currentTetrimino.position.col) {
            gameOver = true
            gameTimer?.invalidate()
        }
    }

    func moveTetrimino(_ direction: String) {
        var newPosition = currentTetrimino.position

        switch direction {
        case "left":
            newPosition.col -= 1
        case "right":
            newPosition.col += 1
        case "down":
            newPosition.row += 1
        default:
            break
        }

        if isValidMove(tetrimino: currentTetrimino, grid: gameGrid, newRow: newPosition.row, newCol: newPosition.col) {
            currentTetrimino.position = newPosition
        } else if direction == "down" {
            lockTetrimino()
        }
    }

    func rotateTetrimino() {
        var rotatedTetrimino = currentTetrimino
        rotatedTetrimino.rotate()

        if isValidMove(tetrimino: rotatedTetrimino, grid: gameGrid, newRow: rotatedTetrimino.position.row, newCol: rotatedTetrimino.position.col) {
            currentTetrimino = rotatedTetrimino
        }
    }

    func lockTetrimino() {
        for (rowIndex, row) in currentTetrimino.shape.enumerated() {
            for (colIndex, cell) in row.enumerated() where cell != 0 {
                let gridRow = currentTetrimino.position.row + rowIndex
                let gridCol = currentTetrimino.position.col + colIndex

                if gridRow >= 0 && gridRow < gameGrid.count && gridCol >= 0 && gridCol < gameGrid[0].count {
                    gameGrid[gridRow][gridCol] = currentTetrimino.type.rawValue
                }
            }
        }
        clearLines()
        spawnNewTetrimino()
    }

    func clearLines() {
        gameGrid = gameGrid.filter { $0.contains(0) }
        let clearedLines = 20 - gameGrid.count
        if clearedLines > 0 {
            let emptyLines = Array(repeating: Array(repeating: 0, count: 10), count: clearedLines)
            gameGrid = emptyLines + gameGrid
            score += clearedLines * 100
        }
    }

    func isValidMove(tetrimino: Tetrimino, grid: [[Int]], newRow: Int, newCol: Int) -> Bool {
        for (rowIndex, row) in tetrimino.shape.enumerated() {
            for (colIndex, cell) in row.enumerated() where cell != 0 {
                let gridRow = newRow + rowIndex
                let gridCol = newCol + colIndex

                if gridRow < 0 || gridRow >= grid.count || gridCol < 0 || gridCol >= grid[0].count || grid[gridRow][gridCol] != 0 {
                    return false
                }
            }
        }
        return true
    }

    func cellColor(row: Int, col: Int) -> Color {
        for (rowIndex, shapeRow) in currentTetrimino.shape.enumerated() {
            for (colIndex, cell) in shapeRow.enumerated() where cell != 0 {
                let gridRow = currentTetrimino.position.row + rowIndex
                let gridCol = currentTetrimino.position.col + colIndex
                if gridRow == row && gridCol == col {
                    return currentTetrimino.color
                }
            }
        }
        return gameGrid[row][col] == 0 ? .gray.opacity(0.3) : Tetrimino.color(for: gameGrid[row][col])
    }
}

// Supporting GridStack for the game board
struct GridStack<Content: View>: View {
    let rows: Int
    let columns: Int
    let content: (Int, Int) -> Content

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \..self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \..self) { column in
                        content(row, column)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }

    init(rows: Int, columns: Int, @ViewBuilder content: @escaping (Int, Int) -> Content) {
        self.rows = rows
        self.columns = columns
        self.content = content
    }
}

// Tetrimino Struct
struct Tetrimino {
    enum TetriminoType: Int {
        case I = 1, O, T, S, Z, J, L

        static var random: TetriminoType {
            [I, O, T, S, Z, J, L].randomElement()!
        }

        var color: Color {
            switch self {
            case .I: return .cyan
            case .O: return .yellow
            case .T: return .purple
            case .S: return .green
            case .Z: return .red
            case .J: return .blue
            case .L: return .orange
            }
        }
    }

    let type: TetriminoType
    var shape: [[Int]]
    var position: (row: Int, col: Int)
    var color: Color { type.color }

    init(type: TetriminoType) {
        self.type = type
        self.shape = Tetrimino.getShape(for: type)
        self.position = (0, 4) // Start at the top center
    }

    static func getShape(for type: TetriminoType) -> [[Int]] {
        switch type {
        case .I: return [[1, 1, 1, 1]]
        case .O: return [[1, 1], [1, 1]]
        case .T: return [[0, 1, 0], [1, 1, 1]]
        case .S: return [[0, 1, 1], [1, 1, 0]]
        case .Z: return [[1, 1, 0], [0, 1, 1]]
        case .J: return [[1, 0, 0], [1, 1, 1]]
        case .L: return [[0, 0, 1], [1, 1, 1]]
        }
    }

    mutating func rotate() {
        shape = shape[0].indices.map { col in shape.map { $0[col] }.reversed() }
    }

    static func color(for value: Int) -> Color {
        guard let type = TetriminoType(rawValue: value) else { return .gray }
        return type.color
    }
}

#Preview {
    ContentView()
}
