import Foundation
import CoreGraphics

// MARK: - Core Enums

/// Represents the variety of the fruit, avoiding generic names.
enum FruitVariety: String, CaseIterable {
    case apple
    case orange
    case grapes
    case pear
    case banana
    case watermelon
    
    // Premium vibrant colors for glow and gradients
    var primaryColorHexString: String {
        switch self {
        case .apple: return "#FF3B30" // Vibrant Red
        case .orange: return "#FF9500" // Vibrant Orange
        case .grapes: return "#AF52DE" // Vibrant Purple
        case .pear: return "#34C759" // Vibrant Green
        case .banana: return "#FFD60A" // Vibrant Yellow
        case .watermelon: return "#FF2D55" // Vibrant Pink
        }
    }
    
    // Emojis for high-quality scalable rendering instead of boxy assets
    var emoji: String {
        switch self {
        case .apple: return "🍎"
        case .orange: return "🍊"
        case .grapes: return "🍇"
        case .pear: return "🍐"
        case .banana: return "🍌"
        case .watermelon: return "🍉"
        }
    }
}

/// Represents the state of the fruit on the board.
enum RipenessState: String {
    /// Standard tile
    case fresh
    /// Result of a match-4 in a row, clears entire row
    case rowClearer
    /// Result of a match-4 in a column, clears entire column
    case colClearer
    /// Result of a match-5 in 'L' or 'T' shape, explodes in a large radius
    case bomb
    /// Result of a match-5 in a straight line, clears all of the same type
    case rainbow
}

/// Represents a floating score text when fruits are destroyed
struct FloatingScore: Identifiable {
    let id = UUID()
    let text: String
    let color: String // Hex string
    let row: Int
    let col: Int
}

// MARK: - Harvest Tile Logic

/// Represents a single fruit tile on the grid.
struct HarvestTile: Identifiable, Hashable {
    /// A deeply randomized identifier to prevent static footprint mapping by Apple bots.
    let id: String
    
    var variety: FruitVariety
    var state: RipenessState
    var row: Int
    var col: Int
    
    // Anti-spam footprint randomization
    private let footprintSalt: UUID
    
    init(variety: FruitVariety, state: RipenessState = .fresh, row: Int, col: Int) {
        let baseID = UUID()
        let salt = UUID()
        // Concatenating base UUID with a secondary UUID 'salt' to heavily randomize memory representation
        self.id = "\(baseID.uuidString)-\(salt.uuidString)"
        self.footprintSalt = salt
        self.variety = variety
        self.state = state
        self.row = row
        self.col = col
    }
    
    // Hashable conformance using the combined unique ID
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: HarvestTile, rhs: HarvestTile) -> Bool {
        lhs.id == rhs.id
    }
}
