/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

#if canImport(SwiftUI)
import Foundation
import SwiftUI

/// This class is used to create and display native fullscreen messages using SwiftUI.
@objc(AEPFullscreenMessageNative)
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
@available(tvOS 13.0, *)
@available(iOS 13.0, *)
public class FullscreenMessageNative: NSObject, FullscreenPresentable {
    private let LOG_PREFIX = "FullscreenMessageNative"
    private let ANIMATION_DURATION = 0.3

    /// Assignable in the constructor, `settings` control the layout and behavior of the message
    @objc
    public var settings: MessageSettings?

    private let payload: any View
    private let listener: FullscreenMessageNativeDelegate?
    private let messageMonitor: MessageMonitoring
    private var hostingController: UIHostingController<AnyView>?

    var messagingDelegate: MessagingDelegate? {
        return ServiceProvider.shared.messagingDelegate
    }

    /// Creates `FullscreenMessageNative` instance with the SwiftUI view provided.
    /// - Parameters:
    ///     - payload: SwiftUI view to be displayed
    ///     - listener: `FullscreenMessageNativeDelegate` listener to listening the message lifecycle.
    ///     - messageMonitor: The message monitor to control message display
    ///     - settings: The `MessageSettings` object defining layout and behavior of the new message
    init(payload: any View, listener: FullscreenMessageNativeDelegate?, messageMonitor: MessageMonitoring, settings: MessageSettings? = nil) {
        self.payload = payload
        self.listener = listener
        self.messageMonitor = messageMonitor
        self.settings = settings
    }

    /// Call this API to hide the fullscreen message.
    /// This API hides the fullscreen message with an animation, but it keeps the view for future reappearances.
    public func hide() {
        DispatchQueue.main.async {
            if self.messageMonitor.dismiss() == false {
                return
            }
            self.dismissWithAnimation(shouldDeallocateView: false)
        }
    }

    /// Attempt to create and show the in-app message.
    public func show() {
        show(withMessagingDelegateControl: true)
    }

    public func show(withMessagingDelegateControl delegateControl: Bool) {
        // get off main thread while delegate has control to prevent pause on main thread
        DispatchQueue.global().async {
            // only show the message if the monitor allows it
            let (shouldShow, error) = self.messageMonitor.show(message: self, delegateControl: delegateControl)
            guard shouldShow else {
                if let error = error {
                    self.listener?.onError?(message: self, error: error)
                }
                return
            }

            // notify global listeners
            self.listener?.onShow(message: self)
            self.messagingDelegate?.onShow(message: self)

            // dispatch UI activity back to main thread
            DispatchQueue.main.async {
                self.showWithAnimation()
            }
        }
    }

    /// Call this API to dismiss the fullscreen message.
    /// This API removes the fullscreen message from memory.
    public func dismiss() {
        DispatchQueue.main.async {
            if self.messageMonitor.dismiss() == false {
                return
            }

            self.dismissWithAnimation(shouldDeallocateView: true)

            // notify all listeners
            self.listener?.onDismiss(message: self)
            self.messagingDelegate?.onDismiss(message: self)
        }
    }

    // MARK: - Private Methods

    private func showWithAnimation() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            Log.warning(label: LOG_PREFIX, "Unable to show message, root view controller is nil")
            return
        }

        // Apply MessageSettings where possible
        let rootView: AnyView = {
            var content: AnyView = AnyView(payload)

            // Corner radius
            if let radius = settings?.cornerRadius, radius > 0 {
                content = AnyView(content.cornerRadius(radius))
            }

            // Insets (interpreted as raw points)
            if let verticalInset = settings?.verticalInset {
                content = AnyView(content.padding(.vertical, CGFloat(verticalInset)))
            }
            if let horizontalInset = settings?.horizontalInset {
                content = AnyView(content.padding(.horizontal, CGFloat(horizontalInset)))
            }

            // Build backdrop color using
            let uiColor = settings?.getBackgroundColor() ?? UIColor.black
            let alpha = uiColor.cgColor.alpha

            // Convert UIColor to SwiftUI Color without using iOS14 API
            func color(from uic: UIColor) -> Color {
                let comps = uic.cgColor.components ?? [1, 1, 1, 1]
                let r = Double(comps[0])
                let g = Double(comps.count >= 3 ? comps[1] : comps[0])
                let b = Double(comps.count >= 3 ? comps[2] : comps[0])
                let a = Double(alpha)
                return Color(red: r, green: g, blue: b, opacity: a)
            }

            let swiftUIColor = color(from: uiColor)
            let needsBackdrop = (settings?.uiTakeover == true) || (alpha > 0)

            if needsBackdrop {
                return AnyView(
                    ZStack {
                        swiftUIColor.edgesIgnoringSafeArea(.all)
                        content
                    })
            }
            return content
        }()

        let hostingController = UIHostingController(rootView: rootView)
        hostingController.modalPresentationStyle = .fullScreen
        hostingController.view.backgroundColor = .clear

        rootViewController.present(hostingController, animated: true) {
            self.listener?.onShow(message: self)
        }
        self.hostingController = hostingController
    }

    private func dismissWithAnimation(shouldDeallocateView: Bool) {
        hostingController?.dismiss(animated: true) {
            if shouldDeallocateView {
                self.hostingController = nil
            }
        }
    }

    // MARK: - Frame Calculations

    private var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }

    private var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }

    private var frameBeforeShow: CGRect {
        return CGRect(x: 0, y: screenHeight, width: screenWidth, height: screenHeight)
    }

    private var frameWhenVisible: CGRect {
        return CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
    }

    private var frameAfterDismiss: CGRect {
        return CGRect(x: 0, y: -screenHeight, width: screenWidth, height: screenHeight)
    }
}
#endif
