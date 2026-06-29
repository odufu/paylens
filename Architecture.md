# 🧱 {{Project Name}} Architecture & Development Guideline

This document serves as the **Absolute Source of Truth** for the `{{project_name}}` Flutter project structure. All future developments, whether by humans or AI, must strictly adhere to these rules.

---

## 🏛️ 1. Core Philosophy: Feature-First Clean Architecture

We use a modular, feature-based approach combined with Clean Architecture principles. Every feature is a self-contained unit that can be developed, tested, and maintained independently.

### Root Structure (`lib/`)

* `core/`: Infrastructure, global services, shared configurations, utilities, and application-wide constants.
* `shared/`: Reusable UI components, layout design tokens, and common data models used across multiple features.
* `features/`: The heart of the app, organized by functional, decoupled modules.
* `main.dart`: Global entry point and provider/service locator initialization.

---

## 📂 2. Feature Internal Structure

Each feature folder inside `lib/features/{{feature_name}}/` should follow this standard layout. Layers are added **as needed** depending on complexity:

```
{{feature_name}}/
├── data/             # Remote & Local data handling
│   ├── datasources/  # API clients, local DB / shared preferences drivers
│   ├── models/       # Data Transfer Objects (DTOs), serialization/deserialization
│   └── repositories/ # Implementation of domain contracts/interfaces
├── domain/           # Pure Business Logic (No Flutter imports allowed)
│   ├── entities/     # Clean business objects
│   ├── repositories/ # Abstract contracts defining data operations
│   └── usecases/     # Functional application actions/interactors
├── presentation/     # UI and State Management
│   ├── pages/        # Screens / full views
│   ├── widgets/      # Feature-specific atomic components
│   └── state/        # State management controllers (e.g., Providers)
└── di/               # Feature-level dependency injection module (if decoupled)

```

---

## 📂 3. Dependency Injection (DI) with GetIt

We use `get_it` as our primary service locator and dependency injection framework. This ensures that services, repositories, and use cases are easily mockable for testing and decoupling.

### I. Registration

All global dependencies must be registered in `lib/core/di/injection_container.dart` within an initialization function called during startup.

```dart
final sl = GetIt.instance; // sl stands for Service Locator

void initGlobalDI() {
  // 1. Services / Core Infrastructure (e.g., Network, Cache, Logger)
  sl.registerLazySingleton<ApiClient>(() => ApiClientImpl());
  
  // 2. Data Sources
  sl.registerLazySingleton<{{FeatureName}}RemoteDataSource>(() => {{FeatureName}}RemoteDataSourceImpl(sl()));
  
  // 3. Repositories (Abstract Contract -> Implementation)
  sl.registerLazySingleton<{{FeatureName}}Repository>(() => {{FeatureName}}RepositoryImpl(sl()));
  
  // 4. Use Cases
  sl.registerLazySingleton<Get{{FeatureName}}UseCase>(() => Get{{FeatureName}}UseCase(sl()));
}

```

### II. Relationship with State Management (Provider)

* **GetIt** manages the **Life Cycle** of underlying dependencies and business logic elements (Singletons, Factories).
* **Provider** remains as the **UI Binder** and State Manager.
* Pass dependencies from GetIt into the Provider's constructor. Use a factory constructor for clean initialization in `main.dart`.

```dart
class {{FeatureName}}Provider extends ChangeNotifier {
  final Get{{FeatureName}}UseCase _get{{FeatureName}}UseCase;
  
  // Inject dependency via constructor
  {{FeatureName}}Provider(this._get{{FeatureName}}UseCase);
  
  // Factory constructor for easy registration
  factory {{FeatureName}}Provider.instance() => {{FeatureName}}Provider(sl<Get{{FeatureName}}UseCase>());
}

```

---

## 🛑 4. Strict Architectural Rules

### I. Layer Isolation

* **Domain stays Pure**: The `domain/` layer must NEVER import `package:flutter`. It must remain pure Dart logic to allow for cross-platform portability and unit testing.
* **Data stays Abstract**: `data/` implements interfaces defined in `domain/`. It handles transformations from JSON data structures to application-ready entities.
* **Presentation stays Visual**: Business logic belongs inside `usecases` or state controllers (`providers`), never directly inside UI builders or view trees.

### II. Import Policy (Mandatory)

* **Absolute Imports ONLY**: Always use `package:{{project_name}}/...`.
* **No Relative Imports**: Never use relative paths (`../../`). This prevents fragile paths, breaks dependencies gracefully during refactors, and maintains module boundaries.

### III. State Management Standard

* Use `ChangeNotifier` and `Provider` consistently unless explicitly shifted for specific background processes.
* Locate state elements within `features/{{feature_name}}/presentation/state/`.
* Register global providers in `main.dart`. Prefer localized, short-lived providers scoped via `ChangeNotifierProvider` near the sub-route layer where applicable.

---

## 🎨 5. Coding & Naming Standards

| Type | Naming Convention | Example |
| --- | --- | --- |
| **Pages/Screens** | `*_screen.dart` or `*_page.dart` | `home_screen.dart`, `settings_page.dart` |
| **Providers** | `*_provider.dart` | `auth_provider.dart` |
| **States** | `*_state.dart` | `profile_state.dart` |
| **Widgets** | `*_widget.dart` or descriptive nouns | `custom_button.dart`, `user_avatar.dart` |
| **Constants** | `App*` utility classes | `AppColors`, `AppStrings`, `AppTheme` |

---

## 🚦 6. Asynchronous Process Handling

To ensure a consistent UX and robust error handling, all async operations must follow a declarative **Result/State Pattern**.

### I. State Modeling

Use **Sealed Classes** (Dart 3+) for UI states instead of exposing separate boolean parameters (e.g., `isLoading`, `hasError`).

```dart
sealed class UIState<T> {}
class Initial<T> extends UIState<T> {}
class Loading<T> extends UIState<T> {}
class Success<T> extends UIState<T> { final T data; Success(this.data); }
class Failure<T> extends UIState<T> { final String message; Failure(this.message); }

```

### II. Implementation Rules

* **Never leave UI in limbo**: Always explicitly account for `Loading` and `Failure` matches within views using a `switch` statement or pattern matching.
* **Fail Fast & Safe**: Intercept structural platform exceptions at the `data` layer (e.g., HTTP exceptions, platform cache issues) and transform them into predictable, localized `Failure` domains.

---

## 📦 7. Package Selection Policy

Before adding new dependencies to `pubspec.yaml`:

1. **Efficiency First**: Prefer lightweight packages with minimal nested transitive dependencies to maintain fast compile pipelines and lean bundle binaries.
2. **Standardization**: Utilize libraries already validated and integrated in the repository blueprint (e.g., `provider`, `get_it`) before adding overlapping alternatives.
3. **Platform Check**: Ensure compatibility across all targeting operating systems and platform environments.
4. **Dart-Native**: Favor pure Dart/Flutter implementations over heavy platform-specific native channel plugins where applicable.

---

## 🤖 8. Protocol for AI Assistants (Read Before Coding)

If you are an AI assistant assisting with this project, you **MUST**:

1. **Strictly execute architectural rules**: Read this architecture blueprint fully before generating scaffolding code blocks.
2. **Path Verification**: Inspect package imports and reference variables within `lib/core/theme/` or global constants before generating boilerplate assets, typography tokens, or style hexes.
3. **Keep Layers Intact**: When building out new feature interfaces, scaffold out appropriate `domain/` and `data/` structures if network or state transactions are anticipated.
4. **Enforce Absolute Paths**: Ensure all generated classes use clean `package:{{project_name}}/` formatting uniformly.

---

## 🚀 9. Feature Scaffolding Workflow

When implementing an entirely new feature module (e.g., `user_profile`):

1. Scaffold directory infrastructure under `lib/features/user_profile/`.
2. Map UI prototypes inside `presentation/pages/` and connect layout dependencies using `presentation/state/`.
3. Abstract underlying business boundaries via `domain/` and wire structural backends using `data/` classes.
4. Wire up service mapping configurations in the central dependency injector context, and expose states globally or locally as required.

---

**Last Updated**: June 2026

**Status**: ACTIVE BLUEPRINT TEMPLATE