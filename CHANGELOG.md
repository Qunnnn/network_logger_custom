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
