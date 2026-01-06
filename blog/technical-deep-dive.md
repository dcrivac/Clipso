# How I Built Semantic Search for a Clipboard Manager Using Apple's On-Device ML

*A deep dive into building AI-powered features without the cloud*

---

## The Problem

I copy hundreds of things every day—code snippets, URLs, notes, random thoughts. But when I need to find something later, I'm stuck playing a frustrating game of "what exact words did I use?"

Traditional clipboard managers only do keyword matching. Search for "artificial intelligence" and you won't find items containing "machine learning" or "neural networks"—even though they're clearly related.

This seemed like a perfect use case for AI. But here's the catch: **I didn't want to send my clipboard data to the cloud.**

## The Solution: On-Device Semantic Search

That's when I discovered Apple's NLEmbedding framework—a way to do semantic AI completely on-device, with zero API calls.

### What Are Embeddings?

Embeddings are mathematical representations of text that capture meaning. Similar concepts end up close together in a high-dimensional space, even if they use different words.

For example:
- "coffee" and "espresso" → similar vectors
- "coffee" and "bicycle" → very different vectors

Apple's NLEmbedding generates 50-dimensional vectors locally on your Mac. No servers involved.

### The Implementation

Here's how I built it into ClipboardManager:

#### Step 1: Generate Embeddings on Copy

```swift
import NaturalLanguage

class SemanticEngine {
    private let embedding = NLEmbedding.sentenceEmbedding(for: .english)

    func generateEmbedding(for text: String) -> [Double]? {
        guard let embedding = embedding else { return nil }
        return embedding.vector(for: text)
    }
}
```

When you copy something, I generate its embedding in the background:

```swift
// In clipboard monitor
DispatchQueue.global(qos: .utility).async {
    if let vector = semanticEngine.generateEmbedding(for: content) {
        // Encode and store in Core Data
        item.embedding = try? JSONEncoder().encode(vector)
    }
}
```

**Performance**: <100ms per item, runs in background. Your Mac doesn't even notice.

#### Step 2: Semantic Search with Cosine Similarity

When you search, I compare the search query's embedding to every stored item:

```swift
func semanticSearch(_ query: String, items: [ClipboardItem]) -> [SearchResult] {
    guard let queryVector = generateEmbedding(for: query) else {
        return keywordFallback(query, items)
    }

    return items.compactMap { item in
        guard let itemVector = decodeEmbedding(item.embedding) else { return nil }

        let similarity = cosineSimilarity(queryVector, itemVector)
        return SearchResult(item: item, score: similarity)
    }
    .sorted { $0.score > $1.score }
}

func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
    let dotProduct = zip(a, b).map(*).reduce(0, +)
    let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
    let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
    return dotProduct / (magnitudeA * magnitudeB)
}
```

**Search Performance**: <50ms on 1000 items. Instant to the user.

#### Step 3: Hybrid Ranking

Pure semantic search isn't perfect. Sometimes exact keyword matches should rank higher. So I use a hybrid approach:

```swift
let finalScore = (0.4 * keywordScore) +
                 (0.3 * semanticScore) +
                 (0.2 * recencyScore) +
                 (0.1 * frequencyScore)
```

This balances four factors:
- **Keyword Match**: Exact or substring matches get a boost
- **Semantic Similarity**: The embedding cosine similarity
- **Recency**: Recently copied items rank higher
- **Frequency**: Items you access often get priority

### The Results

Search for "coffee recipes" and find:
- ✅ "espresso brewing guide"
- ✅ "how to make cappuccino"
- ✅ "latte art techniques"

All semantically related, none with the exact keywords.

## Beyond Search: Context Detection

Once I had embeddings for every clipboard item, I could do something even cooler: **automatic project detection**.

### Algorithm 1: App Pattern Recognition

I track which apps you copy from:

```swift
func detectAppPatterns(_ items: [ClipboardItem]) -> [Project] {
    // Group items by app sequences
    let windows = items.chunked(into: 10)

    return windows.compactMap { window in
        let apps = window.map { $0.sourceApp }
        let appSet = Set(apps)

        // If 3+ apps appear together frequently, it's likely a project
        if appSet.count >= 3 && frequency(appSet) > 0.7 {
            return Project(apps: appSet, items: window)
        }
        return nil
    }
}
```

**Example**: If you often copy from Xcode + Terminal + Safari together, those items probably belong to the same coding project.

### Algorithm 2: Time Window Clustering

Items copied within 30-minute windows often relate to the same task:

```swift
func clusterByTime(_ items: [ClipboardItem]) -> [[ClipboardItem]] {
    var clusters: [[ClipboardItem]] = []
    var currentCluster: [ClipboardItem] = []

    for item in items.sorted(by: { $0.timestamp < $1.timestamp }) {
        if let last = currentCluster.last,
           item.timestamp.timeIntervalSince(last.timestamp) > 1800 { // 30 min
            clusters.append(currentCluster)
            currentCluster = [item]
        } else {
            currentCluster.append(item)
        }
    }

    return clusters
}
```

### Algorithm 3: Content Similarity

Using those embeddings again, I find items with similar content:

```swift
func clusterBySimilarity(_ items: [ClipboardItem]) -> [[ClipboardItem]] {
    // Build similarity matrix
    var clusters: [[ClipboardItem]] = []
    var visited: Set<UUID> = []

    for item in items {
        guard !visited.contains(item.id) else { continue }

        // Find all items similar to this one (threshold: 0.75)
        let similar = items.filter { other in
            similarity(item, other) > 0.75
        }

        if similar.count >= 2 {
            clusters.append(similar)
            visited.formUnion(similar.map { $0.id })
        }
    }

    return clusters
}
```

### The Result: Auto-Organization

Your clipboard items automatically group into color-coded projects:

- 🔵 "Design System" (Figma + VS Code + Safari)
- 🟢 "API Integration" (Xcode + Terminal + Postman)
- 🔴 "Bug Fixes" (Git + Xcode)

**No manual tagging required.**

## Privacy First

This was the whole point: **zero cloud dependency**.

```swift
// This is the entire network code in ClipboardManager:
// [crickets]
```

That's right. There isn't any. Everything runs locally using Apple's frameworks:
- NLEmbedding for semantic vectors
- Vision for OCR
- Core Data for storage
- CryptoKit for encryption

Your clipboard data is as private as any other file on your Mac.

## Performance Numbers

After optimizing, here's where I landed:

| Operation | Time | Notes |
|-----------|------|-------|
| Generate embedding | <100ms | Background thread |
| Search 1000 items | <50ms | Main thread, instant |
| Memory usage | ~50MB | With 1000 items + embeddings |
| Database size | ~2MB | 1000 items with embeddings |
| Network requests | 0 | Always |

## Lessons Learned

### 1. On-Device ML is Ready

Apple's frameworks are surprisingly powerful. NLEmbedding isn't as sophisticated as OpenAI's models, but for this use case, it's perfect—and **instant**.

### 2. Users Value Privacy

The #1 comment I get: "Finally, a clipboard manager that doesn't send my data to the cloud!" There's real demand for local-first AI.

### 3. Hybrid Approaches Win

Pure semantic search has quirks. A hybrid approach that combines AI with traditional methods gives the best user experience.

### 4. Performance Matters

Even with embeddings for 1000 items, search feels instant. Background processing and smart indexing make this possible.

## The Tech Stack

- **Language**: Swift 5.9
- **UI**: SwiftUI
- **Storage**: Core Data
- **ML**: NaturalLanguage (NLEmbedding)
- **OCR**: Vision framework
- **Encryption**: CryptoKit (AES-256-GCM)

100% native Apple frameworks. No dependencies.

## Try It Yourself

ClipboardManager is free and open source:

👉 **[github.com/dcrivac/ClipboardManager](https://github.com/dcrivac/ClipboardManager)**

### Key Features:
- 🧠 Semantic search with NLEmbedding
- 🎯 Automatic context detection
- 🔒 100% local, zero network requests
- 💰 Free forever
- 📱 macOS 13.0+

## What's Next?

I'm exploring:
- Cross-item relationship graphs (visualizing connections)
- Natural language queries ("Find code I copied from Xcode yesterday")
- Predictive surfacing (suggest items before you need them)
- iCloud sync with end-to-end encryption

All still 100% privacy-preserving.

## Conclusion

Building AI features doesn't require cloud APIs or big ML models. For many use cases, on-device frameworks like NLEmbedding are perfect—and they give users privacy, speed, and offline functionality.

If you're building Mac apps, I highly recommend exploring Apple's ML frameworks. They're more capable than you might think.

---

**Questions? Drop them in the comments. Want to contribute? PRs welcome!**

**Follow me for more posts about building privacy-first AI applications.**

---

### Resources

- [NLEmbedding Documentation](https://developer.apple.com/documentation/naturallanguage/nlembedding)
- [ClipboardManager Source Code](https://github.com/dcrivac/ClipboardManager)
- [Apple ML Frameworks Overview](https://developer.apple.com/machine-learning/)

---

*Originally published on [your blog]. Cross-posted to Dev.to and Medium.*

**Tags**: #swift #macos #ai #machinelearning #privacy #opensource #nlp #embeddings #apple
