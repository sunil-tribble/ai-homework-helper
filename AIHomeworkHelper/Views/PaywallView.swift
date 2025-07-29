import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreKitManager
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var animateGradient = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.teal.opacity(0.1)],
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateGradient)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Features
                        featuresSection
                        
                        // Subscription Plans
                        plansSection
                        
                        // Purchase Button
                        purchaseButton
                        
                        // Terms and Restore
                        termsSection
                    }
                    .padding()
                }
            }
            .onAppear {
                animateGradient = true
            }
            .navigationTitle("Upgrade to Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
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
        }
        .onAppear {
            selectedPlan = SubscriptionPlan.plans.first
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.yellow.opacity(0.5), radius: 10)
            }
            
            Text("Unlock Unlimited Learning")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Get instant solutions to all your homework problems")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Solves",
                description: "No daily limits on homework help",
                iconColor: .blue
            )
            
            FeatureRow(
                icon: "brain.head.profile",
                title: "Advanced AI",
                description: "Get detailed, step-by-step explanations",
                iconColor: .purple
            )
            
            FeatureRow(
                icon: "sparkles",
                title: "All Subjects",
                description: "Math, Science, English, and more",
                iconColor: .orange
            )
            
            FeatureRow(
                icon: "bolt.fill",
                title: "Priority Support",
                description: "Fast responses and premium features",
                iconColor: .yellow
            )
        }
        .padding(.vertical)
    }
    
    private var plansSection: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionPlan.plans) { plan in
                PlanCard(
                    plan: plan,
                    isSelected: selectedPlan?.id == plan.id,
                    product: storeManager.products.first { $0.id == plan.id }
                ) {
                    selectedPlan = plan
                }
            }
        }
    }
    
    private var purchaseButton: some View {
        Button(action: purchase) {
            Text("Continue with \(selectedPlan?.name ?? "Premium")")
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
        .disabled(isPurchasing || selectedPlan == nil)
    }
    
    private var termsSection: some View {
        VStack(spacing: 16) {
            Button("Restore Purchases") {
                Task {
                    await storeManager.restorePurchases()
                    if storeManager.hasActiveSubscription {
                        userManager.upgradeToPremium()
                        dismiss()
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Terms of Service • Privacy Policy")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Subscriptions automatically renew unless cancelled")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func purchase() {
        guard let selectedPlan = selectedPlan,
              let product = storeManager.products.first(where: { $0.id == selectedPlan.id }) else {
            return
        }
        
        isPurchasing = true
        
        Task {
            do {
                if try await storeManager.purchase(product) != nil {
                    userManager.upgradeToPremium()
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            isPurchasing = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconColor.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .opacity(0.3)
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let product: Product?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(plan.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(product?.displayPrice ?? plan.price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                if plan.id == Config.Products.monthlySubscription {
                    Text("MOST POPULAR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: isSelected ? [Color.blue, Color.purple] : [Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isSelected ? 2 : 1
                        )
                }
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreKitManager())
        .environmentObject(UserManager())
}