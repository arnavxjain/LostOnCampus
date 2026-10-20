# Local patches to native_glass_navbar 1.2.0

Upstream: https://github.com/TechSupportz/native_glass_navbar (pub.dev 1.2.0).

## Selection sync (`ios/.../NativeTabBar.swift`)

Inside a Flutter platform view, touches reach UIKit only after Flutter's gesture
arena hands them over. With the iOS 26+ tab bar this can make the bar change its
selection without calling `tabBarController(_:didSelect...)`, so Flutter never
hears about it and stays on the old page.

The patch overrides `selectedTab`, `selectedIndex` and `selectedViewController`
and reports every user-driven selection change to Flutter (`valueChanged`),
deduplicated against the last known index. Selection changes made *from*
Flutter (`update`, rebuilds) are suppressed so they aren't echoed back.

Known limitation (not fixable in the plugin): an extremely short tap can still
end before Flutter hands the touch to UIKit, in which case the bar ignores it.
