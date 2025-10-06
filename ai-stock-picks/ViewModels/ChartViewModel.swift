//
//  ChartViewModel.swift
//  ai-stock-picks
//
//  Created by Copilot on 10/6/25.
//

import Foundation
import Combine

@MainActor
class ChartViewModel: ObservableObject {
    @Published var symbol: String
    @Published var timeframe: String = "1d"
    @Published var candles: [Candle] = []
    @Published var patterns: [CandlestickPattern] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var webSocketTask: URLSessionWebSocketTask?
    
    init(symbol: String) {
        self.symbol = symbol
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        Task {
            await loadCandles()
            await detectPatterns()
        }
    }
    
    func loadCandles() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedCandles = try await APIService.shared.getCandles(
                symbol: symbol,
                timeframe: timeframe,
                limit: 100
            )
            
            // Convert API Candle to our ChartCandle
            self.candles = fetchedCandles.map { apiCandle in
                Candle(
                    timestamp: apiCandle.timestamp,
                    open: apiCandle.open,
                    high: apiCandle.high,
                    low: apiCandle.low,
                    close: apiCandle.close,
                    volume: apiCandle.volume
                )
            }
            
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func detectPatterns() async {
        guard !candles.isEmpty else { return }
        
        do {
            let detectedPatterns = try await APIService.shared.detectPatterns(
                symbol: symbol,
                candles: candles
            )
            
            self.patterns = detectedPatterns
        } catch {
            print("Pattern detection error: \(error)")
        }
    }
    
    // MARK: - WebSocket Real-time Connection
    
    func connect() {
        guard let url = URL(string: "ws://localhost:8003/ws/\(symbol)") else {
            return
        }
        
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessage() // Continue listening
                
            case .failure(let error):
                print("WebSocket error: \(error)")
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        Task { @MainActor in
            switch message {
            case .string(let text):
                if let data = text.data(using: .utf8) {
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        
                        if let newCandle = try? decoder.decode(Candle.self, from: data) {
                            // Update candles array
                            self.candles.append(newCandle)
                            
                            // Keep only last 100 candles
                            if self.candles.count > 100 {
                                self.candles.removeFirst()
                            }
                            
                            // Check for patterns in real-time
                            await self.detectPatterns()
                        }
                    }
                }
                
            case .data(let data):
                print("Received binary data: \(data)")
                
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Actions
    
    func refresh() {
        Task {
            await loadCandles()
            await detectPatterns()
        }
    }
    
    func changeTimeframe(_ newTimeframe: String) {
        self.timeframe = newTimeframe
        refresh()
    }
    
    deinit {
        disconnect()
    }
}

// MARK: - Chart-specific Candle Model

extension ChartViewModel {
    struct Candle: Identifiable {
        let id = UUID()
        let timestamp: String
        let open: Double
        let high: Double
        let low: Double
        let close: Double
        let volume: Double
        
        var date: Date {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: timestamp) ?? Date()
        }
    }
}
