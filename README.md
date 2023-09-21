# YYAlert
## An Alert View Shows On The Top Of The Window
> Only Support iOS 17.0+

- Step 1
    Set Delegate In your ApplicationMain Strut
    ```
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    ```
- Step 2
  Set AlertConfig with your prefered style in your `View`
  ```
  @State private var alert: AlertConfig = .init(disableOutsideTap: false,transitionType:.opacity)
  ```
- Step 3
  Use `.alert` modifier where you want and custom your own alert style.
  ```
            Button("Show Alert") {
                /// Show Alert
                alert.present()
            }
            .alert(alertConfig: $alert) {
                /// Your custom alert style
                Rectangle()
                    .fill(.red.gradient)
                    .frame(width: 100, height: 100)
                    .contentShape(.rect)
                    .onTapGesture {
                        /// Dismiss Alert
                        alert.dismiss()
                    }
            }
  ```
