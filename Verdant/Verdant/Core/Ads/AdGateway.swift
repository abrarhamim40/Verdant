//
//  AdGateway.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/20/26.
//
//  Abstraction over the Double-Ad Wall mechanism (blueprint §4.2).
//  The real implementation will live in GADRewardedAdGateway.swift backed by
//  AdMob's GADRewardedAd. This protocol lets ScanView + Entitlement run against
//  a MockAdGateway during development and Week 6's eventual AdMob integration.

import Foundation

@MainActor
protocol AdGateway: AnyObject {
    /// Show two consecutive rewarded video ads. Resolves to `true` ONLY if both
    /// ads completed their reward callback. Any error, cancellation, partial
    /// completion, or network failure resolves to `false`.
    ///
    /// On success the caller should call `Entitlement.shared.grantAdUnlock()`;
    /// on failure no entitlement is granted and the user can retry.
    func presentDoubleAdWall() async -> Bool
}
