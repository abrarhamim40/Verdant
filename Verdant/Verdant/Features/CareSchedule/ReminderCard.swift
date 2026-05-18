//
//  ReminderCard.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/19/26.
//
//  Day 31-32 — single row in the ScheduleView. Shows the plant photo, the
//  type-coded icon, the plant nickname, when it's due, and a mark-done action
//  that runs the CareReminder model's markCompleted() and reschedules the
//  notification through NotificationService.

import SwiftUI
import SwiftData
import os

struct ReminderCard: View {
    @Bindable var reminder: CareReminder

    @Environment(\.modelContext) private var modelContext

    @State private var isCompleting = false

    var body: some View {
        HStack(spacing: 12) {
            plantThumbnail
            details
            Spacer(minLength: 0)
            doneButton
        }
        .padding(12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var plantThumbnail: some View {
        ZStack(alignment: .bottomTrailing) {
            photoOrPlaceholder
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Small floating type icon on the bottom-right corner of the photo.
            Image(systemName: typeIcon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(5)
                .background(typeTint)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.backgroundPrimary, lineWidth: 2))
                .offset(x: 4, y: 4)
        }
    }

    @ViewBuilder
    private var photoOrPlaceholder: some View {
        if let data = reminder.plant?.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color.sage.opacity(0.25)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color.forestGreen)
            }
        }
    }

    // MARK: - Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(reminder.plant?.displayName ?? "Unknown plant")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(typeLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(typeTint)

            HStack(spacing: 6) {
                Text(dueLabel)
                    .font(.caption)
                    .foregroundStyle(reminder.isOverdue ? Color.terracotta : .secondary)
                if reminder.streak >= 2 {
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Label("\(reminder.streak)", systemImage: "flame.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.terracotta)
                }
            }
        }
    }

    // MARK: - Done button

    private var doneButton: some View {
        Button {
            markComplete()
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.forestGreen.opacity(0.5), lineWidth: 2)
                    .frame(width: 36, height: 36)
                if isCompleting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color.forestGreen)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isCompleting)
        .accessibilityLabel("Mark \(typeLabel.lowercased()) done")
    }

    // MARK: - Background

    private var cardBackground: some View {
        Group {
            if reminder.isOverdue {
                Color.terracotta.opacity(0.10)
            } else {
                Color.sage.opacity(0.10)
            }
        }
    }

    // MARK: - Mapping

    private var typeLabel: String {
        switch reminder.type {
        case "watering":    return "Water"
        case "fertilizing": return "Fertilize"
        case "pruning":     return "Prune"
        case "misting":     return "Mist"
        default:            return reminder.type.capitalized
        }
    }

    private var typeIcon: String {
        switch reminder.type {
        case "watering":    return "drop.fill"
        case "fertilizing": return "sparkles"
        case "pruning":     return "scissors"
        case "misting":     return "humidity.fill"
        default:            return "leaf.fill"
        }
    }

    private var typeTint: Color {
        switch reminder.type {
        case "watering":    return Color.forestGreen
        case "fertilizing": return Color.terracotta
        case "pruning":     return Color.sage
        case "misting":     return Color.sage
        default:            return Color.forestGreen
        }
    }

    private var dueLabel: String {
        if reminder.isOverdue {
            let days = abs(reminder.daysUntilDue)
            return days == 0 ? "Due today" : "\(days)d overdue"
        }
        let days = reminder.daysUntilDue
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        return "Due in \(days)d"
    }

    // MARK: - Action

    private func markComplete() {
        guard !isCompleting else { return }
        isCompleting = true
        Haptics.success()

        // Snapshot the values BEFORE markCompleted() shifts nextDue forward.
        let plantName = reminder.plant?.displayName ?? "Unknown plant"
        let reminderID = reminder.id
        let type = reminder.type

        reminder.markCompleted()

        do {
            try modelContext.save()
            Logger.data.info("Completed \(type, privacy: .public) for \(plantName, privacy: .public)")
        } catch {
            Logger.data.error("markCompleted save failed: \(error.localizedDescription, privacy: .public)")
            Haptics.error()
            isCompleting = false
            return
        }

        let newDue = reminder.nextDue
        let isEnabled = reminder.isEnabled
        Task {
            await NotificationService.shared.schedule(
                reminderID: reminderID,
                type: type,
                plantName: plantName,
                nextDue: newDue,
                isEnabled: isEnabled
            )
            await MainActor.run { isCompleting = false }
        }
    }
}
