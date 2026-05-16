# Skill: AI Integration

## Strategy
- **Primary:** Plant.id API (94-98% accuracy)
- **Secondary:** Gemini 2.5 Pro (treatment generation)
- **Pre-filter:** Apple Vision (free, on-device)
- **Caching:** 24-hour TTL on SHA256 hash

---

## 🔑 API Keys Setup

### **Config.plist (gitignored!)**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>PLANT_ID_API_KEY</key>
    <string>your_plant_id_key</string>
    <key>GEMINI_API_KEY</key>
    <string>your_gemini_key</string>
    <key>REVENUECAT_API_KEY</key>
    <string>your_revenuecat_key</string>
</dict>
</plist>
```

### **APIKeys.swift**
```swift
enum APIKeys {
    static let plantId: String = load("PLANT_ID_API_KEY")
    static let gemini: String = load("GEMINI_API_KEY")
    static let revenueCat: String = load("REVENUECAT_API_KEY")
    
    private static func load(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let value = plist[key] as? String,
              !value.isEmpty else {
            #if DEBUG
            fatalError("Missing API key: \(key). Add to Config.plist")
            #else
            return ""
            #endif
        }
        return value
    }
}
```

### **.gitignore (add this!):**
```
# API Keys
Config.plist
*.xcconfig

# Xcode
build/
DerivedData/
*.xcuserstate
.DS_Store
```

---

## 🌿 Plant.id API

### **Endpoint:**
```
POST https://plant.id/api/v3/identification
Headers:
  Api-Key: YOUR_KEY
  Content-Type: application/json
```

### **Request Model:**
```swift
struct PlantIdRequest: Codable {
    let images: [String]              // base64 encoded
    let latitude: Double?
    let longitude: Double?
    let similarImages: Bool
    let healthAssessment: Bool
    let classificationLevel: String   // "all" for variety detection
    
    enum CodingKeys: String, CodingKey {
        case images, latitude, longitude
        case similarImages = "similar_images"
        case healthAssessment = "health_assessment"
        case classificationLevel = "classification_level"
    }
}
```

### **Response Models:**
```swift
struct PlantIdResponse: Codable {
    let result: PlantIdResult
}

struct PlantIdResult: Codable {
    let isPlant: ProbabilityResult
    let classification: Classification
    let disease: DiseaseAssessment?
    
    enum CodingKeys: String, CodingKey {
        case isPlant = "is_plant"
        case classification
        case disease
    }
}

struct ProbabilityResult: Codable {
    let probability: Double
}

struct Classification: Codable {
    let suggestions: [PlantSuggestion]
}

struct PlantSuggestion: Codable, Identifiable {
    let id: String
    let name: String
    let probability: Double
    let details: PlantDetails?
}

struct PlantDetails: Codable {
    let commonNames: [String]?
    let url: String?
    let taxonomy: Taxonomy?
    let watering: Watering?
    let description: Description?
    
    enum CodingKeys: String, CodingKey {
        case commonNames = "common_names"
        case url, taxonomy, watering, description
    }
}

struct Taxonomy: Codable {
    let kingdom: String?
    let family: String?
    let genus: String?
    let species: String?
}

struct Watering: Codable {
    let max: Int?
    let min: Int?
}

struct Description: Codable {
    let value: String?
    let citation: String?
}

struct DiseaseAssessment: Codable {
    let suggestions: [DiseaseSuggestion]
}

struct DiseaseSuggestion: Codable, Identifiable {
    let id: String
    let name: String
    let probability: Double
    let details: DiseaseDetails?
}

struct DiseaseDetails: Codable {
    let description: String?
    let treatment: Treatment?
    let cause: String?
    let url: String?
}

struct Treatment: Codable {
    let prevention: [String]?
    let chemical: [String]?
    let biological: [String]?
}
```

### **Service:**
```swift
actor PlantIdService {
    static let shared = PlantIdService()
    
    private let apiKey = APIKeys.plantId
    private let baseURL = URL(string: "https://plant.id/api/v3")!
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    func identify(
        images: [Data],
        location: CLLocationCoordinate2D? = nil
    ) async throws -> PlantIdResponse {
        guard !images.isEmpty, images.count <= 5 else {
            throw AIError.invalidInput
        }
        
        let base64Images = images.map { $0.base64EncodedString() }
        
        let request = PlantIdRequest(
            images: base64Images,
            latitude: location?.latitude,
            longitude: location?.longitude,
            similarImages: true,
            healthAssessment: true,
            classificationLevel: "all"  // Get varieties, not just genus
        )
        
        let url = baseURL.appendingPathComponent("identification")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "Api-Key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        Logger.ai.info("Plant.id request started")
        let startTime = Date()
        
        let (data, response) = try await session.data(for: urlRequest)
        
        let duration = Date().timeIntervalSince(startTime)
        Logger.ai.info("Plant.id response in \(duration)s")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }
        
        switch httpResponse.statusCode {
        case 200, 201:
            return try JSONDecoder().decode(PlantIdResponse.self, from: data)
        case 401:
            throw AIError.invalidAPIKey
        case 429:
            throw AIError.rateLimited
        case 500...599:
            throw AIError.serverError
        default:
            throw AIError.unknownError(httpResponse.statusCode)
        }
    }
}
```

---

## 🧠 Gemini Service

### **Service:**
```swift
actor GeminiService {
    static let shared = GeminiService()
    
    private let apiKey = APIKeys.gemini
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent"
    private let session = URLSession.shared
    
    func generateTreatment(
        plantName: String,
        commonNames: [String],
        disease: DiseaseSuggestion?,
        userLanguage: String = "English",
        climate: ClimateContext? = nil
    ) async throws -> TreatmentPlan {
        let prompt = buildPrompt(
            plantName: plantName,
            commonNames: commonNames,
            disease: disease,
            language: userLanguage,
            climate: climate
        )
        
        let request = GeminiRequest(
            contents: [.init(parts: [.init(text: prompt)])],
            generationConfig: .init(
                temperature: 0.7,
                maxOutputTokens: 1024,
                responseMimeType: "application/json"
            )
        )
        
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        Logger.ai.info("Gemini request started")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            Logger.ai.error("Gemini failed: \(httpResponse.statusCode)")
            throw AIError.serverError
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw AIError.invalidResponse
        }
        
        return try parseTreatmentJSON(text)
    }
    
    private func buildPrompt(
        plantName: String,
        commonNames: [String],
        disease: DiseaseSuggestion?,
        language: String,
        climate: ClimateContext?
    ) -> String {
        var prompt = """
        You are an expert botanist. Generate a personalized care plan in \(language).
        
        Plant: \(plantName)
        Common names: \(commonNames.joined(separator: ", "))
        """
        
        if let disease = disease {
            prompt += """
            
            Detected issue: \(disease.name)
            Confidence: \(Int(disease.probability * 100))%
            Description: \(disease.details?.description ?? "")
            """
        } else {
            prompt += "\n\nPlant appears healthy"
        }
        
        if let climate = climate {
            prompt += """
            
            User's climate:
            - Location: \(climate.location)
            - Average humidity: \(climate.humidity)%
            - Average temperature: \(climate.temperature)°C
            - Season: \(climate.season)
            
            Adjust recommendations for this climate.
            """
        }
        
        prompt += """
        
        Respond with ONLY valid JSON (no markdown):
        {
          "summary": "1-2 sentence overview",
          "immediate_actions": ["urgent action 1", "action 2"],
          "weekly_care": ["routine 1", "routine 2", "routine 3"],
          "warning_signs": ["sign 1", "sign 2"],
          "recovery_timeline": "estimated time in plain language",
          "prevention_tips": ["tip 1", "tip 2"],
          "watering_frequency_days": 7,
          "fertilizing_frequency_days": 30
        }
        
        Rules:
        - Be specific and actionable
        - Include concrete measurements (e.g., "1 cup every 7 days")
        - Friendly but professional tone
        - Reference plant biology when helpful
        """
        
        return prompt
    }
    
    private func parseTreatmentJSON(_ text: String) throws -> TreatmentPlan {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleaned.data(using: .utf8) else {
            throw AIError.parsingFailed
        }
        
        return try JSONDecoder().decode(TreatmentPlan.self, from: jsonData)
    }
}
```

### **Gemini Models:**
```swift
struct GeminiRequest: Codable {
    let contents: [Content]
    let generationConfig: GenerationConfig
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
    
    struct GenerationConfig: Codable {
        let temperature: Double
        let maxOutputTokens: Int
        let responseMimeType: String
        
        enum CodingKeys: String, CodingKey {
            case temperature
            case maxOutputTokens = "max_output_tokens"
            case responseMimeType = "response_mime_type"
        }
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
}

struct TreatmentPlan: Codable {
    let summary: String
    let immediateActions: [String]
    let weeklyCare: [String]
    let warningSigns: [String]
    let recoveryTimeline: String
    let preventionTips: [String]
    let wateringFrequencyDays: Int
    let fertilizingFrequencyDays: Int
    
    enum CodingKeys: String, CodingKey {
        case summary
        case immediateActions = "immediate_actions"
        case weeklyCare = "weekly_care"
        case warningSigns = "warning_signs"
        case recoveryTimeline = "recovery_timeline"
        case preventionTips = "prevention_tips"
        case wateringFrequencyDays = "watering_frequency_days"
        case fertilizingFrequencyDays = "fertilizing_frequency_days"
    }
}

struct ClimateContext: Codable {
    let location: String
    let humidity: Int
    let temperature: Int
    let season: String
}
```

---

## 👁️ Apple Vision Pre-filter

```swift
import Vision
import UIKit

actor AppleVisionService {
    static let shared = AppleVisionService()
    
    func containsPlant(_ image: UIImage) async -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: false)
                    return
                }
                
                let plantKeywords = [
                    "plant", "flower", "leaf", "tree", "vegetation",
                    "foliage", "succulent", "herb", "fern", "moss",
                    "garden", "bush", "shrub", "grass"
                ]
                
                let containsPlant = results.contains { observation in
                    let identifier = observation.identifier.lowercased()
                    let matchesKeyword = plantKeywords.contains { keyword in
                        identifier.contains(keyword)
                    }
                    return matchesKeyword && observation.confidence > 0.3
                }
                
                continuation.resume(returning: containsPlant)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
}
```

---

## 🎯 Main AI Coordinator

```swift
actor AIService {
    static let shared = AIService()
    
    private let plantId = PlantIdService.shared
    private let gemini = GeminiService.shared
    private let vision = AppleVisionService.shared
    private let cache = ResponseCache()
    
    func analyzePlant(
        images: [UIImage],
        userLocation: CLLocation? = nil,
        userLanguage: String = "English",
        climate: ClimateContext? = nil
    ) async throws -> PlantAnalysisResult {
        
        // 1. Validate input
        guard !images.isEmpty, images.count <= 3 else {
            throw AIError.invalidInput
        }
        
        // 2. Apple Vision pre-check (FREE, saves API calls)
        let isPlant = await vision.containsPlant(images[0])
        guard isPlant else {
            Logger.ai.info("Apple Vision: no plant detected")
            throw AIError.noPlantDetected
        }
        
        // 3. Optimize images
        let imageData = images.compactMap { $0.optimizeForAPI() }
        guard imageData.count == images.count else {
            throw AIError.compressionFailed
        }
        
        // 4. Check cache
        let hash = imageData.first!.sha256Hash
        if let cached = await cache.get(hash: hash) {
            Logger.ai.info("Cache hit")
            return cached
        }
        
        // 5. Plant.id identification
        let identification = try await plantId.identify(
            images: imageData,
            location: userLocation?.coordinate
        )
        
        guard let plant = identification.result.classification.suggestions.first else {
            throw AIError.identificationFailed
        }
        
        let disease = identification.result.disease?.suggestions
            .first(where: { $0.probability > 0.5 })
        
        // 6. Gemini treatment generation
        let treatment = try await gemini.generateTreatment(
            plantName: plant.name,
            commonNames: plant.details?.commonNames ?? [],
            disease: disease,
            userLanguage: userLanguage,
            climate: climate
        )
        
        // 7. Combine results
        let result = PlantAnalysisResult(
            plantName: plant.name,
            commonNames: plant.details?.commonNames ?? [],
            scientificName: plant.details?.taxonomy?.species,
            confidence: plant.probability,
            disease: disease,
            treatment: treatment,
            alternativeMatches: Array(identification.result.classification.suggestions.dropFirst().prefix(3)),
            timestamp: Date()
        )
        
        // 8. Cache for 24 hours
        await cache.set(hash: hash, result: result)
        
        Logger.ai.info("Analysis complete: \(plant.name) at \(Int(plant.probability * 100))% confidence")
        
        return result
    }
}

struct PlantAnalysisResult: Codable {
    let plantName: String
    let commonNames: [String]
    let scientificName: String?
    let confidence: Double
    let disease: DiseaseSuggestion?
    let treatment: TreatmentPlan
    let alternativeMatches: [PlantSuggestion]
    let timestamp: Date
    
    var confidencePercent: Int { Int(confidence * 100) }
    var isHighConfidence: Bool { confidence >= 0.85 }
    var needsExpertReview: Bool { confidence < 0.70 }
}
```

---

## 🗄️ Response Cache

```swift
actor ResponseCache {
    private var cache: [String: CachedResult] = [:]
    private let ttl: TimeInterval = 86400  // 24 hours
    
    func get(hash: String) -> PlantAnalysisResult? {
        guard let cached = cache[hash],
              Date().timeIntervalSince(cached.timestamp) < ttl else {
            return nil
        }
        return cached.result
    }
    
    func set(hash: String, result: PlantAnalysisResult) {
        cache[hash] = CachedResult(result: result, timestamp: Date())
    }
    
    func clear() {
        cache.removeAll()
    }
}

struct CachedResult {
    let result: PlantAnalysisResult
    let timestamp: Date
}
```

---

## 🖼️ Image Optimization

```swift
import UIKit
import CryptoKit

extension UIImage {
    func optimizeForAPI() -> Data? {
        let maxDimension: CGFloat = 1024
        let compressionQuality: CGFloat = 0.75
        
        let resized: UIImage
        if size.width > maxDimension || size.height > maxDimension {
            let scale = min(maxDimension / size.width, maxDimension / size.height)
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            
            let renderer = UIGraphicsImageRenderer(size: newSize)
            resized = renderer.image { _ in
                draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            resized = self
        }
        
        return resized.jpegData(compressionQuality: compressionQuality)
    }
}

extension Data {
    var sha256Hash: String {
        let digest = SHA256.hash(data: self)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
```

---

## ⚠️ Error Handling

```swift
enum AIError: LocalizedError {
    case noPlantDetected
    case imageUnclear
    case compressionFailed
    case identificationFailed
    case lowConfidence(Double)
    case invalidAPIKey
    case rateLimited
    case networkError
    case serverError
    case invalidInput
    case invalidResponse
    case parsingFailed
    case unknownError(Int)
    
    var errorDescription: String? {
        switch self {
        case .noPlantDetected:
            return "No plant detected. Try a clearer photo."
        case .imageUnclear:
            return "Image is too blurry. Use better lighting."
        case .compressionFailed:
            return "Failed to process image."
        case .identificationFailed:
            return "Could not identify this plant."
        case .lowConfidence(let conf):
            return "Low confidence (\(Int(conf*100))%). Try multiple angles."
        case .invalidAPIKey:
            return "Authentication failed. Please try again."
        case .rateLimited:
            return "Too many requests. Wait a few minutes."
        case .networkError:
            return "Check your internet connection."
        case .serverError:
            return "Server temporarily unavailable."
        case .invalidInput:
            return "Invalid input."
        case .invalidResponse:
            return "Unexpected response."
        case .parsingFailed:
            return "Failed to process result."
        case .unknownError(let code):
            return "Error \(code). Please try again."
        }
    }
    
    var recoveryAction: String? {
        switch self {
        case .noPlantDetected: return "Take a clearer photo of a plant"
        case .imageUnclear: return "Use better lighting and focus"
        case .lowConfidence: return "Try multiple angles"
        case .rateLimited: return "Wait a few minutes"
        case .networkError: return "Check WiFi/cellular"
        default: return nil
        }
    }
}
```

---

## 📱 SwiftUI Usage

```swift
struct ScanResultsView: View {
    let images: [UIImage]
    
    @State private var result: PlantAnalysisResult?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView("Analyzing your plant...")
            } else if let result {
                DiagnosisResultView(result: result)
            } else if let errorMessage {
                ErrorRecoveryView(message: errorMessage) {
                    Task { await analyze() }
                }
            }
        }
        .task {
            await analyze()
        }
    }
    
    private func analyze() async {
        isLoading = true
        errorMessage = nil
        
        do {
            result = try await AIService.shared.analyzePlant(
                images: images,
                userLanguage: Locale.current.language.languageCode?.identifier ?? "English"
            )
        } catch {
            errorMessage = error.localizedDescription
            Logger.ai.error("Analysis failed: \(error)")
        }
        
        isLoading = false
    }
}
```

---

## 💰 Cost Tracking

```swift
@Model
final class APIUsageLog {
    var date: Date
    var service: String  // "plant_id" or "gemini"
    var cost: Double
    var success: Bool
    var userId: UUID?
    
    init(service: String, cost: Double, success: Bool, userId: UUID? = nil) {
        self.date = Date()
        self.service = service
        self.cost = cost
        self.success = success
        self.userId = userId
    }
}

extension AIService {
    func logUsage(service: String, cost: Double, success: Bool) {
        // Track in SwiftData for monitoring
        // Alert if monthly cost exceeds budget
    }
}
```

---

## ✅ Pre-Commit Checklist

- [ ] API keys in Config.plist (not in code)
- [ ] All errors use AIError enum
- [ ] Cache integrated (saves API calls)
- [ ] Apple Vision pre-check (saves API calls)
- [ ] Image compression (saves bandwidth)
- [ ] Logger statements (not print)
- [ ] Timeout intervals set
- [ ] All async paths handled
- [ ] Cost logging for monitoring
