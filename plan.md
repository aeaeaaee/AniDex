In this App, we will use the Foundation Model and Visual Intelligence package of iOS 26 to develop an app that identify an animal or plant , given a photo or user-taken photo of the animal or plant..

- Target iOS Version: iOS 26
- App purpose : Identify an animal or plant , given a photo or user-taken photo of the animal or plant. Then record it at AniDex.
- App name : AniDex
- Multi language is supported

## 0) Purpose
This living document defines the product requirements, scope, and technical plan for AniDex — an iOS 26 app that identifies an animal or plant from a user photo (camera or library) using on-device Foundation Model and the Visual Intelligence package, and records it in the user's AniDex. We will iterate on this plan as decisions are made.

## Direction Update (iOS 26 Nature Identifier)
- Target iOS Version: iOS 26
- App name: AniDex
- App purpose: Identify an animal or plant from a photo and record it in AniDex.
- Multi-language: Supported

## App Features (Draft)
- Photo
  - Take a photo or upload from the photo library. Two buttons: Take Photo, Upload Photo.
- AniDex
  - View all identified animals/plants.
  - Sort entries.
  - Delete entries.
  - Each item includes:
    - Name
    - Description
    - Scientific Name
    - Family (similar/related taxa)
    - 1 interesting fact
    - Photo location if available (MapKit shows coordinates)

## App Features

The app has two tabs:
- Photo
  - Take Photo (camera) or Upload Photo (photo library)
  - Classify the subject on-device using the iOS 26 Foundation Model via Visual Intelligence
  - Show top prediction(s) with confidence and allow user confirmation/edit
- AniDex
  - View all identified animals/plants
  - Sort by Name, Date Added, Family
  - Delete entries (with confirmation)
  - Each item stores: Name, Scientific Name, Family, Description, 1 Interesting Fact, Photo, Location (if available), Created Date

## Architecture & Tech Stack
- UI: SwiftUI
- Pattern: MVVM with async/await
- Classification: On-device model via Apple frameworks (Foundation Model / Visual Intelligence) for image understanding
- Persistence: SwiftData (iOS 26) for local store of observations and media file URLs
- Images: Store original in app container (FileManager) and generate a thumbnail
- Location & Map: CoreLocation for coordinates (optional, when permitted) + MapKit for display
- Permissions: Camera, Photo Library (read), Photo Library Add (write, if needed), Location When In Use

## Data Model (initial)
- Observation
  - id: UUID
  - createdAt: Date
  - imageFileURL: URL (to app-managed copy)
  - name: String (common name)
  - scientificName: String?
  - family: String?
  - description: String?
  - interestingFact: String?
  - latitude: Double? / longitude: Double?

## Permissions (Info.plist keys to add)
- NSCameraUsageDescription — "This app uses the camera to identify animals/plants from photos."
- NSPhotoLibraryUsageDescription — "This app needs photo library access to select photos for identification."
- NSPhotoLibraryAddUsageDescription — "This app may save processed images to your library."
- NSLocationWhenInUseUsageDescription — "This app uses your location to tag where observations were made."

## Acceptance Criteria (samples)
- Photo Capture/Upload
  - After selecting or capturing a photo, the app returns the top classification within 2s on-device for common cases.
  - If classification is uncertain, show multiple candidates and allow manual edit.
- Saving to AniDex
  - When the user confirms, an Observation is saved with image, fields, and optional location; it appears at the top of AniDex.
- Deletion & Sorting
  - Deleting an item removes it from the list and storage; sorting by Name/Date/Family updates immediately.

## Navigation
- TabView with two tabs: Photo and AniDex
- From AniDex list -> Observation Detail -> Map (if coordinates present)

## Localization
- Multi-language supported. Confirm initial languages (e.g., English + Traditional Chinese?). Use Localizable.strings throughout.

## Milestones (draft)
- M1: Scaffold UI (tabs, basic screens) + permissions strings
- M2: Photo picker/camera flow + stub classifier + save entries
- M3: Real on-device classification + detail view + thumbnails
- M4: Location tagging + MapKit display + sorting & delete polish

## Open Questions
- Which languages to localize first?
- Should description/fact be generated on-device only, or may we enrich via a web source (e.g., Wikipedia) when online?
- Any constraints on storing full-size images vs. downscaled copies?