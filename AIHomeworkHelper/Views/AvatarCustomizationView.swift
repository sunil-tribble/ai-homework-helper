import SwiftUI

struct AvatarCustomizationView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAvatarBase = "avatar_1"
    @State private var selectedHairStyle = "hair_1"
    @State private var selectedHairColor = Color.brown
    @State private var selectedSkinTone = Color(red: 0.96, green: 0.87, blue: 0.70)
    @State private var selectedAccessory = "none"
    @State private var selectedBackground = "gradient_1"
    @State private var selectedTheme = AppTheme.default
    
    @State private var animateAvatar = false
    @State private var showUnlockPrompt = false
    @State private var selectedLockedItem: CustomizationItem?
    
    let avatarBases = ["avatar_1", "avatar_2", "avatar_3", "avatar_4"]
    let hairStyles = ["hair_1", "hair_2", "hair_3", "hair_4", "hair_5"]
    let accessories = ["none", "glasses_1", "glasses_2", "headphones", "hat_1", "crown"]
    let backgrounds = ["gradient_1", "gradient_2", "gradient_3", "space", "nature", "abstract"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic theme background
                selectedTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar Preview
                        avatarPreview
                            .padding(.top)
                        
                        // Customization sections
                        VStack(spacing: 20) {
                            // Base Avatar
                            CustomizationSection(
                                title: "Avatar Style",
                                icon: "person.fill"
                            ) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(avatarBases, id: \.self) { base in
                                            AvatarOptionCard(
                                                id: base,
                                                isSelected: selectedAvatarBase == base,
                                                isLocked: isItemLocked(base),
                                                requiredLevel: getRequiredLevel(base)
                                            ) {
                                                selectItem(base, category: .avatar)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Hair Style
                            CustomizationSection(
                                title: "Hair Style",
                                icon: "scissors"
                            ) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(hairStyles, id: \.self) { style in
                                            AvatarOptionCard(
                                                id: style,
                                                isSelected: selectedHairStyle == style,
                                                isLocked: isItemLocked(style),
                                                requiredLevel: getRequiredLevel(style)
                                            ) {
                                                selectItem(style, category: .hair)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Colors
                            CustomizationSection(
                                title: "Colors",
                                icon: "paintpalette.fill"
                            ) {
                                VStack(spacing: 16) {
                                    ColorPicker("Hair Color", selection: $selectedHairColor)
                                    ColorPicker("Skin Tone", selection: $selectedSkinTone)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Accessories
                            CustomizationSection(
                                title: "Accessories",
                                icon: "sparkles"
                            ) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(accessories, id: \.self) { accessory in
                                            AvatarOptionCard(
                                                id: accessory,
                                                isSelected: selectedAccessory == accessory,
                                                isLocked: isItemLocked(accessory),
                                                requiredLevel: getRequiredLevel(accessory)
                                            ) {
                                                selectItem(accessory, category: .accessory)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Themes
                            CustomizationSection(
                                title: "App Theme",
                                icon: "paintbrush.fill"
                            ) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(AppTheme.allCases, id: \.self) { theme in
                                            ThemeCard(
                                                theme: theme,
                                                isSelected: selectedTheme == theme,
                                                isLocked: isThemeLocked(theme)
                                            ) {
                                                selectTheme(theme)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Save button
                        Button(action: saveCustomization) {
                            Text("Save Avatar")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [selectedTheme.primaryColor, selectedTheme.secondaryColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Customize Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showUnlockPrompt) {
                if let item = selectedLockedItem {
                    UnlockItemView(item: item)
                        .environmentObject(userManager)
                }
            }
        }
    }
    
    private var avatarPreview: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: backgroundColors(for: selectedBackground),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 200)
                .shadow(color: selectedTheme.primaryColor.opacity(0.3), radius: 20)
            
            // Avatar
            VStack {
                ZStack {
                    // Base avatar shape
                    Circle()
                        .fill(selectedSkinTone)
                        .frame(width: 120, height: 120)
                    
                    // Eyes
                    HStack(spacing: 20) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 8, height: 8)
                    }
                    .offset(y: -10)
                    
                    // Smile
                    Curve()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 30, height: 15)
                        .offset(y: 10)
                    
                    // Hair
                    if selectedHairStyle != "none" {
                        RoundedRectangle(cornerRadius: 60)
                            .fill(selectedHairColor)
                            .frame(width: 140, height: 80)
                            .offset(y: -60)
                    }
                    
                    // Accessory
                    if selectedAccessory == "glasses_1" {
                        Image(systemName: "eyeglasses")
                            .font(.system(size: 40))
                            .foregroundColor(.black)
                            .offset(y: -10)
                    } else if selectedAccessory == "crown" {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.yellow)
                            .offset(y: -70)
                    }
                }
                .scaleEffect(animateAvatar ? 1.1 : 1.0)
                .rotationEffect(.degrees(animateAvatar ? 5 : -5))
                .animation(
                    .spring(response: 2, dampingFraction: 0.5)
                        .repeatForever(autoreverses: true),
                    value: animateAvatar
                )
            }
        }
        .onAppear {
            animateAvatar = true
        }
    }
    
    private func backgroundColors(for background: String) -> [Color] {
        switch background {
        case "gradient_1":
            return [Color.blue, Color.purple]
        case "gradient_2":
            return [Color.orange, Color.pink]
        case "gradient_3":
            return [Color.green, Color.teal]
        case "space":
            return [Color.black, Color.purple]
        case "nature":
            return [Color.green, Color.brown]
        default:
            return [Color.gray, Color.blue]
        }
    }
    
    private func isItemLocked(_ item: String) -> Bool {
        // Lock items based on user progress
        let requiredLevel = getRequiredLevel(item)
        let userLevel = calculateUserLevel()
        return userLevel < requiredLevel
    }
    
    private func getRequiredLevel(_ item: String) -> Int {
        switch item {
        case "avatar_3", "hair_4", "glasses_2":
            return 5
        case "avatar_4", "hair_5", "crown":
            return 10
        case "headphones":
            return 3
        default:
            return 1
        }
    }
    
    private func isThemeLocked(_ theme: AppTheme) -> Bool {
        switch theme {
        case .cosmic:
            return userManager.currentStreak < 7
        case .nature:
            return userManager.totalSolves < 50
        case .neon:
            return !userManager.isPremium
        default:
            return false
        }
    }
    
    private func calculateUserLevel() -> Int {
        // Simple level calculation based on total solves
        return min(userManager.totalSolves / 10 + 1, 20)
    }
    
    private func selectItem(_ item: String, category: CustomizationCategory) {
        if isItemLocked(item) {
            selectedLockedItem = CustomizationItem(
                id: item,
                category: category,
                requiredLevel: getRequiredLevel(item)
            )
            showUnlockPrompt = true
        } else {
            switch category {
            case .avatar:
                selectedAvatarBase = item
            case .hair:
                selectedHairStyle = item
            case .accessory:
                selectedAccessory = item
            }
        }
    }
    
    private func selectTheme(_ theme: AppTheme) {
        if isThemeLocked(theme) {
            // Show unlock prompt
            showUnlockPrompt = true
        } else {
            selectedTheme = theme
        }
    }
    
    private func saveCustomization() {
        // Play success feedback
        HapticManager.shared.notification(.success)
        SoundManager.shared.play(.success)
        
        // Save avatar configuration
        userManager.updateAvatar(
            base: selectedAvatarBase,
            hairStyle: selectedHairStyle,
            hairColor: selectedHairColor,
            skinTone: selectedSkinTone,
            accessory: selectedAccessory,
            background: selectedBackground,
            theme: selectedTheme
        )
        
        // Check for avatar customization achievement
        AchievementManager.shared.checkAchievements(for: userManager)
        
        dismiss()
    }
}

struct CustomizationSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            .padding(.horizontal)
            
            content()
        }
    }
}

struct AvatarOptionCard: View {
    let id: String
    let isSelected: Bool
    let isLocked: Bool
    let requiredLevel: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .frame(width: 80, height: 80)
                
                if isLocked {
                    VStack {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Lvl \(requiredLevel)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Preview of the item
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundColor(isSelected ? .blue : .gray)
                }
            }
        }
    }
}

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [theme.primaryColor, theme.secondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                        )
                    
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                    }
                }
                
                Text(theme.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
            }
        }
    }
}

struct UnlockItemView: View {
    let item: CustomizationItem
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Unlock This Item!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Reach Level \(item.requiredLevel) to unlock this customization")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your Level:")
                        Spacer()
                        Text("\(userManager.totalSolves / 10 + 1)")
                            .fontWeight(.bold)
                    }
                    
                    ProgressView(value: Double(userManager.totalSolves % 10), total: 10)
                        .tint(.blue)
                    
                    Text("\(10 - userManager.totalSolves % 10) more solves to next level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Keep Learning!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Locked Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Supporting types
enum CustomizationCategory {
    case avatar, hair, accessory
}

struct CustomizationItem {
    let id: String
    let category: CustomizationCategory
    let requiredLevel: Int
}

// AppTheme is now defined in Models/AppTheme.swift

struct Curve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.3),
            control: CGPoint(x: rect.width / 2, y: rect.height)
        )
        return path
    }
}

#Preview {
    AvatarCustomizationView()
        .environmentObject(UserManager())
}