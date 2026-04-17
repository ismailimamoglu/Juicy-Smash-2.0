import SwiftUI

struct LevelMapView: View {
    let onStartLevel: (Int) -> Void
    let onBackToMenu: () -> Void
    let onOpenShop: () -> Void
    @Binding var showSettings: Bool
    var onColorChange: ([Color]) -> Void
    
    @ObservedObject private var progression = ProgressionManager.shared
    @State private var selectedLevel: Int? = nil
    @State private var currentPage: Int = 0
    
    // Page groups with exact requested ranges and thematic colors
    struct WorldData { let name: String; let levels: [Int]; let colors: [Color]; let columns: Int }
    private let worlds: [WorldData] = [
        // Village — warm golden hour: soft wheat → blush rose
        WorldData(name: "VILLAGE", levels: Array(1...5),   colors: [Color(hex: "#F7D794"), Color(hex: "#F0A8A8")], columns: 3),
        // Forest — mossy morning: muted sage → soft teal
        WorldData(name: "FOREST", levels: Array(6...15),  colors: [Color(hex: "#A8CC8C"), Color(hex: "#78C5A8")], columns: 4),
        // City — urban dusk: dusty periwinkle → warm slate
        WorldData(name: "CITY",   levels: Array(16...50), colors: [Color(hex: "#A8B4D4"), Color(hex: "#C4A8C8")], columns: 6),
        // Space — deep cosmos: midnight navy → deep indigo (intentionally dark)
        WorldData(name: "SPACE",  levels: Array(51...99), colors: [Color(hex: "#1A1A3E"), Color(hex: "#2D2B6E")], columns: 6)
    ]
    
    var body: some View {
        ZStack {
            // MARK: - Sulu Map Depth
            ZStack {
                // Subtle tint gradient (Transparent to reveal background)
                LinearGradient(
                    colors: [worlds[currentPage].colors.first?.opacity(0.3) ?? .clear, .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                
                // Watercolor blobs for texture
                GeometryReader { geo in
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(worlds[currentPage].colors.first?.opacity(0.1) ?? .clear)
                            .frame(width: geo.size.width * 0.7).blur(radius: 60)
                            .offset(x: i % 2 == 0 ? -40 : 100, y: i == 0 ? -100 : 250)
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onBackToMenu) {
                        Image(systemName: "house.fill").padding(10).background(.ultraThinMaterial).clipShape(Circle()).foregroundColor(.white)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("WORLD MAP").font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                        Text(worlds[currentPage].name).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white.opacity(0.7))
                        
                        Button(action: onOpenShop) {
                            HStack(spacing: 6) {
                                Image(systemName: "circle.circle.fill").foregroundColor(.yellow)
                                Text("\(progression.coins)").font(.system(size: 16, weight: .black, design: .rounded)).foregroundColor(.white)
                                Image(systemName: "plus.circle.fill").foregroundColor(.green)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.black.opacity(0.4)))
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        }
                    }
                    Spacer()
                    // Settings button removed from Map, adding invisible spacer for header symmetry
                    Circle().fill(Color.clear).frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20).padding(.top, 10)
                
                TabView(selection: $currentPage) {
                    ForEach(0..<worlds.count, id: \.self) { index in
                        worldGrid(for: worlds[index]).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .onChange(of: currentPage) { newValue in
                    onColorChange(worlds[newValue].colors)
                }
            }
            .opacity(selectedLevel == nil ? 1.0 : 0.2)
            
            if let level = selectedLevel {
                Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { selectedLevel = nil }
                LevelPreviewPopup(
                    level: level, 
                    stars: progression.levelStars[level] ?? 0, 
                    onPlay: { selectedLevel = nil; onStartLevel(level) }, 
                    onClose: { selectedLevel = nil }
                )
            }
        }
        .onAppear { 
            scrollToCurrent() 
            onColorChange(worlds[currentPage].colors)
        }
    }
    
    private func scrollToCurrent() {
        let max = progression.maxUnlockedLevel
        if let idx = worlds.firstIndex(where: { $0.levels.contains(max) }) { currentPage = idx }
    }
    
    private func worldGrid(for world: WorldData) -> some View {
        GeometryReader { geo in
            let cols = world.columns
            // Compute node size to always fit within the available width
            let totalPadding: CGFloat = 32 // 16 each side
            let spacing: CGFloat = cols >= 6 ? 8 : 14
            let nodeSize: CGFloat = min(46, (geo.size.width - totalPadding - spacing * CGFloat(cols - 1)) / CGFloat(cols))
            let rows = chunked(world.levels, into: cols)
            
            ScrollView {
                VStack(spacing: spacing) {
                    ForEach(0..<rows.count, id: \.self) { rowIndex in
                        HStack(spacing: spacing) {
                            ForEach(rows[rowIndex], id: \.self) { level in
                                node(for: level, size: nodeSize)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func chunked<T>(_ array: [T], into size: Int) -> [[T]] {
        stride(from: 0, to: array.count, by: size).map {
            Array(array[$0 ..< Swift.min($0 + size, array.count)])
        }
    }
    
    private func node(for level: Int, size: CGFloat = 42) -> some View {
        let isUnlocked = level <= progression.maxUnlockedLevel || progression.debugUnlockAll
        let colors = progression.dynamicTheme(for: level)
        let isCurrent = level == (progression.levelStars.count + 1)
        let fontSize: CGFloat = size >= 44 ? 14 : (size >= 38 ? 12 : 11)
        
        return Button {
            if isUnlocked { 
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation { selectedLevel = level } 
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isUnlocked ? colors.first!.opacity(0.85) : .gray.opacity(0.25))
                    .frame(width: size, height: size)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().stroke(Color.white.opacity(isCurrent ? 1.0 : 0.6), lineWidth: isCurrent ? 3 : 1.5))
                    .shadow(color: isUnlocked ? (colors.first?.opacity(0.4) ?? .clear) : .clear, radius: 4, y: 2)
                
                if isUnlocked {
                    Text("\(level)")
                        .font(.system(size: fontSize, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: fontSize - 1))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
