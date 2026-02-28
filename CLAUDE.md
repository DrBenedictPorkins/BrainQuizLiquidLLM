# Project Overview

This is a native **iOS application** built with **Swift 6.1+** and **SwiftUI**. The codebase targets **iOS 18.0 and later**, allowing full use of modern Swift and iOS APIs. All concurrency is handled with **Swift Concurrency** (async/await, actors, @MainActor isolation) ensuring thread-safe code.

- **Frameworks & Tech:** SwiftUI for UI, Swift Concurrency with strict mode, Swift Package Manager for modular architecture
- **Architecture:** Model-View (MV) pattern using pure SwiftUI state management. We avoid MVVM and instead leverage SwiftUI's built-in state mechanisms (@State, @Observable, @Environment, @Binding)
- **Testing:** Swift Testing framework with modern @Test macros and #expect/#require assertions
- **Platform:** iOS (Simulator and Device)
- **Accessibility:** Full accessibility support using SwiftUI's accessibility modifiers

## Project Structure

The project follows a **workspace + SPM package** architecture:

```
LeapDemo/
├── Config/                         # XCConfig build settings
│   ├── Debug.xcconfig
│   ├── Release.xcconfig
│   ├── Shared.xcconfig
│   └── Tests.xcconfig
├── LeapDemo.xcworkspace/           # Workspace container (always open this)
├── LeapDemo.xcodeproj/             # App shell (minimal wrapper)
├── LeapDemo/                       # App target - just the entry point
│   ├── Assets.xcassets/
│   ├── LeapDemoApp.swift           # @main entry point only
│   └── LeapDemo.xctestplan
├── LeapDemoPackage/                # All features and business logic
│   ├── Package.swift               # Depends on LeapSDK (local path)
│   ├── Sources/
│   │   └── LeapDemoFeature/        # Feature module
│   └── Tests/
│       └── LeapDemoFeatureTests/   # Swift Testing tests
└── LeapDemoUITests/                # UI automation tests
```

**Important:** All development work should be done in the **LeapDemoPackage** Swift Package, not in the app project. The app project is merely a thin wrapper that imports and launches the package features.

## LeapSDK Dependency

This project depends on [LeapSDK](https://github.com/Liquid4All/leap-ios) as a **local path** dependency. The repo bundles pre-built XCFrameworks that are referenced via `path:` binary targets in `leap-ios/Package.swift`.

Clone it alongside this repo before opening in Xcode:

```bash
git clone https://github.com/Liquid4All/leap-ios.git ~/Swift/leap-ios
```

Then update the path in `LeapDemoPackage/Package.swift` if your clone location differs:

```swift
.package(path: "/your/path/to/leap-ios")
```

> **Note:** Using the remote SPM URL (`url:`) does not work — Xcode/SPM fails to download the binary artifact zips from GitHub releases. The local path approach using pre-built XCFrameworks is the correct method.

## Xcode 26 / macOS Tahoe — Known SPM Issue

On macOS Tahoe (Darwin 25+) with Xcode 26, SPM package resolution may silently fail in the Xcode UI. Fix:

```bash
defaults write com.apple.dt.Xcode IDEPackageSupportUseBuiltinSCM 1
```

Restart Xcode after running this command. Then use **File → Packages → Reset Package Caches**.

# Code Quality & Style Guidelines

## Swift Style & Conventions

- **Naming:** Use `UpperCamelCase` for types, `lowerCamelCase` for properties/functions. Choose descriptive names (e.g., `calculateMonthlyRevenue()` not `calcRev`)
- **Value Types:** Prefer `struct` for models and data, use `class` only when reference semantics are required
- **Enums:** Leverage Swift's powerful enums with associated values for state representation
- **Early Returns:** Prefer early return pattern over nested conditionals to avoid pyramid of doom

## Optionals & Error Handling

- Use optionals with `if let`/`guard let` for nil handling
- Never force-unwrap (`!`) without absolute certainty - prefer `guard` with failure path
- Use `do/try/catch` for error handling with meaningful error types
- Handle or propagate all errors - no empty catch blocks

# Modern SwiftUI Architecture Guidelines (2025)

### No ViewModels - Use Native SwiftUI Data Flow
**New features MUST follow these patterns:**

1. **Views as Pure State Expressions**
   ```swift
   struct MyView: View {
       @Environment(MyService.self) private var service
       @State private var viewState: ViewState = .loading
       
       enum ViewState {
           case loading
           case loaded(data: [Item])
           case error(String)
       }
       
       var body: some View {
           // View is just a representation of its state
       }
   }
   ```

2. **Use Environment Appropriately**
   - **App-wide services**: Router, Theme, CurrentAccount, Client, etc. - use `@Environment`
   - **Feature-specific services**: Timeline services, single-view logic - use `let` properties with `@Observable`
   - Rule: Environment for cross-app/cross-feature dependencies, let properties for single-feature services
   - Access app-wide via `@Environment(ServiceType.self)`
   - Feature services: `private let myService = MyObservableService()`

3. **Local State Management**
   - Use `@State` for view-specific state
   - Use `enum` for view states (loading, loaded, error)
   - Use `.task(id:)` and `.onChange(of:)` for side effects
   - Pass state between views using `@Binding`

4. **No ViewModels Required**
   - Views should be lightweight and disposable
   - Business logic belongs in services/clients
   - Test services independently, not views
   - Use SwiftUI previews for visual testing

5. **When Views Get Complex**
   - Split into smaller subviews
   - Use compound views that compose smaller views
   - Pass state via bindings between views
   - Never reach for a ViewModel as the solution

# iOS 26 Features (Optional)

**Note**: If your app targets iOS 26+, you can take advantage of these cutting-edge SwiftUI APIs introduced in June 2025. These features are optional and should only be used when your deployment target supports iOS 26.

## Available iOS 26 SwiftUI APIs

When targeting iOS 26+, consider using these new APIs:

#### Liquid Glass Effects
- `glassEffect(_:in:isEnabled:)` - Apply Liquid Glass effects to views
- `buttonStyle(.glass)` - Apply Liquid Glass styling to buttons
- `ToolbarSpacer` - Create visual breaks in toolbars with Liquid Glass

#### Enhanced Scrolling
- `scrollEdgeEffectStyle(_:for:)` - Configure scroll edge effects
- `backgroundExtensionEffect()` - Duplicate, mirror, and blur views around edges

#### Tab Bar Enhancements
- `tabBarMinimizeBehavior(_:)` - Control tab bar minimization behavior
- Search role for tabs with search field replacing tab bar
- `TabViewBottomAccessoryPlacement` - Adjust accessory view content based on placement

#### Web Integration
- `WebView` and `WebPage` - Full control over browsing experience

#### Drag and Drop
- `draggable(_:_:)` - Drag multiple items
- `dragContainer(for:id:in:selection:_:)` - Container for draggable views

#### Animation
- `@Animatable` macro - SwiftUI synthesizes custom animatable data properties

#### UI Components
- `Slider` with automatic tick marks when using step parameter
- `windowResizeAnchor(_:)` - Set window anchor point for resizing

#### Text Enhancements
- `TextEditor` now supports `AttributedString`
- `AttributedTextSelection` - Handle text selection with attributed text
- `AttributedTextFormattingDefinition` - Define text styling in specific contexts
- `FindContext` - Create find navigator in text editing views

#### Accessibility
- `AssistiveAccess` - Support Assistive Access in iOS scenes

#### HDR Support
- `Color.ResolvedHDR` - RGBA values with HDR headroom information

#### UIKit Integration
- `UIHostingSceneDelegate` - Host and present SwiftUI scenes in UIKit
- `NSGestureRecognizerRepresentable` - Incorporate gesture recognizers from AppKit

#### Immersive Spaces (if applicable)
- `manipulable(coordinateSpace:operations:inertia:isEnabled:onChanged:)` - Hand gesture manipulation
- `SurfaceSnappingInfo` - Snap volumes and windows to surfaces
- `RemoteImmersiveSpace` - Render stereo content from Mac to Apple Vision Pro
- `SpatialContainer` - 3D layout container
- Depth-based modifiers: `aspectRatio3D(_:contentMode:)`, `rotation3DLayout(_:)`, `depthAlignment(_:)`

## iOS 26 Usage Guidelines
- **Only use when targeting iOS 26+**: Ensure your deployment target supports these APIs
- **Progressive enhancement**: Use availability checks if supporting multiple iOS versions
- **Feature detection**: Test on older simulators to ensure graceful fallbacks
- **Modern aesthetics**: Leverage Liquid Glass effects for cutting-edge UI design

```swift
// Example: Using iOS 26 features with availability checks
struct ModernButton: View {
    var body: some View {
        Button("Tap me") {
            // Action
        }
        .buttonStyle({
            if #available(iOS 26.0, *) {
                .glass
            } else {
                .bordered
            }
        }())
    }
}
```

## SwiftUI State Management (MV Pattern)

- **@State:** For all state management, including observable model objects
- **@Observable:** Modern macro for making model classes observable (replaces ObservableObject)
- **@Environment:** For dependency injection and shared app state
- **@Binding:** For two-way data flow between parent and child views
- **@Bindable:** For creating bindings to @Observable objects
- Avoid ViewModels - put view logic directly in SwiftUI views using these state mechanisms
- Keep views focused and extract reusable components

Example with @Observable:
```swift
@Observable
class UserSettings {
    var theme: Theme = .light
    var fontSize: Double = 16.0
}

@MainActor
struct SettingsView: View {
    @State private var settings = UserSettings()
    
    var body: some View {
        VStack {
            // Direct property access, no $ prefix needed
            Text("Font Size: \(settings.fontSize)")
            
            // For bindings, use @Bindable
            @Bindable var settings = settings
            Slider(value: $settings.fontSize, in: 10...30)
        }
    }
}

// Sharing state across views
@MainActor
struct ContentView: View {
    @State private var userSettings = UserSettings()
    
    var body: some View {
        NavigationStack {
            MainView()
                .environment(userSettings)
        }
    }
}

@MainActor
struct MainView: View {
    @Environment(UserSettings.self) private var settings
    
    var body: some View {
        Text("Current theme: \(settings.theme)")
    }
}
```

Example with .task modifier for async operations:
```swift
@Observable
class DataModel {
    var items: [Item] = []
    var isLoading = false
    
    func loadData() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulated network call
        try await Task.sleep(for: .seconds(1))
        items = try await fetchItems()
    }
}

@MainActor
struct ItemListView: View {
    @State private var model = DataModel()
    
    var body: some View {
        List(model.items) { item in
            Text(item.name)
        }
        .overlay {
            if model.isLoading {
                ProgressView()
            }
        }
        .task {
            // This task automatically cancels when view disappears
            do {
                try await model.loadData()
            } catch {
                // Handle error
            }
        }
        .refreshable {
            // Pull to refresh also uses async/await
            try? await model.loadData()
        }
    }
}
```

## Concurrency

- **@MainActor:** All UI updates must use @MainActor isolation
- **Actors:** Use actors for expensive operations like disk I/O, network calls, or heavy computation
- **async/await:** Always prefer async functions over completion handlers
- **Task:** Use structured concurrency with proper task cancellation
- **.task modifier:** Always use .task { } on views for async operations tied to view lifecycle - it automatically handles cancellation
- **Avoid Task { } in onAppear:** This doesn't cancel automatically and can cause memory leaks or crashes
- No GCD usage - Swift Concurrency only

### Sendable Conformance

Swift 6 enforces strict concurrency checking. All types that cross concurrency boundaries must be Sendable:

- **Value types (struct, enum):** Usually Sendable if all properties are Sendable
- **Classes:** Must be marked `final` and have immutable or Sendable properties, or use `@unchecked Sendable` with thread-safe implementation
- **@Observable classes:** Automatically Sendable when all properties are Sendable
- **Closures:** Mark as `@Sendable` when captured by concurrent contexts

```swift
// Sendable struct - automatic conformance
struct UserData: Sendable {
    let id: UUID
    let name: String
}

// Sendable class - must be final with immutable properties
final class Configuration: Sendable {
    let apiKey: String
    let endpoint: URL
    
    init(apiKey: String, endpoint: URL) {
        self.apiKey = apiKey
        self.endpoint = endpoint
    }
}

// @Observable with Sendable
@Observable
final class UserModel: Sendable {
    var name: String = ""
    var age: Int = 0
    // Automatically Sendable if all stored properties are Sendable
}

// Using @unchecked Sendable for thread-safe types
final class Cache: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Any] = [:]
    
    func get(_ key: String) -> Any? {
        lock.withLock { storage[key] }
    }
}

// @Sendable closures
func processInBackground(completion: @Sendable @escaping (Result<Data, Error>) -> Void) {
    Task {
        // Processing...
        completion(.success(data))
    }
}
```

## Code Organization

- Keep functions focused on a single responsibility
- Break large functions (>50 lines) into smaller, testable units
- Use extensions to organize code by feature or protocol conformance
- Prefer `let` over `var` - use immutability by default
- Use `[weak self]` in closures to prevent retain cycles
- Always include `self.` when referring to instance properties in closures

# Testing Guidelines

We use **Swift Testing** framework (not XCTest) for all tests. Tests live in the package test target.

## Swift Testing Basics

```swift
import Testing

@Test func userCanLogin() async throws {
    let service = AuthService()
    let result = try await service.login(username: "test", password: "pass")
    #expect(result.isSuccess)
    #expect(result.user.name == "Test User")
}

@Test("User sees error with invalid credentials")
func invalidLogin() async throws {
    let service = AuthService()
    await #expect(throws: AuthError.self) {
        try await service.login(username: "", password: "")
    }
}
```

## Key Swift Testing Features

- **@Test:** Marks a test function (replaces XCTest's test prefix)
- **@Suite:** Groups related tests together
- **#expect:** Validates conditions (replaces XCTAssert)
- **#require:** Like #expect but stops test execution on failure
- **Parameterized Tests:** Use @Test with arguments for data-driven tests
- **async/await:** Full support for testing async code
- **Traits:** Add metadata like `.bug()`, `.feature()`, or custom tags

## Test Organization

- Write tests in the package's Tests/ directory
- One test file per source file when possible
- Name tests descriptively explaining what they verify
- Test both happy paths and edge cases
- Add tests for bug fixes to prevent regression

# Entitlements Management

This template includes a **declarative entitlements system** that AI agents can safely modify without touching Xcode project files.

## How It Works

- **Entitlements File**: `Config/LeapDemo.entitlements` contains all app capabilities
- **XCConfig Integration**: `CODE_SIGN_ENTITLEMENTS` setting in `Config/Shared.xcconfig` points to the entitlements file
- **AI-Friendly**: Agents can edit the XML file directly to add/remove capabilities

## Adding Entitlements

To add capabilities to your app, edit `Config/LeapDemo.entitlements`:

## Common Entitlements

| Capability | Entitlement Key | Value |
|------------|-----------------|-------|
| HealthKit | `com.apple.developer.healthkit` | `<true/>` |
| CloudKit | `com.apple.developer.icloud-services` | `<array><string>CloudKit</string></array>` |
| Push Notifications | `aps-environment` | `development` or `production` |
| App Groups | `com.apple.security.application-groups` | `<array><string>group.id</string></array>` |
| Keychain Sharing | `keychain-access-groups` | `<array><string>$(AppIdentifierPrefix)bundle.id</string></array>` |
| Background Modes | `com.apple.developer.background-modes` | `<array><string>mode-name</string></array>` |
| Contacts | `com.apple.developer.contacts.notes` | `<true/>` |
| Camera | `com.apple.developer.avfoundation.audio` | `<true/>` |

# XcodeBuildMCP Tool Usage

XcodeBuildMCP uses **session defaults** — set them once and all subsequent tool calls use them automatically.

## Session Setup

Always call `session_show_defaults` first to check current configuration, then set defaults:

```javascript
// Set defaults for this session (do this once)
session_set_defaults({
    workspacePath: "/Users/makram/Swift/LeapDemo/LeapDemo.xcworkspace",
    scheme: "LeapDemo",
    simulatorName: "iPhone 16"
})
```

## Building & Running

```javascript
// Build for simulator (compile only)
build_sim()

// Build and launch on simulator
build_run_sim()

// Clean build artifacts
clean()
```

## Testing

```javascript
// Run tests on simulator
test_sim()
```

## Simulator Management

```javascript
// List available simulators
list_sims({ enabled: true })

// Boot simulator
boot_sim()

// Install and launch app
install_app_sim({ appPath: "/path/to/LeapDemo.app" })
launch_app_sim()         // uses bundleId from session defaults
launch_app_logs_sim()    // same but streams logs
```

## UI Automation

```javascript
// Capture screenshot
screenshot()

// Inspect view hierarchy with coordinates
snapshot_ui()
```

## Log Capture

```javascript
// Start capturing logs
start_sim_log_cap({ subsystemFilter: "app" })

// Stop and retrieve logs
stop_sim_log_cap({ logSessionId: "SESSION_ID" })
```

# Development Workflow

1. **Make changes in the Package**: All feature development happens in `LeapDemoPackage/Sources/LeapDemoFeature/`
2. **Write tests**: Add Swift Testing tests in `LeapDemoPackage/Tests/LeapDemoFeatureTests/`
3. **Build and test**: Use XcodeBuildMCP tools to build and run tests
4. **Run on simulator**: Deploy to simulator for manual testing
5. **UI automation**: Use `snapshot_ui` and `screenshot` tools for UI inspection
6. **Device testing**: Deploy to physical device when needed

# Best Practices

## SwiftUI & State Management

- Keep views small and focused
- Extract reusable components into their own files
- Use @ViewBuilder for conditional view composition
- Leverage SwiftUI's built-in animations and transitions
- Avoid massive body computations - break them down
- **Always use .task modifier** for async work tied to view lifecycle - it automatically cancels when the view disappears
- Never use Task { } in onAppear - use .task instead for proper lifecycle management

## Performance

- Use .id() modifier sparingly as it forces view recreation
- Implement Equatable on models to optimize SwiftUI diffing
- Use LazyVStack/LazyHStack for large lists
- Profile with Instruments when needed
- @Observable tracks only accessed properties, improving performance over @Published

## Accessibility

- Always provide accessibilityLabel for interactive elements
- Use accessibilityIdentifier for UI testing
- Implement accessibilityHint where actions aren't obvious
- Test with VoiceOver enabled
- Support Dynamic Type

## Security & Privacy

- Never log sensitive information
- Use Keychain for credential storage
- All network calls must use HTTPS
- Request minimal permissions
- Follow App Store privacy guidelines

## Data Persistence

When data persistence is required, always prefer **SwiftData** over CoreData. However, carefully consider whether persistence is truly necessary - many apps can function well with in-memory state that loads on launch.

### When to Use SwiftData

- You have complex relational data that needs to persist across app launches
- You need advanced querying capabilities with predicates and sorting
- You're building a data-heavy app (note-taking, inventory, task management)
- You need CloudKit sync with minimal configuration

### When NOT to Use Data Persistence

- Simple user preferences (use UserDefaults)
- Temporary state that can be reloaded from network
- Small configuration data (consider JSON files or plist)
- Apps that primarily display remote data

### SwiftData Best Practices

```swift
import SwiftData

@Model
final class Task {
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    
    init(title: String) {
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
    }
}

// In your app
@main
struct LeapDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Task.self)
        }
    }
}

// In your views
struct TaskListView: View {
    @Query private var tasks: [Task]
    @Environment(\.modelContext) private var context
    
    var body: some View {
        List(tasks) { task in
            Text(task.title)
        }
        .toolbar {
            Button("Add") {
                let newTask = Task(title: "New Task")
                context.insert(newTask)
            }
        }
    }
}
```

**Important:** Never use CoreData for new projects. SwiftData provides a modern, type-safe API that's easier to work with and integrates seamlessly with SwiftUI.

---

Remember: This project prioritizes clean, simple SwiftUI code using the platform's native state management. Keep the app shell minimal and implement all features in the Swift Package.