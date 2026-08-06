# Press Kit — Technical Architecture Overview

Holo Browser utilizes an MVVM architecture backed by `BrowserEnvironment` as a clean composition root. All UI and view model state is `@MainActor` isolated under Swift 6 strict concurrency rules, while disk I/O offloads to background utility queues via `Task.detached(priority: .utility)`.
