//
//  ScanView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Day 8 deliverable: PhotosPicker-based multi-photo selection.
//  Day 9 added live camera capture + photo guidance overlay.
//  Day 10-11 will wire the "Identify" CTA to the AI pipeline.

import SwiftUI
import PhotosUI
import os

struct ScanView: View {
    static let maxPhotos = 3

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var photos: [ScanPhoto] = []
    @State private var isLoadingPhotos = false
    @State private var showCamera = false
    @State private var showTipsSheet = false
    @State private var errorMessage: String?
    @State private var activeScan: ScanRequest?

    // Blueprint §4 monetisation gate. AdGateway is the dev-mock; Week 6 swaps in
    // the real AdMob-backed GADRewardedAdGateway with the same signature.
    @ObservedObject private var entitlement = Entitlement.shared
    @State private var adGateway: any AdGateway = MockAdGateway()
    @State private var showAdWall = false
    @State private var pendingScanRequest: ScanRequest?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    scansRemainingBadge
                    photoArea
                    captureButtons
                    if !photos.isEmpty {
                        identifyButton
                        helperText
                    }
                }
                .padding(20)
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .navigationDestination(item: $activeScan) { request in
                ScanningView(request: request)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(
                    onCapture: { image in
                        showCamera = false
                        Task { await appendCapturedImage(image) }
                    },
                    onCancel: { showCamera = false }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showTipsSheet) {
                NavigationStack {
                    ScrollView {
                        PhotoGuidanceTips()
                            .padding(20)
                    }
                    .navigationTitle("Photo Tips")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showTipsSheet = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .alert("Couldn't load photo", isPresented: errorBinding) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showAdWall) {
                AdWallSheet(
                    adGateway: adGateway,
                    onUnlock: {
                        entitlement.grantAdUnlock()
                        showAdWall = false
                        if let pending = pendingScanRequest {
                            activeScan = pending
                            pendingScanRequest = nil
                        }
                    },
                    onCancel: {
                        showAdWall = false
                        pendingScanRequest = nil
                    }
                )
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showTipsSheet = true
            } label: {
                Image(systemName: "lightbulb")
            }
            .accessibilityLabel("Photo tips")
        }
        #if DEBUG
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Section("Quota") {
                    Button("Burn 1 free scan") { entitlement.recordScanCompleted() }
                    Button("Reset all counters") { entitlement._debugResetCounters() }
                }
                Section("Tokens") {
                    Button("Grant ad unlock") { entitlement.grantAdUnlock() }
                }
                Section("Weekly cap") {
                    Button("Max out weekly cap") { entitlement._debugMaxOutWeeklyCap() }
                }
                Section("Tier") {
                    Button(entitlement.isPremium ? "Downgrade to Free" : "Upgrade to Premium") {
                        entitlement.setPremium(!entitlement.isPremium)
                    }
                }
            } label: {
                Image(systemName: "ladybug.fill")
                    .foregroundStyle(.orange)
            }
            .accessibilityLabel("Debug menu")
        }
        #endif
    }

    // MARK: - Photo area

    @ViewBuilder
    private var photoArea: some View {
        if photos.isEmpty {
            VStack(spacing: 20) {
                emptyHeader
                PhotoGuidanceTips()
            }
        } else {
            photoGrid
        }
    }

    private var emptyHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color.sage)
            Text("Snap your plant")
                .font(.title2.bold())
            Text("Pick 1–3 photos. Closer shots and varied angles give better diagnoses.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
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

    // MARK: - Capture buttons

    private var captureButtons: some View {
        HStack(spacing: 12) {
            cameraButton
            libraryPicker
        }
    }

    private var cameraButton: some View {
        Button {
            showCamera = true
        } label: {
            captureButtonLabel(icon: "camera.fill", text: "Camera")
        }
        .disabled(isLoadingPhotos || photos.count >= Self.maxPhotos)
    }

    private var libraryPicker: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: Self.maxPhotos,
            matching: .images,
            photoLibrary: .shared()
        ) {
            captureButtonLabel(
                icon: isLoadingPhotos ? "hourglass" : "photo.on.rectangle.angled",
                text: isLoadingPhotos ? "Loading…" : "Library"
            )
        }
        .disabled(isLoadingPhotos)
        .onChange(of: pickerItems) { _, newItems in
            Task { await loadPhotos(from: newItems) }
        }
    }

    private func captureButtonLabel(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .font(.body.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color.sage.opacity(0.18))
        .foregroundStyle(Color.forestGreen)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Identify

    private var identifyButton: some View {
        Button {
            startScan()
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

    /// Permission gate before triggering an actual scan navigation. Free users with
    /// quota or a valid ad-unlock proceed straight to ScanningView; users at the
    /// monthly quota wall but still under the weekly ad-unlock cap stash the request
    /// and the AdWallSheet drives the rest; users who've hit the weekly cap get an
    /// alert pointing them at Pro or "wait until Monday".
    private func startScan() {
        Haptics.impact(.medium)
        let imagesData = photos.map(\.optimizedData)
        let request = ScanRequest(images: imagesData)

        switch entitlement.currentPermission() {
        case .allowed:
            activeScan = request
        case .requiresAds:
            pendingScanRequest = request
            showAdWall = true
        case .weeklyCapReached:
            Haptics.warning()
            errorMessage = "You've used your \(entitlement.weeklyAdUnlockCap) ad-unlocked scans this week. Upgrade to Pro for unlimited scans, or wait until next Monday."
        }
    }

    private var helperText: some View {
        Text(photos.count >= Self.maxPhotos
             ? "Maximum 3 photos. Tap × to swap one out."
             : "\(photos.count) of \(Self.maxPhotos) selected. Add more for higher accuracy.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    /// Always-visible status pill so a fresh free user sees their budget on first
    /// open, not only after they've selected photos. Premium users see no pill.
    /// Three states: free quota left → ad-unlock available this week → weekly cap hit.
    @ViewBuilder
    private var scansRemainingBadge: some View {
        if !entitlement.isPremium {
            let info = badgeContent
            HStack(spacing: 6) {
                Image(systemName: info.icon)
                Text(info.label)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(info.color.opacity(0.14))
            .foregroundStyle(info.color)
            .clipShape(Capsule())
            .accessibilityLabel(info.accessibility)
        }
    }

    private var badgeContent: (icon: String, label: String, color: Color, accessibility: String) {
        let remaining = entitlement.remainingFreeScans
        if remaining > 0 {
            return (
                icon: "leaf.fill",
                label: "\(remaining) free scan\(remaining == 1 ? "" : "s") left this month",
                color: Color.forestGreen,
                accessibility: "\(remaining) free scans remaining this month"
            )
        }
        // Quota exhausted. Either ads are still an option, or the weekly cap is hit.
        switch entitlement.currentPermission() {
        case .weeklyCapReached:
            return (
                icon: "lock.fill",
                label: "Weekly cap reached — upgrade or wait until Monday",
                color: Color.terracotta,
                accessibility: "You've used your weekly ad-unlocked scans. Upgrade to Pro or wait until next Monday."
            )
        default:
            let left = entitlement.remainingAdUnlocksThisWeek
            return (
                icon: "play.rectangle.fill",
                label: left == 1 ? "1 ad-unlock left this week" : "Watch 2 ads to scan (\(left) left this week)",
                color: Color.terracotta,
                accessibility: "Free quota used. \(left) ad-unlocked scans available this week."
            )
        }
    }

    // MARK: - Bindings

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    // MARK: - Photo loading

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else {
            withAnimation(.easeInOut(duration: 0.25)) { photos.removeAll() }
            return
        }

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

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            photos = loaded
        }
        if !loaded.isEmpty { Haptics.selection() }
    }

    private func appendCapturedImage(_ image: UIImage) async {
        guard photos.count < Self.maxPhotos else { return }
        guard let optimized = image.optimizeForAPI() else {
            Haptics.error()
            errorMessage = "Couldn't process that photo. Try again with better lighting."
            return
        }

        let captured = ScanPhoto(
            pickerItem: nil,
            optimizedData: optimized,
            displayImage: image
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            photos.append(captured)
        }
        Haptics.selection()
    }

    private func remove(_ photo: ScanPhoto) {
        Haptics.selection()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            photos.removeAll { $0.id == photo.id }
        }
        if let item = photo.pickerItem {
            pickerItems.removeAll { $0 == item }
        }
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
    let pickerItem: PhotosPickerItem?
    let optimizedData: Data
    let displayImage: UIImage

    init(
        id: UUID = UUID(),
        pickerItem: PhotosPickerItem?,
        optimizedData: Data,
        displayImage: UIImage
    ) {
        self.id = id
        self.pickerItem = pickerItem
        self.optimizedData = optimizedData
        self.displayImage = displayImage
    }
}

#Preview {
    ScanView()
}
