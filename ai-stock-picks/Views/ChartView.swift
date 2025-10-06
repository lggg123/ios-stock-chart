//
//  ChartView.swift
//  ai-stock-picks
//
//  Created by Copilot on 10/6/25.
//

import SwiftUI
import Charts

struct ChartView: View {
    let symbol: String
    @StateObject private var viewModel: ChartViewModel
    
    init(symbol: String) {
        self.symbol = symbol
        _viewModel = StateObject(wrappedValue: ChartViewModel(symbol: symbol))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with price info
            headerView
            
            // Candlestick Chart
            chartView
                .frame(height: 300)
                .padding()
            
            // Detected Patterns
            if !viewModel.patterns.isEmpty {
                patternsListView
            }
            
            Spacer()
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(symbol)
                .font(.title)
                .fontWeight(.bold)
            
            if let lastCandle = viewModel.candles.last {
                HStack {
                    Text("$\(lastCandle.close, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    let change = lastCandle.close - lastCandle.open
                    let changePercent = (change / lastCandle.open) * 100
                    
                    Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.2f")")
                        .foregroundColor(change >= 0 ? .green : .red)
                    
                    Text("(\(changePercent, specifier: "%.2f")%)")
                        .foregroundColor(change >= 0 ? .green : .red)
                }
                .font(.subheadline)
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Chart View
    
    private var chartView: some View {
        Chart {
            ForEach(Array(viewModel.candles.enumerated()), id: \.offset) { index, candle in
                // Candlestick body
                RectangleMark(
                    x: .value("Index", index),
                    yStart: .value("Open", min(candle.open, candle.close)),
                    yEnd: .value("Close", max(candle.open, candle.close)),
                    width: 8
                )
                .foregroundStyle(candle.close >= candle.open ? Color.green : Color.red)
                
                // Candlestick wick (high-low)
                RuleMark(
                    x: .value("Index", index),
                    yStart: .value("Low", candle.low),
                    yEnd: .value("High", candle.high)
                )
                .lineStyle(StrokeStyle(lineWidth: 1))
                .foregroundStyle(candle.close >= candle.open ? Color.green : Color.red)
            }
            
            // Pattern annotations
            ForEach(viewModel.patterns) { pattern in
                if pattern.startIndex >= 0 && pattern.startIndex < viewModel.candles.count {
                    PointMark(
                        x: .value("Index", pattern.startIndex),
                        y: .value("Price", pattern.priceAtDetection)
                    )
                    .symbol(.circle)
                    .foregroundStyle(pattern.direction == "bullish" ? Color.green : Color.red)
                    .symbolSize(100)
                    .annotation(position: .top) {
                        Text(pattern.emoji)
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5))
        }
        .chartYAxis {
            AxisMarks(position: .trailing)
        }
        .overlay {
            if viewModel.candles.isEmpty && !viewModel.isLoading {
                VStack {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No chart data available")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Patterns List View
    
    private var patternsListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Patterns")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.patterns) { pattern in
                        PatternCard(pattern: pattern)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
    }
}

// MARK: - Pattern Card

struct PatternCard: View {
    let pattern: CandlestickPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pattern.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.patternType.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(pattern.direction.capitalized)
                        .font(.caption)
                        .foregroundColor(pattern.direction == "bullish" ? .green : .red)
                }
                
                Spacer()
            }
            
            HStack {
                Label("\(Int(pattern.confidence * 100))%", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(pattern.strengthStars)
                    .font(.caption)
            }
            
            Text("$\(pattern.priceAtDetection, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Preview

#Preview {
    ChartView(symbol: "AAPL")
}
