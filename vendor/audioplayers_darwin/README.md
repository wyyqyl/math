# audioplayers_darwin 6.5.0

This copy of the upstream Apple implementation keeps player status and completion callbacks on the main actor under Xcode 27. Status observation resumes the preparation continuation once. The upstream license is included.

The application uses this copy through the override in the root pubspec. Remove the override when a published release includes the fix.
