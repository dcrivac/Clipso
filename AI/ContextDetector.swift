import Foundation
import CoreData
import AppKit

// MARK: - Context Detector
class ContextDetector {
    static let shared = ContextDetector()
    private let semanticEngine = SemanticEngine.shared

    // MARK: - App Pattern Detection
    func detectAppPatterns(_ items: [ClipboardItemEntity]) -> [String: [ClipboardItemEntity]] {
        var patterns: [String: [ClipboardItemEntity]] = [:]

        // Take last 50 items for pattern analysis
        let recentItems = Array(items.prefix(50))

        // Build app sequences (sliding window of 3)
        var appSequences: [String: Int] = [:]

        for i in 0..<(recentItems.count - 2) {
            let apps = [
                recentItems[i].sourceApp ?? "",
                recentItems[i+1].sourceApp ?? "",
                recentItems[i+2].sourceApp ?? ""
            ].filter { !$0.isEmpty }

            if apps.count >= 2 {
                let pattern = apps.sorted().joined(separator: " + ")
                appSequences[pattern, default: 0] += 1
            }
        }

        // Find common patterns (appeared 3+ times)
        let commonPatterns = appSequences.filter { $0.value >= 3 }.keys

        // Group items by detected patterns
        for item in recentItems {
            guard let itemApp = item.sourceApp, !itemApp.isEmpty else { continue }

            for pattern in commonPatterns {
                if pattern.contains(itemApp) {
                    patterns[pattern, default: []].append(item)
                }
            }
        }

        return patterns
    }

    // MARK: - Time Window Detection
    func detectTimeWindows(_ items: [ClipboardItemEntity], windowMinutes: Int = 30) -> [[ClipboardItemEntity]] {
        var windows: [[ClipboardItemEntity]] = []

        // Sort by timestamp
        let sortedItems = items.sorted { $0.timestamp < $1.timestamp }

        var currentWindow: [ClipboardItemEntity] = []
        var windowStart: Date?

        for item in sortedItems {
            let timestamp = item.timestamp

            if let start = windowStart {
                let minutesDiff = Calendar.current.dateComponents([.minute], from: start, to: timestamp).minute ?? 0

                if minutesDiff <= windowMinutes {
                    // Add to current window
                    currentWindow.append(item)
                } else {
                    // Start new window
                    if !currentWindow.isEmpty {
                        windows.append(currentWindow)
                    }
                    currentWindow = [item]
                    windowStart = timestamp
                }
            } else {
                // First item
                currentWindow.append(item)
                windowStart = timestamp
            }
        }

        // Add last window
        if !currentWindow.isEmpty {
            windows.append(currentWindow)
        }

        // Merge adjacent windows if >70% similar
        return mergeSimilarWindows(windows)
    }

    private func mergeSimilarWindows(_ windows: [[ClipboardItemEntity]]) -> [[ClipboardItemEntity]] {
        guard windows.count > 1 else { return windows }

        var merged: [[ClipboardItemEntity]] = []
        var current = windows[0]

        for i in 1..<windows.count {
            let next = windows[i]
            let similarity = calculateWindowSimilarity(current, next)

            if similarity > 0.7 {
                current.append(contentsOf: next)
            } else {
                merged.append(current)
                current = next
            }
        }

        merged.append(current)
        return merged
    }

    private func calculateWindowSimilarity(_ window1: [ClipboardItemEntity], _ window2: [ClipboardItemEntity]) -> Double {
        // Calculate similarity based on common apps
        let apps1 = Set(window1.compactMap { $0.sourceApp })
        let apps2 = Set(window2.compactMap { $0.sourceApp })

        guard !apps1.isEmpty && !apps2.isEmpty else { return 0.0 }

        let intersection = apps1.intersection(apps2).count
        let union = apps1.union(apps2).count

        return Double(intersection) / Double(union)
    }

    // MARK: - Content Similarity Clustering
    func detectContentClusters(_ items: [ClipboardItemEntity], threshold: Double = 0.75) -> [[ClipboardItemEntity]] {
        var clusters: [[ClipboardItemEntity]] = []
        var processed: Set<UUID> = []

        for item in items {
            guard !processed.contains(item.id) else { continue }

            // Find similar items
            let similarItems = semanticEngine.findSimilarItems(to: item, in: items, threshold: threshold)

            if !similarItems.isEmpty {
                var cluster = [item]
                cluster.append(contentsOf: similarItems.map { $0.0 })

                // Mark all as processed
                cluster.forEach { processed.insert($0.id) }

                clusters.append(cluster)
            } else {
                processed.insert(item.id)
            }
        }

        return clusters
    }

    // MARK: - Project Tag Suggestions
    func suggestProjectTags(for item: ClipboardItemEntity, basedOn history: [ClipboardItemEntity]) -> [TagSuggestion] {
        var suggestions: [TagSuggestion] = []

        // Learn from manually tagged items
        let taggedItems = history.filter { $0.projectTag != nil && !$0.projectTag!.isEmpty }

        guard !taggedItems.isEmpty else { return [] }

        // Group by tag
        var tagGroups: [String: [ClipboardItemEntity]] = [:]
        for taggedItem in taggedItems {
            guard let tag = taggedItem.projectTag else { continue }
            tagGroups[tag, default: []].append(taggedItem)
        }

        // For each tag, check if current item matches the pattern
        for (tag, group) in tagGroups {
            var score = 0.0
            var matchCount = 0

            // Check app match
            if let itemApp = item.sourceApp {
                let groupApps = Set(group.compactMap { $0.sourceApp })
                if groupApps.contains(itemApp) {
                    score += 0.3
                    matchCount += 1
                }
            }

            // Check content similarity
            let similarItems = group.filter { otherItem in
                let similar = semanticEngine.findSimilarItems(to: item, in: [otherItem], threshold: 0.7)
                return !similar.isEmpty
            }

            if !similarItems.isEmpty {
                score += 0.4 * (Double(similarItems.count) / Double(group.count))
                matchCount += 1
            }

            // Check time proximity (within last hour)
            let itemTime = item.timestamp
            let recentItems = group.filter { otherItem in
                let otherTime = otherItem.timestamp
                let minutes = Calendar.current.dateComponents([.minute], from: otherTime, to: itemTime).minute ?? Int.max
                return abs(minutes) <= 60
            }

            if !recentItems.isEmpty {
                score += 0.3
                matchCount += 1
            }

            // Only suggest if at least 2 criteria match
            if matchCount >= 2 && score > 0.5 {
                suggestions.append(TagSuggestion(tag: tag, confidence: score))
            }
        }

        // Sort by confidence
        return suggestions.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Context Score Calculation
    func calculateContextScores(_ items: [ClipboardItemEntity]) -> [UUID: Double] {
        var scores: [UUID: Double] = [:]

        guard let currentApp = NSWorkspace.shared.frontmostApplication?.localizedName else {
            return scores
        }

        for item in items {
            var score = 0.0

            // Recency (40%)
            let timestamp = item.timestamp
            let hoursSince = Calendar.current.dateComponents([.hour], from: timestamp, to: Date()).hour ?? 0
            let recencyScore = max(0, 0.4 - Double(hoursSince) * 0.02)
            score += recencyScore

            // App match (30%)
            if item.sourceApp == currentApp {
                score += 0.3
            }

            // Frequency (20%)
            let frequencyScore = min(0.2, Double(item.accessCount) * 0.02)
            score += frequencyScore

            // Has project tag (10%)
            if item.projectTag != nil && !item.projectTag!.isEmpty {
                score += 0.1
            }

            scores[item.id] = min(1.0, max(0.0, score))
        }

        return scores
    }
}

// Tag suggestion structure
struct TagSuggestion: Identifiable {
    let id = UUID()
    let tag: String
    let confidence: Double

    var confidencePercent: Int {
        Int(confidence * 100)
    }
}
