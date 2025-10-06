//
//  APIService.swift
//  ai-stock-picks
//
//  Created by Copilot on 10/6/25.
//

import Foundation

// MARK: - API Service
class APIService {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:3000" // Your Next.js API
    private let patternServiceURL = "http://localhost:8003" // Pattern detection service
    
    private init() {}
    
    // MARK: - User & Subscription
    
    func getSubscriptionStatus() async throws -> User {
        // Mock user for demo - in production, fetch from your backend
        return User(
            id: "demo-user",
            email: UserDefaults.standard.string(forKey: "user_email") ?? "demo@example.com",
            subscriptionTier: .pro
        )
    }
    
    func upgradeSubscription(to tier: SubscriptionTier) async throws {
        // Implement Stripe/RevenueCat integration
        print("Upgrading to \(tier.displayName)")
    }
    
    // MARK: - Stock Picks
    
    func getTopPicks(limit: Int = 100, category: String? = nil) async throws -> [StockPick] {
        var urlString = "\(baseURL)/api/ml/screen"
        
        var components = URLComponents(string: urlString)
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        if let category = category {
            components?.queryItems?.append(URLQueryItem(name: "category", value: category))
        }
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(PicksResponse.self, from: data)
        return result.topPicks ?? []
    }
    
    // MARK: - Pattern Detection
    
    func detectPatterns(symbol: String, candles: [Candle]) async throws -> [CandlestickPattern] {
        let url = URL(string: "\(patternServiceURL)/detect")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = PatternDetectionRequest(
            symbol: symbol,
            timeframe: "1d",
            candles: candles,
            context: ["rsi": 65.0, "macd": 0.5, "volume_ratio": 1.2]
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(PatternDetectionResponse.self, from: data)
        return result.patterns
    }
    
    func getPatternTypes() async throws -> [String] {
        let url = URL(string: "\(patternServiceURL)/patterns/types")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(PatternTypesResponse.self, from: data)
        return result.patterns
    }
    
    // MARK: - Market Data
    
    func getCandles(symbol: String, timeframe: String = "1d", limit: Int = 100) async throws -> [Candle] {
        // In production, connect to your market data provider
        // For now, return mock data
        return generateMockCandles(symbol: symbol, count: limit)
    }
    
    private func generateMockCandles(symbol: String, count: Int) -> [Candle] {
        var candles: [Candle] = []
        var currentDate = Date().addingTimeInterval(-Double(count) * 86400)
        var currentPrice = 150.0
        
        for _ in 0..<count {
            let open = currentPrice
            let high = open + Double.random(in: 0...5)
            let low = open - Double.random(in: 0...5)
            let close = Double.random(in: low...high)
            let volume = Double.random(in: 1_000_000...10_000_000)
            
            candles.append(Candle(
                timestamp: ISO8601DateFormatter().string(from: currentDate),
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
            
            currentDate = currentDate.addingTimeInterval(86400)
            currentPrice = close
        }
        
        return candles
    }
}

// MARK: - API Models

struct PatternDetectionRequest: Codable {
    let symbol: String
    let timeframe: String
    let candles: [Candle]
    let context: [String: Double]
}

struct PatternDetectionResponse: Codable {
    let symbol: String
    let timeframe: String
    let patterns: [CandlestickPattern]
    let totalPatterns: Int
    let detectionTimeMs: Double
    
    enum CodingKeys: String, CodingKey {
        case symbol, timeframe, patterns
        case totalPatterns = "total_patterns"
        case detectionTimeMs = "detection_time_ms"
    }
}

struct PatternTypesResponse: Codable {
    let patterns: [String]
    let total: Int
}

struct PicksResponse: Codable {
    let topPicks: [StockPick]?
    let generatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case topPicks = "top_picks"
        case generatedAt = "generated_at"
    }
}

struct Candle: Codable {
    let timestamp: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

struct CandlestickPattern: Codable, Identifiable {
    let id = UUID()
    let patternType: String
    let confidence: Double
    let direction: String
    let strength: Int
    let startIndex: Int
    let endIndex: Int
    let priceAtDetection: Double
    let context: [String: Double]
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case patternType = "pattern_type"
        case confidence, direction, strength
        case startIndex = "start_index"
        case endIndex = "end_index"
        case priceAtDetection = "price_at_detection"
        case context, timestamp
    }
    
    var emoji: String {
        switch direction {
        case "bullish": return "🟢"
        case "bearish": return "🔴"
        default: return "⚪️"
        }
    }
    
    var strengthStars: String {
        String(repeating: "⭐", count: strength)
    }
}

struct StockPick: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let companyName: String?
    let rank: Int
    let aiScore: Double
    let confidence: Double
    let riskScore: Double
    let predictedReturn: Double
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case companyName = "company_name"
        case rank
        case aiScore = "ai_score"
        case confidence
        case riskScore = "risk_score"
        case predictedReturn = "predicted_return"
        case category
    }
}

// MARK: - API Errors

enum APIError: Error {
    case invalidURL
    case serverError
    case decodingError
    case networkError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .serverError:
            return "Server error occurred"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network connection failed"
        }
    }
}
