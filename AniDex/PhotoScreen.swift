import SwiftUI
import UIKit
import AVFoundation
import PhotosUI
import UniformTypeIdentifiers

private enum CameraAlertContext {
    case none
    case notDetermined
    case unavailable
    case deniedOrRestricted
}

struct PhotoScreen: View {
    @State private var selectedTab: MenuTab = .photo
    @State private var isShowingCamera = false
    @State private var isShowingPhotoPicker = false
    @State private var capturedImage: UIImage?
    @State private var savedImageURL: URL?
    @State private var showCameraAlert = false
    @State private var cameraAlertTitle = ""
    @State private var cameraAlertMessage = ""
    @State private var cameraAlertContext: CameraAlertContext = .none

    var body: some View {
        ZStack() {
            if selectedTab == .photo {
                // Main placeholder content
                VStack(alignment:.center, spacing: 12) {
                    Spacer()
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        if let url = savedImageURL {
                            Text("Saved: \(url.lastPathComponent)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                        Text("Take or upload a photo to identify")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Floating action buttons (lower-right)
                VStack(alignment: .trailing, spacing: 12) {
                    Spacer()
                    Button {
                        handleTakePhotoTapped()
                    } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.tint, in: Capsule())
                            .foregroundStyle(.white)
                    }

                    Button {
                        isShowingPhotoPicker = true
                    } label: {
                        Label("Upload Photo", systemImage: "photo.fill.on.rectangle.fill")
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    
                }
                .padding(.trailing, -200)
                .padding(.bottom,4)
            } else {
                AniDexScreen(selectedTab: $selectedTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Title block under the island / status bar
        .safeAreaInset(edge: .top) {
            TitleBlock()
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .background(.thinMaterial)
        }
        // Bottom menu bar
        .safeAreaInset(edge: .bottom) {
            BottomMenuBar(selected: $selectedTab)
        }
        // Present native camera
        .sheet(isPresented: $isShowingCamera) {
            CameraPicker(image: $capturedImage, isPresented: $isShowingCamera)
        }
        // Present native photo library (PHPicker)
        .sheet(isPresented: $isShowingPhotoPicker) {
            PhotoLibraryPicker(image: $capturedImage, isPresented: $isShowingPhotoPicker)
        }
        // Alerts for camera unavailability or permission issues
        .alert(cameraAlertTitle, isPresented: $showCameraAlert) {
            Button("OK", role: .cancel) { handleCameraAlertOkTapped() }
            Button("Allow") { handleCameraAlertAllowTapped() }
                .disabled(!isAllowEnabledForCurrentAlert())
        } message: {
            Text(cameraAlertMessage)
        }
        // Save captured image into app storage
        .onChange(of: capturedImage) { newImage in
            guard let image = newImage else { return }
            savedImageURL = saveImageToAppFolder(image)
        }
    }
}

private struct TitleBlock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AniDex")
                .font(.title.bold())
            Text("Identify animals and plants from photos")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Divider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum MenuTab {
    case photo
    case anidex
}

struct BottomMenuBar: View {
    @Binding var selected: MenuTab

    var body: some View {
        HStack(spacing: 0) {
            menuButton(.photo, title: "Photo", systemImage: "camera")
            Divider()
            menuButton(.anidex, title: "AniDex", systemImage: "list.bullet")
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: 60)
        .background(.thinMaterial)
    }

    @ViewBuilder
    private func menuButton(_ tab: MenuTab, title: String, systemImage: String) -> some View {
        let isSelected = (tab == selected)
        Button {
            selected = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Save to App Storage

private extension PhotoScreen {
    func handleTakePhotoTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraAlertTitle = "Camera Unavailable"
            cameraAlertMessage = "This device does not have a camera."
            cameraAlertContext = .unavailable
            showCameraAlert = true
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isShowingCamera = true
        case .notDetermined:
            cameraAlertTitle = "Camera Permission"
            cameraAlertMessage = "This App needs camera access to take photos."
            cameraAlertContext = .notDetermined
            showCameraAlert = true
        case .denied, .restricted:
            cameraAlertTitle = "Camera Access Denied"
            cameraAlertMessage = "Enable camera access in Settings > Privacy > Camera to take photos."
            cameraAlertContext = .deniedOrRestricted
            showCameraAlert = true
        @unknown default:
            cameraAlertTitle = "Camera Error"
            cameraAlertMessage = "An unknown camera permission status occurred."
            showCameraAlert = true
        }
    }

    func saveImageToAppFolder(_ image: UIImage) -> URL? {
        let fm = FileManager.default
        guard var baseURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        // Create subdirectory
        baseURL.appendPathComponent("CapturedPhotos", isDirectory: true)
        do {
            try fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
            var dirValues = URLResourceValues()
            dirValues.isExcludedFromBackup = true
            try? baseURL.setResourceValues(dirValues)
        } catch {
            print("Failed to create directory: \(error)")
            return nil
        }

        // Generate file name
        let filename = "IMG_\(UUID().uuidString).jpg"
        var fileURL = baseURL.appendingPathComponent(filename, isDirectory: false)

        // Encode image data
        guard let data = image.jpegData(compressionQuality: 0.9) ?? image.pngData() else {
            return nil
        }
        do {
            try data.write(to: fileURL, options: .atomic)
            var fileValues = URLResourceValues()
            fileValues.isExcludedFromBackup = true
            try? fileURL.setResourceValues(fileValues)
            return fileURL
        } catch {
            print("Failed to write image: \(error)")
            return nil
        }
    }

    // MARK: - Alert Helpers
    func handleCameraAlertOkTapped() {
        switch cameraAlertContext {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        isShowingCamera = true
                    } else {
                        cameraAlertTitle = "Camera Access Denied"
                        cameraAlertMessage = "Enable camera access in Settings > Privacy > Camera to take photos."
                        cameraAlertContext = .deniedOrRestricted
                        showCameraAlert = true
                    }
                }
            }
        default:
            break
        }
        cameraAlertContext = .none
    }

    func handleCameraAlertAllowTapped() {
        if cameraAlertContext == .deniedOrRestricted {
            openAppSettings()
        }
    }

    func isAllowEnabledForCurrentAlert() -> Bool {
        cameraAlertContext == .deniedOrRestricted
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Camera Picker Wrapper

private struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        }
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Photo Library Picker Wrapper

private struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        init(_ parent: PhotoLibraryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            defer { DispatchQueue.main.async { self.parent.isPresented = false } }
            guard let provider = results.first?.itemProvider else { return }
            // Prefer loading raw data to avoid sending non-Sendable objects across threads.
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                    guard let data = data, let uiImage = UIImage(data: data) else { return }
                    DispatchQueue.main.async {
                        self.parent.image = uiImage
                    }
                }
            }
        }
    }
}

#Preview {
    PhotoScreen()
}
