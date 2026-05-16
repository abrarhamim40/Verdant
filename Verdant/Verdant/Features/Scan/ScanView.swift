//
//  ScanView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Day 8 deliverable: PhotosPicker-based multi-photo selection.
//  Day 9 will add live camera. Day 10-11 wires the "Identify" CTA to the AI pipeline.

import SwiftUI
import PhotosUI
import os

struct ScanView: View {
    static let maxPhotos = 3

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var photos: [ScanPhoto] = []
    @State private var isLoadingPhotos = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    photoArea
                    pickerButton
                    if !photos.isEmpty {
                        identifyButton
                        helperText
                    }
                }
                .padding(20)
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.large)
            .alert("Couldn't load photo", isPresented: errorBinding) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var photoArea: some View {
        if photos.isEmpty {
            emptyState
        } else {
            photoGrid
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.sage)
            Text("Snap your plant")
                .font(.title2.bold())
            Text("Pick 1–3 photos. Closer shots and varied angles give better diagnoses.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var photoGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(photos) { photo in
                    ScanPhotoCard(photo: photo, onRemove: { remove(photo) })
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var pickerButton: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: Self.maxPhotos,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack(spacing: 8) {
                Image(systemName: isLoadingPhotos ? "hourglass" : "photo.on.rectangle.angled")
                Text(pickerButtonLabel)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.sage.opacity(0.18))
            .foregroundStyle(Color.forestGreen)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isLoadingPhotos)
        .onChange(of: pickerItems) { _, newItems in
            Task { await loadPhotos(from: newItems) }
        }
    }

    private var identifyButton: some View {
        Button {
            // Day 10-11 wires this to AIService + ScanningView.
            // For now, surface a placeholder so we can verify the path end-to-end visually.
            errorMessage = "Identify pipeline lands Day 10-11. Photo data is ready (\(photos.count) optimized image\(photos.count == 1 ? "" : "s"))."
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                Text("Identify Plant")
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.forestGreen)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .disabled(isLoadingPhotos)
    }

    private var helperText: some View {
        Text(photos.count >= Self.maxPhotos
             ? "Maximum 3 photos reached. Tap × to swap one out."
             : "\(photos.count) of \(Self.maxPhotos) selected. Add more for higher accuracy.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Computed

    private var pickerButtonLabel: String {
        if isLoadingPhotos { return "Processing…" }
        if photos.isEmpty { return "Choose Photos" }
        return "Change Selection"
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    // MARK: - Photo loading

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        isLoadingPhotos = true
        defer { isLoadingPhotos = false }

        var loaded: [ScanPhoto] = []
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data),
                      let optimized = uiImage.optimizeForAPI() else {
                    Logger.ui.error("Failed to load or optimize a selected photo")
                    continue
                }
                loaded.append(ScanPhoto(
                    pickerItem: item,
                    optimizedData: optimized,
                    displayImage: uiImage
                ))
            } catch {
                Logger.ui.error("PhotosPicker load error: \(error.localizedDescription, privacy: .public)")
                errorMessage = "Some photos could not be loaded. Try picking them again."
            }
        }

        photos = loaded
    }

    private func remove(_ photo: ScanPhoto) {
        photos.removeAll { $0.id == photo.id }
        pickerItems.removeAll { $0 == photo.pickerItem }
    }
}

// MARK: - Photo card

private struct ScanPhotoCard: View {
    let photo: ScanPhoto
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: photo.displayImage)
                .resizable()
                .scaledToFill()
                .frame(width: 140, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.6))
            }
            .padding(6)
            .accessibilityLabel("Remove photo")
        }
    }
}

// MARK: - Data type

struct ScanPhoto: Identifiable {
    let id: UUID
    let pickerItem: PhotosPickerItem
    let optimizedData: Data
    let displayImage: UIImage

    init(id: UUID = UUID(), pickerItem: PhotosPickerItem, optimizedData: Data, displayImage: UIImage) {
        self.id = id
        self.pickerItem = pickerItem
        self.optimizedData = optimizedData
        self.displayImage = displayImage
    }
}

#Preview {
    ScanView()
}
