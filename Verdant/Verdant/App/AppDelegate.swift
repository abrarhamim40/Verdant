//
//  AppDelegate.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/19/26.
//
//  Tiny UIKit adapter for two purposes:
//
//  1. Set ourselves as UNUserNotificationCenter.delegate so local
//     notifications keep firing even when the app is in the foreground —
//     iOS suppresses banners by default; willPresent has to return them.
//
//  2. Set the delegate before any notification arrives so a notification
//     received during a launch (e.g. tapped while app was killed) is handed
//     to didReceive instead of dropped.

import SwiftUI
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// Called when a notification fires while the app is in the foreground.
    /// Without this, iOS swallows the banner because the app is already on
    /// screen. We opt into the full presentation so users get the same
    /// feedback regardless of whether they're scrolling Verdant or somewhere else.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    /// Called when the user taps a notification (background, foreground, or
    /// killed). Day 31-32+ wiring can route the userInfo["reminderID"] back
    /// to PlantDetailView; for now we just acknowledge so iOS marks it
    /// handled and clears it from the lock screen.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
