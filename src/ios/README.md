# Mint Replica Lite - iOS Application

<!-- HUMAN TASKS
1. Install Xcode 14.0+ from the Mac App Store
2. Install CocoaPods 1.12.0+ using: sudo gem install cocoapods
3. Configure Apple Developer account in Xcode
4. Add GoogleService-Info.plist for Firebase configuration
5. Set up code signing certificates and provisioning profiles
6. Configure SwiftLint by installing via Homebrew: brew install swiftlint
-->

## Project Overview

Mint Replica Lite iOS is a native financial management application built with Swift and UIKit/SwiftUI, providing users with comprehensive financial account management, transaction tracking, budgeting, and investment monitoring capabilities.

### System Requirements

- iOS 14.0 or later
- Xcode 14.0+
- CocoaPods 1.12.0+
- Swift 5.0+
- macOS Monterey (12.0) or later

### Architecture Overview

The application follows the MVVM (Model-View-ViewModel) architecture pattern with the following key components:

- **Presentation Layer**: SwiftUI/UIKit views and view controllers
- **Business Logic**: ViewModels and Services
- **Data Layer**: Core Data for local persistence
- **Networking**: URLSession with Alamofire
- **Security**: Keychain Services for credential storage

### Key Features

- Multi-account financial management
- Real-time transaction synchronization
- Category-based budgeting
- Investment portfolio tracking
- Secure authentication and data encryption
- Offline capability with Core Data
- Push notifications for alerts and updates

## Getting Started

### Prerequisites Installation

1. Install Xcode from the Mac App Store
```bash
xcode-select --install
```

2. Install CocoaPods
```bash
sudo gem install cocoapods
```

3. Install SwiftLint
```bash
brew install swiftlint
```

### Environment Setup

1. Clone the repository
```bash
git clone <repository-url>
cd src/ios
```

2. Install dependencies
```bash
pod install
```

3. Open the workspace
```bash
open MintReplicaLite.xcworkspace
```

### Project Configuration

1. Build Settings
```swift
DEVELOPMENT_TEAM = "Your Team ID"
PRODUCT_BUNDLE_IDENTIFIER = "com.mintreplicalite.ios"
SWIFT_VERSION = 5.0
IPHONEOS_DEPLOYMENT_TARGET = 14.0
```

2. Environment Variables
```swift
API_BASE_URL = "https://api.mintreplicalite.com"
API_VERSION = "v1"
ENVIRONMENT = "development"
```

### Running the Application

1. Select the appropriate scheme (Debug/Release)
2. Choose target device or simulator
3. Build and run (⌘R)
4. Run tests (⌘U)

## Architecture

### MVVM Pattern Implementation

```
├── Models
│   ├── Account.swift
│   ├── Transaction.swift
│   └── Budget.swift
├── Views
│   ├── AccountView.swift
│   ├── TransactionView.swift
│   └── BudgetView.swift
├── ViewModels
│   ├── AccountViewModel.swift
│   ├── TransactionViewModel.swift
│   └── BudgetViewModel.swift
└── Services
    ├── NetworkService.swift
    ├── StorageService.swift
    └── SecurityService.swift
```

### Core Modules

- **Authentication**: Handles user authentication and session management
- **Account Management**: Manages financial account integration
- **Transaction Sync**: Handles real-time transaction synchronization
- **Budget Tracking**: Manages budget creation and monitoring
- **Investment Module**: Handles investment portfolio tracking
- **Notification System**: Manages push notifications and alerts

### Data Flow

1. User Interface Layer (SwiftUI/UIKit)
2. ViewModel Layer (Business Logic)
3. Service Layer (API/Storage)
4. Core Data Layer (Local Persistence)
5. Network Layer (API Communication)

### Security Implementation

- Keychain Services for credential storage
- AES-256 encryption for sensitive data
- Certificate pinning for API communication
- Biometric authentication support
- Secure data wiping on logout

## Development Guidelines

### Code Style Guide

- Follow Swift API Design Guidelines
- Use Swift's type inference where appropriate
- Implement proper error handling
- Document public interfaces
- Use dependency injection
- Follow SOLID principles

### SwiftLint Rules

Refer to `.swiftlint.yml` for detailed configuration:

- Mandatory rules for code formatting
- Opt-in rules for enhanced quality
- Custom rules for project-specific requirements
- Analyzer rules for deep code analysis

### Testing Requirements

- Unit tests for business logic
- UI tests for critical flows
- Integration tests for API communication
- Minimum 80% code coverage
- Mock objects for dependencies

### Documentation Standards

- Use proper header documentation
- Document complex algorithms
- Include usage examples
- Document security considerations
- Keep README up to date

## Dependencies

### Third-party Libraries

- **Alamofire** (~> 5.6.0): Network requests
- **KeychainAccess** (~> 4.2.0): Secure storage
- **SwiftLint** (~> 0.50.0): Code quality
- **Charts** (~> 4.1.0): Financial visualization
- **Firebase** (~> 10.0.0): Analytics and messaging
- **CryptoSwift** (~> 1.7.0): Data encryption
- **SDWebImage** (~> 5.15.0): Image handling
- **PromiseKit** (~> 6.18.0): Async operations

### Internal Modules

- Core Data models
- Networking layer
- Security services
- Analytics tracking
- Cache management

### Configuration Management

- Environment-specific settings
- Feature flags
- API configurations
- Security policies

### Version Requirements

- iOS 14.0 minimum deployment target
- Swift 5.0 minimum
- Xcode 14.0 minimum
- CocoaPods 1.12.0 minimum

For detailed information about the project architecture, implementation guidelines, and best practices, refer to the technical specification document.