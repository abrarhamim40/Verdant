//
//  MockAdGatewayTests.swift
//  VerdantTests
//
//  Created by Abrar Hamim on 5/20/26.
//

import Testing
import Foundation
@testable import Verdant

@MainActor
struct MockAdGatewayTests {

    @Test func defaultConfigResolvesToTrue() async {
        let gateway = MockAdGateway(simulatedTotalDelay: .milliseconds(5))
        let granted = await gateway.presentDoubleAdWall()
        #expect(granted == true)
    }

    @Test func simulatedFailureResolvesToFalse() async {
        let gateway = MockAdGateway(simulatedTotalDelay: .milliseconds(5), simulatedSuccess: false)
        let granted = await gateway.presentDoubleAdWall()
        #expect(granted == false)
    }

    @Test func cancellationMidWatchResolvesToFalse() async {
        // 5 s simulated watch but we cancel almost immediately.
        let gateway = MockAdGateway(simulatedTotalDelay: .seconds(5))
        let task = Task { await gateway.presentDoubleAdWall() }
        task.cancel()
        let granted = await task.value
        #expect(granted == false)
    }

    @Test func delayIsRespected() async {
        // Verify the gateway actually awaits the configured delay — not strict timing
        // (CI variance), just that we waited at least most of it.
        let gateway = MockAdGateway(simulatedTotalDelay: .milliseconds(120))
        let started = ContinuousClock.now
        _ = await gateway.presentDoubleAdWall()
        let elapsed = ContinuousClock.now - started
        #expect(elapsed >= .milliseconds(100))
    }
}
