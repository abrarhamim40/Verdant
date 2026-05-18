//
//  AppleVisionServiceTests.swift
//  VerdantTests
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Vision request execution itself can't be unit tested without bundled image
//  fixtures, but the keyword-matching logic is pure and worth covering — it's
//  the difference between "blocks bad photos" and "blocks valid scans".

import Testing
import Foundation
@testable import Verdant

struct AppleVisionServiceTests {

    @Test func detectsObviousPlantLabel() {
        let classifications: [(String, Float)] = [
            ("plant", 0.92),
            ("outdoor", 0.40)
        ]
        #expect(AppleVisionService.detectsPlant(in: classifications))
    }

    @Test func detectsHierarchicalLabel() {
        // Vision sometimes returns "plant > flower > rose" or "leaf vegetable" etc.
        let classifications: [(String, Float)] = [
            ("leaf vegetable", 0.81),
            ("food", 0.60)
        ]
        #expect(AppleVisionService.detectsPlant(in: classifications))
    }

    @Test func rejectsObviouslyNonPlant() {
        let classifications: [(String, Float)] = [
            ("cat", 0.95),
            ("indoor", 0.60),
            ("furniture", 0.55)
        ]
        #expect(AppleVisionService.detectsPlant(in: classifications) == false)
    }

    @Test func ignoresLowConfidenceMatches() {
        // Below threshold (0.15) should not pass even if the label is plant-y.
        let classifications: [(String, Float)] = [
            ("plant", 0.08),
            ("indoor", 0.92)
        ]
        #expect(AppleVisionService.detectsPlant(in: classifications) == false)
    }

    @Test func detectsFloraTopLevelLabel() {
        // Vision's bundled taxonomy uses "flora" / "botanical" as common top-level
        // labels for plant photos — these previously slipped through and got rejected.
        let classifications: [(String, Float)] = [
            ("flora", 0.42),
            ("outdoor", 0.30)
        ]
        #expect(AppleVisionService.detectsPlant(in: classifications))
    }

    @Test func detectsSucculentSpecifically() {
        let classifications: [(String, Float)] = [
            ("succulent", 0.65),
            ("pot", 0.40)
        ]
        #expect(AppleVisionService.detectsPlant(in: classifications))
    }

    @Test func detectsCaseInsensitive() {
        let classifications: [(String, Float)] = [
            ("FLOWER", 0.71)
        ]
        #expect(AppleVisionService.detectsPlant(in: classifications))
    }

    @Test func emptyClassificationsReturnFalse() {
        #expect(AppleVisionService.detectsPlant(in: []) == false)
    }

    @Test func plantKeywordsContainsExpectedCoreSet() {
        // Sanity: the keyword set should at minimum cover the obvious terms.
        for keyword in ["plant", "flower", "leaf", "tree", "succulent", "cactus"] {
            #expect(AppleVisionService.plantKeywords.contains(keyword))
        }
    }
}
