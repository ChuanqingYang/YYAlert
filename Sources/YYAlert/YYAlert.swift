// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

// Alert Config
@available(iOS 17.0, *)
public struct AlertConfig {
    public var enableBackgroundBlur: Bool = true
    public var disableOutsideTap: Bool = false
    
    public var transitionType: TransitionType = .side
    public var slideEdge: Edge = .bottom
    
    // auto-dismiss
    public var autoDismiss: Bool = false
    public var autoDismissInterval: TimeInterval = 1
    
    fileprivate var showAlert: Bool = false
    /// for dismiss the view with same animation and also can
    ///  animate the alert in or out from outside the AlertView
    fileprivate var showView: Bool = false
    
    
    public init(enableBackgroundBlur: Bool = true,
         disableOutsideTap: Bool = true,
         transitionType: TransitionType = .side ,
         slideEdge: Edge = .bottom,
         autoDismiss: Bool = false,
         autoDismissInterval: TimeInterval = 1
    ) {
        self.enableBackgroundBlur = enableBackgroundBlur
        self.disableOutsideTap = disableOutsideTap
        self.transitionType = transitionType
        self.slideEdge = slideEdge
        self.autoDismiss = autoDismiss
        self.autoDismissInterval = autoDismissInterval
    }
    
    public enum TransitionType {
        case side
        case opacity
    }
    
    public mutating
    func present() {
        showAlert = true
    }
    
    public mutating
    func dismiss() {
        showAlert = false
    }
}

/// AppDelegate for add new windown for alert
/// so we can put the alert on top of our scene

/// The reason for use of observable is that this will automatically inject this object as an Environment Object
/// in our SwiftUI Lifecycle, and then we can use it directly inside our SwiftUI Views.
///
@available(iOS 17.0, *)
@Observable
public class AppDelegate: NSObject,UIApplicationDelegate {
    public func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        /// Setting SceneDelegate Class
        config.delegateClass = SceneDelegate.self
        return config
    }
}

@available(iOS 17.0, *)
@Observable
public class SceneDelegate: NSObject,UIWindowSceneDelegate {
    
    // Current Scene
    weak var windowScene: UIWindowScene?
    /// Alert Window
    var overlayWindow: UIWindow?
    /// Alert Tag
    var tag: Int = 0
    /// for saving muti-alerts
    var alerts:[UIView] = []
    
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        windowScene = scene as? UIWindowScene
        
        setupOverlayWindow()
    }
    
    /// Adding overlay window to handle all our alerts on the top of the current window
    func setupOverlayWindow() {
        guard let windowScene = windowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.isHidden = true
        window.isUserInteractionEnabled = false
        self.overlayWindow = window
    }
    
    
    /// The ViewTag closure will return the appropriate tag for the added alert view
    ///  and with that, we can remove the alert in some complex cases
    fileprivate func alert<Content: View>(
        config: Binding<AlertConfig>,
        @ViewBuilder content: @escaping () -> Content,
        viewTag: @escaping (Int) -> ()
    ) {
        guard let alertWindow = overlayWindow else { return }
        
       let viewController = UIHostingController(
        // TODO: - Content
        rootView:AlertView(tag: tag, config: config, content: content)
       )
        viewController.view.backgroundColor = .clear
        viewController.view.tag = tag
        viewTag(tag)
        /// Since each tag must be unique for each view,it's incremented for each alert.
        tag += 1
        
        if alertWindow.rootViewController == nil {
            alertWindow.rootViewController = viewController
            alertWindow.isHidden = false
            alertWindow.isUserInteractionEnabled = true
        }else {
//            print("Exisiting Alert is Still Present")
            viewController.view.frame = alertWindow.rootViewController?.view.frame ?? .zero
            alerts.append(viewController.view)
        }
    }
}

@available(iOS 17.0, *)
fileprivate struct AlertView<Content: View> : View {
    
    var tag: Int
    @Binding var config: AlertConfig
    @ViewBuilder var content: () -> Content
    
    /// for animation purpose
    @State private var showView: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            
            /// for background
            ZStack {
                if config.enableBackgroundBlur {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }else {
                    Rectangle()
                        .fill(.primary.opacity(0.25))
                }
            }
            .ignoresSafeArea()
            .contentShape(.rect)
            .onTapGesture {
                if !config.disableOutsideTap {
                    config.dismiss()
                }
            }
            .opacity(showView ? 1 : 0)
            
            /// for content
            if showView && config.transitionType == .side {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.move(edge: config.slideEdge))
            }else {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(showView ? 1 : 0)
            }
        }
        .onAppear {
            config.showView = true
            
            if config.autoDismiss {
                DispatchQueue.main.asyncAfter(deadline: .now() + config.autoDismissInterval) {
                    config.dismiss()
                }
            }
        }
        .onChange(of: config.showView) { oldValue, newValue in
            withAnimation(.smooth(duration: 0.35, extraBounce: 0)) {
                showView = newValue
            }
        }
    }
}

///  The modifier will handles the present and dismiss actions for the alert
@available(iOS 17.0, *)
fileprivate struct AlertModifier<AlertContent: View>: ViewModifier {
    @Binding var config: AlertConfig
    @ViewBuilder var alertContent: () -> AlertContent
    @Environment(SceneDelegate.self) private var sceneDelegate
    @State private var viewTag: Int = 0
    func body(content: Content) -> some View {
        content
            .onChange(of: config.showAlert) { oldValue, newValue in
                if newValue {
                    sceneDelegate.alert(config: $config, content: alertContent) { tag in
                        viewTag = tag
                    }
                }else {
                    guard let alertWindow = sceneDelegate.overlayWindow else { return }
                    /// view hide logic
                    if config.showView {
                        withAnimation(.smooth(duration: 0.35, extraBounce: 0)) {
                            config.showView = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            if sceneDelegate.alerts.isEmpty {
                                alertWindow.rootViewController = nil
                                alertWindow.isHidden = true
                                alertWindow.isUserInteractionEnabled = false
                            }else {
                                if let first = sceneDelegate.alerts.first {
                                    alertWindow.rootViewController?.view.subviews.forEach({ view in
                                        view.removeFromSuperview()
                                    })
                                    
                                    alertWindow.rootViewController?.view.addSubview(first)
                                    sceneDelegate.alerts.removeFirst()
                                }
                            }
                        }
                    }else {
                        sceneDelegate.alerts.removeAll(where: {$0.tag == viewTag })
                    }
                }
            }
    }
}

@available(iOS 17.0, *)
extension View {
    @ViewBuilder
    public func alert<Content: View>(alertConfig: Binding<AlertConfig>, @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(AlertModifier(config: alertConfig, alertContent: content))
    }
}
