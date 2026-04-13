import Foundation

enum GameLogger {
    static func debug(_ message: String, category: String = "GENERAL", emoji: String = "💡") {
        #if DEBUG
        print("\(emoji) [\(category)] \(message)")
        #endif
    }

    static func error(_ message: String, category: String = "ERROR") {
        #if DEBUG
        print("❌ [\(category)] \(message)")
        #endif
    }
    
    static func success(_ message: String, category: String = "SUCCESS") {
        #if DEBUG
        print("✅ [\(category)] \(message)")
        #endif
    }
    
    // Bu fonksiyonun yukarıdaki parantezin içinde olduğundan emin ol!
    static func warning(_ message: String, category: String = "WARNING") {
        #if DEBUG
        print("⚠️ [\(category)] \(message)")
        #endif
    }
} // Enum burada bitmeli

