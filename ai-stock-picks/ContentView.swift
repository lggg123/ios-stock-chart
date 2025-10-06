// ============================================
// COPY THIS TO YOUR XCODE PROJECT
// File: ContentView.swift
// ============================================

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        if authManager.isAuthenticated {
            TabView(selection: $selectedTab) {
                PicksView()
                    .tabItem {
                        Label("Picks", systemImage: "chart.bar.fill")
                    }
                    .tag(0)
                
                ExploreView()
                    .tabItem {
                        Label("Explore", systemImage: "magnifyingglass")
                    }
                    .tag(1)
                
                PortfolioView()
                    .tabItem {
                        Label("Portfolio", systemImage: "briefcase.fill")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }
        } else {
            OnboardingView()
                .environmentObject(authManager)
        }
    }
}

// ============================================
// AUTHENTICATION MANAGER
// ============================================

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    
    init() {
        // Check for existing auth token
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            isAuthenticated = true
            loadUser()
        }
    }
    
    func signIn(email: String, password: String) async {
        // Implement your auth logic
        // For now, just set authenticated
        await MainActor.run {
            isAuthenticated = true
            UserDefaults.standard.set("demo_token", forKey: "auth_token")
        }
    }
    
    func signOut() {
        isAuthenticated = false
        user = nil
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    private func loadUser() {
        Task {
            do {
                let user = try await APIService.shared.getSubscriptionStatus()
                await MainActor.run {
                    self.user = user
                }
            } catch {
                print("Error loading user: \(error)")
            }
        }
    }
}

// ============================================
// ONBOARDING VIEW
// ============================================

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var showPricing = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo/Title
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("AI Stock Screener")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Find winners before everyone else")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Stats
                HStack(spacing: 40) {
                    StatView(label: "+47%", sublabel: "Avg Return")
                    StatView(label: "86%", sublabel: "Win Rate")
                    StatView(label: "10k+", sublabel: "Traders")
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(16)
                
                Spacer()
                
                // Email input
                TextField("Enter your email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 32)
                
                // CTA Button
                Button(action: {
                    showPricing = true
                }) {
                    Text("Start Free Trial →")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                
                Text("14-day free trial • No credit card required")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
        }
        .sheet(isPresented: $showPricing) {
            PricingView()
        }
    }
}

struct StatView: View {
    let label: String
    let sublabel: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(sublabel)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// ============================================
// EXPLORE VIEW - Search & Chart
// ============================================

struct ExploreView: View {
    @State private var searchText = ""
    @State private var selectedStock: String?
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText)
                
                if let stock = selectedStock {
                    ChartView(symbol: stock)
                } else {
                    // Popular stocks
                    List {
                        Section("Popular Stocks") {
                            ForEach(["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA"], id: \.self) { symbol in
                                Button(action: {
                                    selectedStock = symbol
                                }) {
                                    HStack {
                                        Text(symbol)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Explore")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search stocks...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// ============================================
// PORTFOLIO VIEW
// ============================================

struct PortfolioView: View {
    @State private var positions: [Position] = []
    @State private var totalValue: Double = 0
    @State private var totalReturn: Double = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Portfolio summary card
                    VStack(spacing: 16) {
                        HStack {
                            Text("Portfolio Value")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(totalReturn >= 0 ? "+" : "")\(String(format: "%.2f", totalReturn))%")
                                .font(.headline)
                                .foregroundColor(totalReturn >= 0 ? .green : .red)
                        }
                        
                        Text("$\(String(format: "%.2f", totalValue))")
                            .font(.system(size: 48, weight: .bold))
                        
                        HStack(spacing: 20) {
                            StatBox(label: "Day", value: "+2.3%", color: .green)
                            StatBox(label: "Week", value: "+5.1%", color: .green)
                            StatBox(label: "Month", value: "+12.4%", color: .green)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    
                    // Positions
                    if positions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No positions yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Start trading to see your portfolio here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(positions) { position in
                            PositionRow(position: position)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Portfolio")
            .toolbar {
                Button(action: {}) {
                    Image(systemName: "plus.circle")
                }
            }
        }
    }
}

struct Position: Identifiable {
    let id = UUID()
    let symbol: String
    let shares: Int
    let avgCost: Double
    let currentPrice: Double
    
    var totalValue: Double {
        Double(shares) * currentPrice
    }
    
    var totalReturn: Double {
        ((currentPrice - avgCost) / avgCost) * 100
    }
}

struct PositionRow: View {
    let position: Position
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(position.symbol)
                    .font(.headline)
                Text("\(position.shares) shares")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", position.totalValue))")
                    .font(.headline)
                Text("\(position.totalReturn >= 0 ? "+" : "")\(String(format: "%.2f", position.totalReturn))%")
                    .font(.caption)
                    .foregroundColor(position.totalReturn >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// ============================================
// SETTINGS VIEW
// ============================================

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSubscription = false
    @State private var showReferral = false
    @State private var notificationsEnabled = true
    
    var body: some View {
        NavigationView {
            List {
                // Subscription section
                Section {
                    Button(action: { showSubscription = true }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(authManager.user?.subscriptionTier.rawValue.capitalized ?? "Free")
                                    .font(.headline)
                                Text("Manage subscription")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Account section
                Section("Account") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authManager.user?.email ?? "")
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: { showReferral = true }) {
                        HStack {
                            Text("Referral Code")
                            Spacer()
                            Image(systemName: "gift.fill")
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                // Notifications
                Section("Notifications") {
                    Toggle("Pattern Alerts", isOn: $notificationsEnabled)
                    Toggle("Price Alerts", isOn: $notificationsEnabled)
                    Toggle("Daily Summary", isOn: $notificationsEnabled)
                }
                
                // About
                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://yourapp.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://yourapp.com/terms")!)
                    Link("Help & Support", destination: URL(string: "https://yourapp.com/support")!)
                }
                
                // Sign out
                Section {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $showReferral) {
                ReferralView()
            }
        }
    }
}

// ============================================
// SUBSCRIPTION VIEW
// ============================================

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current plan
                    if let user = authManager.user {
                        VStack(spacing: 12) {
                            Text("Current Plan")
                                .font(.headline)
                            
                            Text(user.subscriptionTier.rawValue.capitalized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if let endDate = user.subscriptionEnd {
                                Text("Renews \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Usage stats
                        VStack(spacing: 16) {
                            UsageBar(
                                label: "API Calls",
                                used: user.usage.apiCallsToday,
                                limit: user.limits.apiCallsPerDay
                            )
                            
                            UsageBar(
                                label: "Patterns Detected",
                                used: user.usage.patternsDetectedToday,
                                limit: user.limits.patternsPerDay
                            )
                            
                            UsageBar(
                                label: "Active Alerts",
                                used: user.usage.alertsCount,
                                limit: user.limits.alerts
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Upgrade button
                    Button(action: {
                        // Show pricing
                    }) {
                        Text("Upgrade Plan")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Subscription")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct UsageBar: View {
    let label: String
    let used: Int
    let limit: Int
    
    var progress: Double {
        if limit == -1 { return 0 } // Unlimited
        return min(Double(used) / Double(limit), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(limit == -1 ? "Unlimited" : "\(used) / \(limit)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if limit != -1 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 8)
                .cornerRadius(4)
            }
        }
    }
}

// ============================================
// REFERRAL VIEW
// ============================================

struct ReferralView: View {
    @Environment(\.dismiss) var dismiss
    let referralCode = "DEMO123"
    let referrals = 0
    let creditsEarned = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Refer Friends")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("You both get 1 month free when they upgrade to Pro!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Referral code
                    VStack(spacing: 8) {
                        Text("Your Referral Code")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text(referralCode)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Button(action: {
                                UIPasteboard.general.string = referralCode
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    HStack(spacing: 40) {
                        StatView(label: "\(referrals)", sublabel: "Referrals")
                        StatView(label: "\(creditsEarned)", sublabel: "Months Earned")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Share button
                    Button(action: shareReferral) {
                        Label("Share Referral Link", systemImage: "square.and.arrow.up")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Referrals")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    func shareReferral() {
        let referralUrl = "https://yourapp.com/signup?ref=\(referralCode)"
        let text = "Join me on AI Stock Screener and we both get 1 month free! Use my code: \(referralCode)\n\n\(referralUrl)"
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// ============================================
// STOCK DETAIL VIEW
// ============================================

struct StockDetailView: View {
    let symbol: String
    @StateObject private var viewModel = ChartViewModel()
    @State private var selectedTimeframe = "1d"
    
    let timeframes = ["1m", "5m", "15m", "1h", "4h", "1d", "1w"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Chart
                ChartView(symbol: symbol)
                    .frame(height: 400)
                
                // Timeframe selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(timeframes, id: \.self) { tf in
                            TimeframeButton(
                                title: tf.uppercased(),
                                isSelected: selectedTimeframe == tf,
                                action: {
                                    selectedTimeframe = tf
                                    viewModel.timeframe = tf
                                    viewModel.disconnect()
                                    viewModel.connect()
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                // Analysis tabs
                // Add your factor analysis, news, etc.
            }
        }
        .navigationTitle(symbol)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.symbol = symbol
            viewModel.timeframe = selectedTimeframe
            viewModel.connect()
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }
}

struct TimeframeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

// ============================================
// PREVIEW
// ============================================

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
