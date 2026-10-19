import SwiftUI

#if os(iOS)
    import UIKit
#endif

extension View {
    /// Mounts the toast/snackbar host once, at the root. On iOS it lives in its own window above the app's,
    /// so feedback shows over sheets and full-screen covers too, which a plain `.overlay` can't do (§6m).
    public func feedbackWindow(_ center: FeedbackCenter, bottomInset: CGFloat = AppSize.tabBarHeight) -> some View {
        #if os(iOS)
            modifier(FeedbackWindowModifier(center: center, bottomInset: bottomInset))
        #else
            overlay { FeedbackHost(center: center, bottomInset: bottomInset) }
        #endif
    }
}

#if os(iOS)
    private struct FeedbackWindowModifier: ViewModifier {
        let center: FeedbackCenter
        let bottomInset: CGFloat
        @State private var window: PassthroughWindow?

        func body(content: Content) -> some View {
            content.background(
                WindowSceneReader { scene in
                    guard window == nil else { return }
                    window = PassthroughWindow.install(in: scene, center: center, bottomInset: bottomInset)
                }
            )
        }
    }

    /// A transparent window that only takes touches inside the visible toast/snackbar; everything else
    /// falls through to the app window below.
    private final class PassthroughWindow: UIWindow {
        var interactiveFrame: CGRect = .zero

        static func install(in scene: UIWindowScene, center: FeedbackCenter, bottomInset: CGFloat) -> PassthroughWindow
        {
            let window = PassthroughWindow(windowScene: scene)
            let host = UIHostingController(
                rootView: FeedbackHost(center: center, bottomInset: bottomInset) { [weak window] frame in
                    window?.interactiveFrame = frame
                })
            host.view.backgroundColor = .clear
            window.rootViewController = host
            window.backgroundColor = .clear
            window.windowLevel = .alert + 1
            window.isHidden = false
            return window
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            interactiveFrame.contains(point) ? super.hitTest(point, with: event) : nil
        }
    }

    /// Reports the window scene the view ends up in.
    private struct WindowSceneReader: UIViewRepresentable {
        let onScene: (UIWindowScene) -> Void

        func makeUIView(context: Context) -> SceneView {
            SceneView(onScene: onScene)
        }

        func updateUIView(_ uiView: SceneView, context: Context) {}

        final class SceneView: UIView {
            let onScene: (UIWindowScene) -> Void

            init(onScene: @escaping (UIWindowScene) -> Void) {
                self.onScene = onScene
                super.init(frame: .zero)
                isUserInteractionEnabled = false
            }

            @available(*, unavailable)
            required init?(coder: NSCoder) { nil }

            override func didMoveToWindow() {
                super.didMoveToWindow()
                if let scene = window?.windowScene { onScene(scene) }
            }
        }
    }
#endif
