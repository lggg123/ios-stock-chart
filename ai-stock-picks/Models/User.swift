//
//  User.swift
//  ai-stock-picks
//
//  Created by Copilot on 10/6/25.
//

import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    var subscriptionTier: SubscriptionTier
    var subscriptionEnd: Date?
    var usage: UsageStats
    var limits: SubscriptionLimits
    
    init(id: String, email: String, subscriptionTier: SubscriptionTier = .free) {
        self.id = id
        self.email = email
        self.subscriptionTier = subscriptionTier
        self.subscriptionEnd = nil
        self.usage = UsageStats()
        self.limits = subscriptionTier.limits
    }
}

// MARK: - Subscription Tier
enum SubscriptionTier: String, Codable {
    case free
    case pro
    case premium
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .premium: return "Premium"
        }
    }
    
    var limits: SubscriptionLimits {
        switch self {
        case .free:
            return SubscriptionLimits(
                apiCallsPerDay: 100,
                patternsPerDay: 10,
                alerts: 3,
                realtimeData: false
            )
        case .pro:
            return SubscriptionLimits(
                apiCallsPerDay: 1000,
                patternsPerDay: 100,
                alerts: 20,
                realtimeData: true
            )
        case .premium:
            return SubscriptionLimits(
                apiCallsPerDay: -1, // Unlimited
                patternsPerDay: -1, // Unlimited
                alerts: -1, // Unlimited
                realtimeData: true
            )
        }
    }
    
    var price: String {
        switch self {
        case .free: return "$0/month"
        case .pro: return "$29/month"
        case .premium: return "$99/month"
        }
    }
}

// MARK: - Subscription Limits
struct SubscriptionLimits: Codable {
    let apiCallsPerDay: Int  // -1 for unlimited
    let patternsPerDay: Int  // -1 for unlimited
    let alerts: Int          // -1 for unlimited
    let realtimeData: Bool
    
    func isUnlimited(_ type: String) -> Bool {
        switch type {
        case "apiCalls": return apiCallsPerDay == -1
        case "patterns": return patternsPerDay == -1
        case "alerts": return alerts == -1
        default: return false
        }
    }
}

// MARK: - Usage Statistics
struct UsageStats: Codable {
    var apiCallsToday: Int = 0
    var patternsDetectedToday: Int = 0
    var alertsCount: Int = 0
    var lastResetDate: Date = Date()
    
    mutating func resetIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            apiCallsToday = 0
            patternsDetectedToday = 0
            lastResetDate = Date()
        }
    }
    
    mutating func incrementAPICall() {
        resetIfNeeded()
        apiCallsToday += 1
    }
    
    mutating func incrementPattern() {
        resetIfNeeded()
        patternsDetectedToday += 1
    }
}
