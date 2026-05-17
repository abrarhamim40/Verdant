//
//  ScanningView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Full-screen progress + result UI for one scan. Owns the AIService Task,
//  surfaces cancellation, and renders a placeholder result on success.
//  Day 12-13 will swap the result block for the full DiagnosisResultView.

import SwiftUI
import os

struct ScanningView: View {
    let request: ScanRequest

    @State private var state: ScanState = .running
    @State private var task: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch state {
            case .running:
                runningView
            case .success(let result):
                successView(result)
            case .failure(let error):
                failureView(error)
            case .cancelled:
                cancelledView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationBarBackButtonHidden(state == .running)
        .toolbar { toolbarContent }
        .task(id: request.id) { await runScan() }
        .onDisappear { task?.cancel() }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if state == .running {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel", role: .cancel) {
                    cancelScan()
                }
            }
        }
    }

    // MARK: - Running

    private var runningView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 96, weight: .light))
                .foregroundStyle(Color.sage)
                .symbolEffect(.pulse, options: .repeating)

            TimelineView(.periodic(from: .now, by: 2.5)) { context in
                let idx = Int(context.date.timeIntervalSinceReferenceDate / 2.5) % Self.statusMessages.count
                VStack(spacing: 12) {
                    Text(Self.statusMessages[idx])
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .id(idx)
                        .transition(.opacity)
                    Text("Usually 5–15 seconds")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .animation(.easeInOut(duration: 0.4), value: idx)
            }

            ProgressView()
                .controlSize(.large)
                .tint(Color.forestGreen)

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Success → full diagnosis screen

    private func successView(_ result: PlantAnalysisResult) -> some View {
        DiagnosisResultView(
            result: result,
            primaryPhotoData: request.images.first,
            photoCount: request.images.count
        )
    }

    // MARK: - Failure

    private func failureView(_ error: AIError) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: iconForError(error))
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Color.terracotta)

            VStack(spacing: 10) {
                Text(error.errorDescription ?? "Something went wrong")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                if let recovery = error.recoveryAction {
                    Text(recovery)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Button {
                    state = .running
                    Task { await runScan() }
                } label: {
                    Text("Try again")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.forestGreen)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button("Back to photos") {
                    dismiss()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func iconForError(_ error: AIError) -> String {
        switch error {
        case .noPlantDetected, .imageUnclear, .compressionFailed:
            return "leaf.fill"
        case .networkError, .rateLimited, .serverError:
            return "wifi.exclamationmark"
        case .invalidAPIKey:
            return "key.slash"
        default:
            return "exclamationmark.triangle"
        }
    }

    // MARK: - Cancelled

    private var cancelledView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "xmark.circle")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.secondary)
            Text("Scan cancelled")
                .font(.title3.weight(.semibold))
            Button("Back to photos") {
                dismiss()
            }
            .foregroundStyle(Color.forestGreen)
            Spacer()
        }
    }

    // MARK: - Logic

    private func runScan() async {
        task = Task {
            do {
                let result = try await AIService.shared.analyzePlant(
                    images: request.images,
                    location: request.coordinate,
                    language: request.language,
                    climate: nil
                )
                if !Task.isCancelled {
                    state = .success(result)
                }
            } catch is CancellationError {
                state = .cancelled
            } catch let error as AIError {
                Logger.ai.error("Scan failed: \(error.localizedDescription, privacy: .public)")
                state = .failure(error)
            } catch {
                Logger.ai.error("Scan failed (unknown): \(error.localizedDescription, privacy: .public)")
                state = .failure(.unknownError(0))
            }
        }
        await task?.value
    }

    private func cancelScan() {
        task?.cancel()
        state = .cancelled
    }

    // MARK: - Cycling messages

    static let statusMessages = [
        "Checking your image…",
        "Identifying the plant…",
        "Generating your care plan…",
        "Almost there…"
    ]
}

// MARK: - State

enum ScanState: Equatable {
    case running
    case success(PlantAnalysisResult)
    case failure(AIError)
    case cancelled

    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.running, .running), (.cancelled, .cancelled): return true
        case (.success(let l), .success(let r)): return l.id == r.id
        case (.failure(let l), .failure(let r)): return l == r
        default: return false
        }
    }
}
