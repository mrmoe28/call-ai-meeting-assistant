import SwiftUI

// MARK: - Color Definitions for Asset Catalog
extension Color {
    // Brand Colors
    static let brandPurple = Color("Brand/Purple", bundle: .main) 
    static let brandPurpleLight = Color("Brand/PurpleLight", bundle: .main)
    
    // Fallback colors for when assets aren't available
    static var safeBrandPurple: Color {
        if Bundle.main.path(forResource: "Brand/Purple", ofType: nil) != nil {
            return Color("Brand/Purple")
        }
        return Color(red: 0.63, green: 0.42, blue: 1.0) // #A06CFF
    }
    
    static var safeSurfaceBackground: Color {
        if Bundle.main.path(forResource: "Surface/Background", ofType: nil) != nil {
            return Color("Surface/Background")
        }
        return Color(red: 0.04, green: 0.04, blue: 0.06) // #0B0B0F
    }
    
    static var safeSurfaceElevated: Color {
        if Bundle.main.path(forResource: "Surface/Elevated", ofType: nil) != nil {
            return Color("Surface/Elevated")
        }
        return Color(red: 0.07, green: 0.07, blue: 0.09) // #111118
    }
    
    static var safeSurfaceCard: Color {
        if Bundle.main.path(forResource: "Surface/Card", ofType: nil) != nil {
            return Color("Surface/Card")
        }
        return Color(red: 0.10, green: 0.10, blue: 0.13) // #1A1A22
    }
    
    static var safeTextPrimary: Color {
        if Bundle.main.path(forResource: "Text/Primary", ofType: nil) != nil {
            return Color("Text/Primary")
        }
        return Color.white
    }
    
    static var safeTextSecondary: Color {
        if Bundle.main.path(forResource: "Text/Secondary", ofType: nil) != nil {
            return Color("Text/Secondary")
        }
        return Color(red: 0.79, green: 0.79, blue: 0.83) // #C9CAD3
    }
    
    static var safeTextMuted: Color {
        if Bundle.main.path(forResource: "Text/Muted", ofType: nil) != nil {
            return Color("Text/Muted")
        }
        return Color(red: 0.55, green: 0.55, blue: 0.59) // #8B8D97
    }
}