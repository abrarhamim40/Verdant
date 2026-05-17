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

    // MARK: - Success (Day 12-13 placeholder)

    private func successView(_ result: PlantAnalysisResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.plantName)
                        .font(.largeTitle.bold())
                    if let scientific = result.scientificName {
                        Text(scientific)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(result.confidencePercent)% confidence")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(confidenceColor(result).opacity(0.18))
                        .foregroundStyle(confidenceColor(result))
                        .clipShape(Capsule())
                }

                if result.needsExpertReview {
                    expertReviewWarning
                }

                if let disease = result.disease, result.hasDiseaseDetected {
                    diseaseSection(disease)
                }

                treatmentSection(result.treatment)

                Text("Full diagnosis screen lands Day 12-13.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
            }
            .padding(20)
        }
    }

    private func confidenceColor(_ result: PlantAnalysisResult) -> Color {
        if result.isHighConfidence { return .forestGreen }
        if result.needsExpertReview { return .terracotta }
        return .sage
    }

    private var expertReviewWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.terracotta)
            Text("Confidence is low. Consider retaking with multiple angles.")
                .font(.subheadline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.terracotta.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func diseaseSection(_ disease: DiseaseSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Possible issue", systemImage: "cross.case.fill")
                .font(.headline)
            Text(disease.name)
                .font(.title3.weight(.semibold))
            Text("\(Int(disease.probability * 100))% likely")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let description = disease.details?.description {
                Text(description)
                    .font(.body)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.terracotta.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func treatmentSection(_ plan: TreatmentPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Care plan", systemImage: "drop.fill")
                .font(.headline)
                .foregroundStyle(Color.forestGreen)
            Text(plan.summary)
                .font(.body)
            HStack(spacing: 16) {
                FrequencyChip(icon: "drop", days: plan.wateringFrequencyDays, label: "water")
                FrequencyChip(icon: "sparkles", days: plan.fertilizingFrequencyDays, label: "feed")
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sage.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

// MARK: - Frequency chip

private struct FrequencyChip: View {
    let icon: String
    let days: Int
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(Color.forestGreen)
            Text("Every \(days) days")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
        .clipShape(Capsule())
        .accessibilityLabel("\(label) every \(days) days")
    }
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
