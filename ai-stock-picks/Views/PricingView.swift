//
//  PricingView.swift
//  ai-stock-picks
//
//  Created by Copilot on 10/6/25.
//

import SwiftUI

struct PricingView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedTier: SubscriptionTier = .pro
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Upgrade to Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Get unlimited access to AI-powered stock analysis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 32)
                    
                    // Pricing Cards
                    VStack(spacing: 16) {
                        PricingCard(
                            tier: .free,
                            isSelected: selectedTier == .free,
                            features: [
                                "100 API calls per day",
                                "10 pattern detections daily",
                                "3 price alerts",
                                "Basic charting",
                                "Community support"
                            ],
                            action: { selectedTier = .free }
                        )
                        
                        PricingCard(
                            tier: .pro,
                            isSelected: selectedTier == .pro,
                            isPopular: true,
                            features: [
                                "1,000 API calls per day",
                                "100 pattern detections daily",
                                "20 price alerts",
                                "Real-time data",
                                "Advanced charting",
                                "Priority support"
                            ],
                            action: { selectedTier = .pro }
                        )
                        
                        PricingCard(
                            tier: .premium,
                            isSelected: selectedTier == .premium,
                            features: [
                                "Unlimited API calls",
                                "Unlimited pattern detections",
                                "Unlimited alerts",
                                "Real-time data",
                                "Advanced charting",
                                "AI insights & predictions",
                                "24/7 premium support",
                                "Early access to features"
                            ],
                            action: { selectedTier = .premium }
                        )
                    }
                    .padding(.horizontal)
                    
                    // Subscribe Button
                    Button(action: subscribe) {
                        Text(selectedTier == .free ? "Continue with Free" : "Subscribe to \(selectedTier.displayName)")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTier == .free ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Terms
                    VStack(spacing: 8) {
                        Text("• Cancel anytime")
                        Text("• 14-day money-back guarantee")
                        Text("• Secure payment via Apple Pay")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Spacer(minLength: 32)
                }
            }
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private func subscribe() {
        Task {
            do {
                if selectedTier != .free {
                    try await APIService.shared.upgradeSubscription(to: selectedTier)
                }
                // Update auth manager
                dismiss()
            } catch {
                print("Subscription error: \(error)")
            }
        }
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    var isPopular: Bool = false
    let features: [String]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tier.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(tier.price)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isPopular {
                        Text("POPULAR")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                Divider()
                
                // Features
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                            
                            Text(feature)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .shadow(color: isPopular ? .blue.opacity(0.3) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    PricingView()
        .environmentObject(AuthManager())
}
