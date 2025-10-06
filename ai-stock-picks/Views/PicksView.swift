//
//  PicksView.swift
//  ai-stock-picks
//
//  Created by Copilot on 10/6/25.
//

import SwiftUI

struct PicksView: View {
    @StateObject private var viewModel = PicksViewModel()
    @State private var selectedCategory: String? = nil
    
    let categories = ["All", "Growth", "Value", "Momentum", "Quality"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter
                categoryFilter
                
                // Picks List
                if viewModel.isLoading {
                    ProgressView("Loading AI picks...")
                        .padding()
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    picksListView
                }
            }
            .navigationTitle("AI Stock Picks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refresh()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            if viewModel.picks.isEmpty {
                viewModel.loadPicks()
            }
        }
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryButton(
                        title: category,
                        isSelected: selectedCategory == category || (category == "All" && selectedCategory == nil),
                        action: {
                            if category == "All" {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                            viewModel.filterByCategory(category == "All" ? nil : category)
                        }
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Picks List
    
    private var picksListView: some View {
        List {
            ForEach(viewModel.filteredPicks) { pick in
                NavigationLink(destination: StockDetailView(symbol: pick.symbol)) {
                    PickRowView(pick: pick)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refreshAsync()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Failed to load picks")
                .font(.headline)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                viewModel.refresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Category Button

struct CategoryButton: View {
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
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Pick Row View

struct PickRowView: View {
    let pick: StockPick
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 44, height: 44)
                
                Text("#\(pick.rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Stock Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(pick.symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if let companyName = pick.companyName {
                        Text(companyName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                HStack(spacing: 8) {
                    CategoryBadge(text: pick.category.capitalized)
                    
                    ScoreBadge(
                        label: "AI",
                        value: pick.aiScore,
                        color: .blue
                    )
                    
                    ScoreBadge(
                        label: "Risk",
                        value: pick.riskScore,
                        color: riskColor
                    )
                }
            }
            
            Spacer()
            
            // Predicted Return
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(pick.predictedReturn >= 0 ? "+" : "")\(pick.predictedReturn, specifier: "%.1f")%")
                    .font(.headline)
                    .foregroundColor(pick.predictedReturn >= 0 ? .green : .red)
                
                Text("\(Int(pick.confidence * 100))% conf")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var rankColor: Color {
        switch pick.rank {
        case 1...10: return .yellow
        case 11...50: return .blue
        default: return .gray
        }
    }
    
    private var riskColor: Color {
        switch pick.riskScore {
        case 0..<30: return .green
        case 30..<70: return .orange
        default: return .red
        }
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.2))
            .foregroundColor(.purple)
            .cornerRadius(4)
    }
}

// MARK: - Score Badge

struct ScoreBadge: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(Int(value))")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}

// MARK: - Stock Detail View

struct StockDetailView: View {
    let symbol: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Chart
                ChartView(symbol: symbol)
                
                // Additional details would go here
                Text("Detailed analysis for \(symbol)")
                    .padding()
            }
        }
        .navigationTitle(symbol)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - View Model

@MainActor
class PicksViewModel: ObservableObject {
    @Published var picks: [StockPick] = []
    @Published var filteredPicks: [StockPick] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadPicks() {
        Task {
            isLoading = true
            error = nil
            
            do {
                let fetchedPicks = try await APIService.shared.getTopPicks(limit: 100)
                self.picks = fetchedPicks
                self.filteredPicks = fetchedPicks
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func refresh() {
        loadPicks()
    }
    
    func refreshAsync() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedPicks = try await APIService.shared.getTopPicks(limit: 100)
            self.picks = fetchedPicks
            self.filteredPicks = fetchedPicks
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func filterByCategory(_ category: String?) {
        if let category = category {
            filteredPicks = picks.filter { $0.category.lowercased() == category.lowercased() }
        } else {
            filteredPicks = picks
        }
    }
}

// MARK: - Preview

#Preview {
    PicksView()
}
