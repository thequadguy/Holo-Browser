# HOLO BROWSER — CLOUDKIT SYNC ARCHITECTURE SPECIFICATION (V1.3 PREPARATION)

## Executive Overview

This design specification details the architecture for `CloudKitSyncManager`, an end-to-end encrypted (E2EE) synchronization subsystem planned for Holo Browser V1.3+. The manager synchronizes HoloMind personal memories, tab bookmarks, and active tab session state across macOS and iOS devices running Holo Browser.

---

## 1. Core Principles & Constraints

1. **Zero Unencrypted Telemetry**: Private browsing records and unencrypted AI context will never be uploaded to CloudKit.
2. **Apple Private Cloud Database**: Data is stored inside the user's private CloudKit database container (`iCloud.com.holobrowser.app`).
3. **Keychain Encryption Boundary**: Sensitive memory strings and session metadata are encrypted using CryptoKit (`AES-GCM-256`) with symmetric keys derived from Apple Keychain.
4. **Low Power & Bandwidth**: Incremental sync updates use CloudKit `CKFetchRecordZoneChangesOperation` with change tokens.

---

## 2. Sync Entity Mappings (`CKRecord`)

### A. Personal Memory Entity (`HoloMemoryRecord`)
- **CKRecordType**: `HoloPersonalMemory`
- **Fields**:
  - `recordID`: UUID string
  - `encryptedPayload`: Encrypted Data (`AES-GCM-256` of `PersonalMemory` JSON)
  - `category`: String (e.g. `Research`, `Preference`)
  - `updatedAt`: Date
  - `deviceOrigin`: String

### B. Bookmark Item Entity (`HoloBookmarkRecord`)
- **CKRecordType**: `HoloBookmark`
- **Fields**:
  - `recordID`: UUID string
  - `title`: String
  - `url`: String
  - `parentFolderID`: Optional UUID string
  - `isFavorite`: Bool
  - `updatedAt`: Date

### C. Active Session Entity (`HoloSessionRecord`)
- **CKRecordType**: `HoloTabSession`
- **Fields**:
  - `recordID`: UUID string (profile ID)
  - `encryptedTabURLs`: Encrypted Data (Array of tab URLs & titles)
  - `activeTabIndex`: Int
  - `updatedAt`: Date

---

## 3. Conflict Resolution Strategy

- **Strategy**: Field-Level Last-Write-Wins (LWW) with Vector Clocks.
- **Clock**: `updatedAt` ISO-8601 timestamp + device epoch counter.
- **Deletion Handling**: Soft deletion using tombstone records retained for 30 days before purge.

---

## 4. Encryption Boundary Pipeline

```
[Local PersonalMemory] ──> [CryptoKit AES-GCM-256 (Keychain Key)] ──> [CKRecord] ──> [Apple iCloud Private Database]
```

---

## 5. Implementation Roadmap Strategy

1. **Phase 1 (Current V1.2)**: Architecture specification finalized. No runtime code changes.
2. **Phase 2 (V1.3 Alpha)**: Implement `CloudKitSyncActor` behind `@AppStorage("enableCloudKitSync")` feature flag (default false).
3. **Phase 3 (V1.3 Release)**: Full background sync integration with automatic push notifications (`CKQueryNotification`).
