import SwiftUI
import StoreKit

struct StoreView: View {
    @EnvironmentObject var storeManager: StoreKitManager
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: IAPProductInfo.ProductCategory = .boost
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var purchasedProductID: String?
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Category selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach([IAPProductInfo.ProductCategory.boost, .consumable, .theme, .tool], id: \.self) { category in
                                StoreCategoryChip(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Products grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 20) {
                            ForEach(filteredProducts, id: \.id) { productInfo in
                                if let storeProduct = storeManager.products.first(where: { $0.id == productInfo.id }) {
                                    ProductCard(
                                        productInfo: productInfo,
                                        storeProduct: storeProduct,
                                        isPurchased: storeManager.isPurchased(productInfo.id),
                                        onPurchase: { purchase(storeProduct) }
                                    )
                                } else {
                                    ProductCard(
                                        productInfo: productInfo,
                                        storeProduct: nil,
                                        isPurchased: false,
                                        onPurchase: { }
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Restore purchases
                    Button(action: restorePurchases) {
                        Text("Restore Purchases")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isPurchasing {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("Processing...")
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                }
            }
            .sheet(isPresented: $showingSuccess) {
                PurchaseSuccessView(productID: purchasedProductID ?? "")
            }
        }
    }
    
    private var filteredProducts: [IAPProductInfo] {
        IAPProductInfo.allProducts.filter { $0.category == selectedCategory }
    }
    
    private func purchase(_ product: Product) {
        isPurchasing = true
        
        Task {
            do {
                if let transaction = try await storeManager.purchase(product) {
                    // Handle specific product purchases
                    await handlePurchaseSuccess(productID: product.id, transaction: transaction)
                    purchasedProductID = product.id
                    showingSuccess = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            isPurchasing = false
        }
    }
    
    private func handlePurchaseSuccess(productID: String, transaction: StoreKit.Transaction) async {
        // Handle consumables
        switch productID {
        case IAPProducts.extraSolves5:
            userManager.addExtraSolves(5)
        case IAPProducts.extraSolves20:
            userManager.addExtraSolves(20)
        case IAPProducts.extraSolves50:
            userManager.addExtraSolves(50)
        default:
            break
        }
        
        // Award badge for first purchase
        if !userManager.unlockedBadges.contains("first_purchase") {
            userManager.checkBadgeUnlock(for: "first_purchase")
        }
    }
    
    private func restorePurchases() {
        Task {
            await storeManager.restorePurchases()
        }
    }
}

struct StoreCategoryChip: View {
    let category: IAPProductInfo.ProductCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconForCategory)
                Text(category.displayName)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
    
    private var iconForCategory: String {
        switch category {
        case .boost: return "bolt.fill"
        case .consumable: return "plus.circle.fill"
        case .theme: return "paintbrush.fill"
        case .tool: return "wrench.and.screwdriver.fill"
        }
    }
}

struct ProductCard: View {
    let productInfo: IAPProductInfo
    let storeProduct: Product?
    let isPurchased: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(productInfo.category.color.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: productInfo.icon)
                    .font(.title2)
                    .foregroundColor(productInfo.category.color)
                
                if isPurchased {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                        .offset(x: 20, y: -20)
                }
            }
            
            // Title
            Text(productInfo.name)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Description
            Text(productInfo.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Spacer()
            
            // Price/Action button
            if isPurchased {
                Label("Purchased", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Button(action: onPurchase) {
                    Text(storeProduct?.displayPrice ?? productInfo.defaultPrice)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(productInfo.category.color)
                        .cornerRadius(8)
                }
                .disabled(storeProduct == nil)
            }
        }
        .padding()
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(productInfo.category.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct PurchaseSuccessView: View {
    let productID: String
    @Environment(\.dismiss) private var dismiss
    @State private var celebrationAnimation = false
    
    private var productName: String {
        IAPProductInfo.allProducts.first { $0.id == productID }?.name ?? "Purchase"
    }
    
    var body: some View {
        ZStack {
            // Confetti background
            ForEach(0..<30, id: \.self) { _ in
                ConfettiPiece()
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: celebrationAnimation ? UIScreen.main.bounds.height + 100 : -100
                    )
                    .animation(
                        .easeOut(duration: Double.random(in: 2...4)),
                        value: celebrationAnimation
                    )
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Success icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(celebrationAnimation ? 1.0 : 0.5)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Purchase Successful!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("You've unlocked \(productName)")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                celebrationAnimation = true
            }
        }
    }
}

extension UserManager {
    func addExtraSolves(_ count: Int) {
        // Add extra solves to daily limit temporarily
        extraSolves += count
        // Save to UserDefaults
        UserDefaults.standard.set(extraSolves, forKey: "extraSolves")
        objectWillChange.send()
    }
    
    func checkBadgeUnlock(for badgeID: String) {
        if !unlockedBadges.contains(badgeID) {
            unlockedBadges.insert(badgeID)
            lastBadgeUnlocked = badgeID
            userPoints += 100 // Bonus points for special badges
        }
    }
}

#Preview {
    StoreView()
        .environmentObject(StoreKitManager())
        .environmentObject(UserManager())
}