//
//  PlantIdServiceTests.swift
//  VerdantTests
//
//  Created by Abrar Hamim on 5/17/26.
//

import Testing
import Foundation
@testable import Verdant

struct PlantIdServiceTests {

    // MARK: - Codable roundtrip

    @Test func requestEncodesOnlyImagesAndLocation() throws {
        // Plant.id v3: body is minimal (images + lat/lon). Feature flags
        // like similar_images / health / classification_level live on the
        // URL query string, not in the body. See PlantIdService.identify.
        let request = PlantIdRequest(
            images: ["base64data"],
            latitude: 23.81,
            longitude: 90.41
        )

        let data = try JSONEncoder().encode(request)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"images\":[\"base64data\"]"))
        #expect(json.contains("\"latitude\":23.81"))
        #expect(json.contains("\"longitude\":90.41"))
        #expect(json.contains("similar_images") == false)
        #expect(json.contains("health_assessment") == false)
        #expect(json.contains("classification_level") == false)
    }

    @Test func responseDecodesSampleFixture() throws {
        let fixture = """
        {
          "result": {
            "is_plant": { "probability": 0.98 },
            "classification": {
              "suggestions": [
                {
                  "id": "abc123",
                  "name": "Monstera deliciosa",
                  "probability": 0.94,
                  "details": {
                    "common_names": ["Swiss cheese plant"],
                    "url": "https://example.com/monstera",
                    "taxonomy": { "family": "Araceae" },
                    "watering": { "min": 1, "max": 2 },
                    "description": { "value": "Tropical climbing plant" }
                  }
                }
              ]
            },
            "disease": {
              "suggestions": [
                {
                  "id": "d1",
                  "name": "Leaf spot",
                  "probability": 0.42,
                  "details": {
                    "description": "Fungal lesions",
                    "treatment": {
                      "prevention": ["Improve airflow"],
                      "biological": ["Neem oil"],
                      "chemical": null
                    }
                  }
                }
              ]
            }
          }
        }
        """

        let data = try #require(fixture.data(using: .utf8))
        let response = try JSONDecoder().decode(PlantIdResponse.self, from: data)

        #expect(response.result.isPlant.probability == 0.98)
        #expect(response.result.classification.suggestions.first?.name == "Monstera deliciosa")
        #expect(response.result.classification.suggestions.first?.details?.commonNames == ["Swiss cheese plant"])
        #expect(response.result.disease?.suggestions.first?.probability == 0.42)
        #expect(response.result.disease?.suggestions.first?.details?.treatment?.biological == ["Neem oil"])
    }

    @Test func responseDecodesWhenDiseaseMissing() throws {
        let fixture = """
        {
          "result": {
            "is_plant": { "probability": 0.99 },
            "classification": { "suggestions": [] }
          }
        }
        """
        let data = try #require(fixture.data(using: .utf8))
        let response = try JSONDecoder().decode(PlantIdResponse.self, from: data)
        #expect(response.result.disease == nil)
        #expect(response.result.classification.suggestions.isEmpty)
    }

    // MARK: - Health assessment endpoint (separate Plant.id v3 endpoint)

    @Test func healthAssessmentDecodesBotrytisFixture() throws {
        // Real shape returned by /api/v3/health_assessment for a diseased Dahlia.
        let fixture = """
        {
          "result": {
            "is_healthy": { "binary": false, "probability": 0.10, "threshold": 0.5 },
            "disease": {
              "suggestions": [{
                "id": "abc",
                "name": "Botrytis",
                "probability": 0.5356,
                "details": {
                  "description": "Botrytis (gray mold) is a fungal disease...",
                  "treatment": {
                    "chemical": ["copper soap"],
                    "biological": ["improve airflow"],
                    "prevention": ["water in the morning"]
                  }
                }
              }]
            }
          }
        }
        """
        let data = try #require(fixture.data(using: .utf8))
        let response = try JSONDecoder().decode(HealthAssessmentResponse.self, from: data)
        #expect(response.result.isHealthy?.binary == false)
        #expect(response.result.disease?.suggestions.first?.name == "Botrytis")
        #expect(response.result.disease?.suggestions.first?.probability == 0.5356)
        #expect(response.result.disease?.suggestions.first?.details?.treatment?.prevention == ["water in the morning"])
    }

    @Test func healthAssessmentDecodesHealthyResponse() throws {
        let fixture = """
        {
          "result": {
            "is_healthy": { "binary": true, "probability": 0.92, "threshold": 0.5 }
          }
        }
        """
        let data = try #require(fixture.data(using: .utf8))
        let response = try JSONDecoder().decode(HealthAssessmentResponse.self, from: data)
        #expect(response.result.isHealthy?.binary == true)
        #expect(response.result.disease == nil)
    }

    // MARK: - AIError mapping (smoke)

    @Test func aiErrorLowConfidenceFormatsPercent() {
        let error = AIError.lowConfidence(0.42)
        #expect(error.errorDescription?.contains("42%") == true)
    }

    @Test func aiErrorUnknownIncludesStatusCode() {
        let error = AIError.unknownError(503)
        #expect(error.errorDescription?.contains("503") == true)
    }

    // MARK: - ResponseCache behavior

    @Test func responseCacheReturnsNilWhenEmpty() async {
        let cache = ResponseCache()
        let result = await cache.get(hash: "nope")
        #expect(result == nil)
    }

    @Test func responseCacheRoundtripsData() async {
        let cache = ResponseCache()
        let payload = Data("hello".utf8)
        await cache.set(hash: "key", data: payload)
        let result = await cache.get(hash: "key")
        #expect(result == payload)
    }

    @Test func responseCacheExpiresAfterTTL() async {
        let cache = ResponseCache(ttl: 0)
        await cache.set(hash: "key", data: Data("x".utf8))
        try? await Task.sleep(nanoseconds: 1_000_000)
        let result = await cache.get(hash: "key")
        #expect(result == nil)
    }
}
