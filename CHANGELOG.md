## 1.1.0

* **Memory Management**: Added `maxEntries` limit (default 500) to `NetworkEventList` to prevent high memory usage in long-running apps.
* **Deep Search**: Expanded search capabilities to include Request Method, Status Code, Request Body, and Response Body.
* **Quick Filters**: Added Success (2xx) and Error (4xx, 5xx) filter chips for faster debugging.
* **JSON Tree Viewer**: Implemented a recursive, collapsible JSON tree viewer for structured inspection of large payloads.
* **Full Session Export**: Added a "Copy" action to the main screen to export the entire network session as a JSON string.
* **cURL Support for FormData**: Fixed `RequestToCurlConverter` to properly handle `dio.FormData` requests (multipart).
- **UI/UX Polish**:
    - Added spring-physics edge-snapping for the draggable overlay button.
    - Switched to `SelectableText` in the details view for easier data extraction.
    - Improved Dark Mode support with theme-aware color tokens.
    - Updated to use non-deprecated Flutter color methods.

## 1.0.2

* **Bugfix**: Fixed missing `handler.next()` calls in `onResponse` and `onError` of `DioNetworkLogger`, which caused the Dio interceptor chain to break — responses and errors were silently swallowed instead of being forwarded to callers.

## 1.0.1

* Improved dependency compatibility (Dio ^5.2.0, Cupertino Icons ^1.0.0).
* Cleaned up library documentation and metadata for pub.dev.
* Resolved various static analysis warnings for better score.

## 1.0.0

* Initial release.
* Features:
    * Custom Dio Interceptor for capturing network telemetry.
    * Draggable floating action button overlay.
    * Detailed log inspection screen (Request, Response, Headers, Error).
    * cURL command export.
    * Real-time search/filtering within logs.
