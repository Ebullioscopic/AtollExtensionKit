import SwiftUI
import AtollExtensionKit

struct ContentView: View {

    // MARK: - State

    @State private var isAuthorized = false
    @State private var status = "Idle"

    @State private var demoProgress: Double = 0.35
    @State private var flightProgress: Double = 0.12

    // Liquid Glass Variant demo (0–19)
    @State private var liquidVariantValue: Int = 12

    private let client = AtollClient.shared

    private let activities = ActivityIDs()
    private let widgets = WidgetIDs()
    private let experiences = ExperienceIDs()

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                Text("AtollExtensionKit — Full API Playground")
                    .font(.title2)
                    .bold()

                Text("Status: \(status)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                authorizationSection

                Divider()

                liveActivitiesSection

                Divider()

                widgetsSection

                Divider()

                notchExperiencesSection
            }
            .padding()
        }
        .onAppear {
            Task {
                await checkAuthorization()
                registerCallbacks()
            }
        }
    }

    // MARK: - Callbacks

    private func registerCallbacks() {

        // ✅ Authorization changes
        client.onAuthorizationChange { authorized in
            DispatchQueue.main.async {
                self.isAuthorized = authorized
                self.status = authorized ? "Authorization changed ✅" : "Authorization revoked ❌"
            }
        }

        // ✅ Per-activity dismissal callback
        client.onActivityDismiss(activityID: activities.flight) {
            DispatchQueue.main.async {
                self.status = "Flight live activity dismissed by user"
            }
        }

        // ✅ Per-experience dismissal callback
        client.onNotchExperienceDismiss(experienceID: experiences.flightAnimation) {
            DispatchQueue.main.async {
                self.status = "Notch experience dismissed: Flight animation"
            }
        }
    }

    // MARK: - Sections

    private var authorizationSection: some View {
        GroupBox("Authorization") {
            VStack(spacing: 10) {
                Button("Request Authorization") {
                    Task { await requestAuthorization() }
                }
                Button("Check Authorization") {
                    Task { await checkAuthorization() }
                }

                Text(isAuthorized ? "✅ Authorized" : "❌ Not Authorized")
                    .font(.caption)
                    .foregroundColor(isAuthorized ? .green : .red)

                if client.isAtollInstalled == false {
                    Text("⚠️ Atoll not installed")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var liveActivitiesSection: some View {
        GroupBox("Live Activities (Present / Update / Dismiss)") {
            VStack(spacing: 10) {

                Text("Demo progress: \(Int(demoProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Present • Download (progressIndicator.percentage)") {
                    Task { await presentDownloadPercentage() }
                }

                Button("Update • Download (+10%)") {
                    Task { await updateDownloadPercentageAdvance() }
                }

                Button("Present • Pomodoro (countdown trailing)") {
                    Task { await presentPomodoroCountdownTrailing() }
                }

                Button("Present • News Marquee (trailing marquee)") {
                    Task { await presentNewsMarqueeTrailing() }
                }

                Button("Present • Icon Trailing") {
                    Task { await presentIconTrailingDemo() }
                }

                Button("Present • Spectrum Trailing") {
                    Task { await presentSpectrumTrailingDemo() }
                }

                Divider().padding(.vertical, 6)

                Text("Flight progress: \(Int(flightProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Present • Flight (RIGHT TEXT, no progress bar)") {
                    Task { await presentFlightLiveActivityTextRight() }
                }

                Button("Update • Flight (+10%)") {
                    Task { await updateFlightLiveActivityAdvance() }
                }

                Divider().padding(.vertical, 6)

                Button("Present • Indicator Ring") {
                    Task { await presentIndicatorRingDemo() }
                }
                Button("Present • Indicator Bar") {
                    Task { await presentIndicatorBarDemo() }
                }
                Button("Present • Indicator Countdown") {
                    Task { await presentIndicatorCountdownDemo() }
                }
                Button("Present • Indicator None") {
                    Task { await presentIndicatorNoneDemo() }
                }

                Divider().padding(.vertical, 6)

                Button("Present • Exclusive (musicCoexistence = false)") {
                    Task { await presentExclusiveDemo() }
                }
                Button("Present • Coexisting (musicCoexistence = true)") {
                    Task { await presentCoexistingDemo() }
                }

                Divider().padding(.vertical, 6)

                Button("Dismiss • Download") {
                    Task { await dismissLiveActivity(id: activities.download) }
                }

                Button("Dismiss • All Live Activities") {
                    Task { await dismissAllLiveActivities() }
                }
            }
            .frame(maxWidth: .infinity)
            .disabled(!isAuthorized)
        }
    }

    private var widgetsSection: some View {
        GroupBox("Lock Screen Widgets (All Layout Styles + Liquid Variant)") {
            VStack(spacing: 10) {

                // Liquid Glass Variant control
                VStack(alignment: .leading, spacing: 8) {
                    Text("Liquid Glass Variant: \(liquidVariantValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Stepper("Variant (0–19)", value: $liquidVariantValue, in: 0...19)
                        .font(.caption)

                    Slider(value: Binding(
                        get: { Double(liquidVariantValue) },
                        set: { liquidVariantValue = Int($0.rounded()) }
                    ), in: 0...19, step: 1)
                }
                .padding(.vertical, 6)

                Button("Present Widget • Inline") {
                    Task { await presentInlineWidget() }
                }

                Button("Present Widget • Card (liquid variant demo)") {
                    Task { await presentCardWidgetLiquidVariant() }
                }

                Button("Present Widget • Circular Gauge") {
                    Task { await presentCircularWidget() }
                }

                Button("Present Widget • Custom + WebView") {
                    Task { await presentCustomWebWidget() }
                }

                Button("Dismiss • All Widgets") {
                    Task { await dismissAllWidgets() }
                }
            }
            .frame(maxWidth: .infinity)
            .disabled(!isAuthorized)
        }
    }

    private var notchExperiencesSection: some View {
        GroupBox("Notch Experiences (Tab / Minimalistic / Web)") {
            VStack(spacing: 10) {

                Button("Present Notch Tab • Simple") {
                    Task { await presentSimpleTabExperience() }
                }

                Button("Present Minimalistic • Simple") {
                    Task { await presentMinimalisticOnlyExperience() }
                }

                Button("Present Tab + Minimalistic • Combined") {
                    Task { await presentCombinedExperience() }
                }

                Divider().padding(.vertical, 6)

                Button("Present Flight Animation • (Tab + Minimalistic, animation only)") {
                    Task { await presentFlightAnimationNotchExperience() }
                }

                Button("Update Flight Animation Notch (+10%)") {
                    Task { await updateFlightAnimationNotchExperienceAdvance() }
                }

                Divider().padding(.vertical, 6)

                Button("Dismiss Notch • Combined") {
                    Task { await dismissNotchExperience(id: experiences.combined) }
                }

                Button("Dismiss Notch • Flight Animation") {
                    Task { await dismissNotchExperience(id: experiences.flightAnimation) }
                }

                Button("Dismiss Notch • Simple Tab") {
                    Task { await dismissNotchExperience(id: experiences.simpleTab) }
                }

                Button("Dismiss Notch • Minimalistic Only") {
                    Task { await dismissNotchExperience(id: experiences.minimalisticOnly) }
                }
            }
            .frame(maxWidth: .infinity)
            .disabled(!isAuthorized)
        }
    }

    // MARK: - Authorization

    private func checkAuthorization() async {
        do {
            isAuthorized = try await client.checkAuthorization()
            status = isAuthorized ? "Authorized ✅" : "Not authorized ❌"
        } catch {
            status = "Authorization check failed: \(error.localizedDescription)"
        }
    }

    private func requestAuthorization() async {
        do {
            isAuthorized = try await client.requestAuthorization()
            status = isAuthorized ? "Authorization granted ✅" : "Authorization denied ❌"
        } catch {
            status = "Authorization request failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Live Activity Transport

    private func present(_ descriptor: AtollLiveActivityDescriptor) async {
        do {
            try await client.presentLiveActivity(descriptor)
            status = "Presented live activity: \(descriptor.id)"
        } catch {
            status = "Present failed: \(error.localizedDescription)"
        }
    }

    private func update(_ descriptor: AtollLiveActivityDescriptor) async {
        do {
            try await client.updateLiveActivity(descriptor)
            status = "Updated live activity: \(descriptor.id)"
        } catch {
            status = "Update failed: \(error.localizedDescription)"
        }
    }

    private func dismissLiveActivity(id: String) async {
        do {
            try await client.dismissLiveActivity(activityID: id)
            status = "Dismissed live activity: \(id)"
        } catch {
            status = "Dismiss failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Live Activities Demos

    private func presentDownloadPercentage() async {
        demoProgress = 0.35

        let descriptor = AtollLiveActivityDescriptor(
            id: activities.download,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .low,
            title: "Downloading",
            subtitle: "update-pkg-v2.dmg",
            leadingIcon: .symbol(name: "arrow.down.circle.fill"),
            trailingContent: .none,
            progressIndicator: .percentage(),
            progress: demoProgress,
            accentColor: .blue,
            allowsMusicCoexistence: true,

            // ✅ inline sneak peek deprecated → use standard + inheritUser
            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "Download",
            sneakPeekSubtitle: "\(Int(demoProgress * 100))% complete"
        )

        await present(descriptor)
    }

    private func updateDownloadPercentageAdvance() async {
        demoProgress = min(demoProgress + 0.10, 1.0)

        let descriptor = AtollLiveActivityDescriptor(
            id: activities.download,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .low,
            title: "Downloading",
            subtitle: "update-pkg-v2.dmg",
            leadingIcon: .symbol(name: "arrow.down.circle.fill"),
            trailingContent: .none,
            progressIndicator: .percentage(),
            progress: demoProgress,
            accentColor: .blue,
            allowsMusicCoexistence: true,

            // ✅
            centerTextStyle: .inheritUser,
            sneakPeekConfig: AtollSneakPeekConfig(
                enabled: true,
                duration: 3.0,
                style: .standard,
                showOnUpdate: true
            ),

            sneakPeekTitle: "Download",
            sneakPeekSubtitle: "\(Int(demoProgress * 100))% complete"
        )

        await update(descriptor)
    }

    private func presentPomodoroCountdownTrailing() async {
        let descriptor = AtollLiveActivityDescriptor(
            id: activities.pomodoro,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            title: "Focus",
            subtitle: "Pomodoro",
            leadingIcon: .symbol(name: "brain.head.profile"),
            trailingContent: .countdownText(
                targetDate: Date().addingTimeInterval(25 * 60),
                font: .monospacedDigit(size: 13, weight: .semibold)
            ),
            accentColor: .purple,
            allowsMusicCoexistence: true,

            // ✅ new recommendation
            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "Focus session",
            sneakPeekSubtitle: "25 min"
        )

        await present(descriptor)
    }

    private func presentNewsMarqueeTrailing() async {
        let descriptor = AtollLiveActivityDescriptor(
            id: activities.news,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "News",
            subtitle: "Top headlines",
            leadingIcon: .symbol(name: "newspaper.fill"),
            trailingContent: .marquee(
                "Markets rally • New release ships today • Weather clears…",
                font: .system(size: 12, weight: .semibold),
                minDuration: 0.6
            ),
            accentColor: .white,
            allowsMusicCoexistence: true,

            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "Headlines",
            sneakPeekSubtitle: "Latest updates"
        )

        await present(descriptor)
    }

    private func presentIconTrailingDemo() async {
        let descriptor = AtollLiveActivityDescriptor(
            id: activities.iconTrailing,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "Timer",
            subtitle: "Icon trailing",
            leadingIcon: .symbol(name: "timer"),
            trailingContent: .icon(.symbol(name: "checkmark.circle.fill")),
            accentColor: .green,
            allowsMusicCoexistence: true,

            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "Timer",
            sneakPeekSubtitle: "Icon trailing"
        )

        await present(descriptor)
    }

    private func presentSpectrumTrailingDemo() async {
        let descriptor = AtollLiveActivityDescriptor(
            id: activities.spectrum,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "Audio",
            subtitle: "Spectrum",
            leadingIcon: .symbol(name: "music.note"),
            trailingContent: .spectrum(color: .accent),
            accentColor: .white,
            allowsMusicCoexistence: true,

            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "Audio",
            sneakPeekSubtitle: "Monitoring"
        )

        await present(descriptor)
    }

    private func presentIndicatorRingDemo() async {
        demoProgress = 0.62

        let descriptor = AtollLiveActivityDescriptor(
            id: activities.indicator,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "Backup",
            subtitle: "Ring",
            leadingIcon: .symbol(name: "externaldrive.fill"),
            trailingContent: .none,
            progressIndicator: .ring(diameter: 26, strokeWidth: 3),
            progress: demoProgress,
            accentColor: .white,
            allowsMusicCoexistence: true,

            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "Backup",
            sneakPeekSubtitle: "\(Int(demoProgress * 100))%"
        )

        await present(descriptor)
    }

    private func presentIndicatorBarDemo() async {
        demoProgress = 0.47

        let descriptor = AtollLiveActivityDescriptor(
            id: activities.indicator,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "Export",
            subtitle: "Bar",
            leadingIcon: .symbol(name: "film.fill"),
            trailingContent: .none,
            progressIndicator: .bar(width: 90, height: 4),
            progress: demoProgress,
            accentColor: .orange,
            allowsMusicCoexistence: true,

            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "Export",
            sneakPeekSubtitle: "\(Int(demoProgress * 100))%"
        )

        await present(descriptor)
    }

    private func presentIndicatorCountdownDemo() async {
        let descriptor = AtollLiveActivityDescriptor(
            id: activities.indicator,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "Next Break",
            subtitle: "Countdown",
            leadingIcon: .symbol(name: "drop.fill"),
            trailingContent: .none,
            progressIndicator: .countdown(font: .monospacedDigit(size: 13, weight: .semibold)),
            progress: 0.0,
            accentColor: .blue,
            allowsMusicCoexistence: true,

            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "Break",
            sneakPeekSubtitle: "Soon"
        )

        await present(descriptor)
    }

    private func presentIndicatorNoneDemo() async {
        let descriptor = AtollLiveActivityDescriptor(
            id: activities.indicator,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "Indicator",
            subtitle: "None",
            leadingIcon: .symbol(name: "circle.slash"),
            trailingContent: .none,
            progressIndicator: .none,
            progress: 0.0,
            accentColor: .gray,
            allowsMusicCoexistence: true,

            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "Indicator",
            sneakPeekSubtitle: "None"
        )

        await present(descriptor)
    }

    private func presentExclusiveDemo() async {
        let descriptor = AtollLiveActivityDescriptor(
            id: activities.musicPolicy,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            title: "Timer",
            subtitle: "Exclusive slot",
            leadingIcon: .symbol(name: "timer"),
            trailingContent: .countdownText(
                targetDate: Date().addingTimeInterval(10 * 60),
                font: .monospacedDigit(size: 13, weight: .semibold)
            ),
            accentColor: .blue,
            allowsMusicCoexistence: false,

            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "Timer",
            sneakPeekSubtitle: "10 min"
        )

        await present(descriptor)
    }

    private func presentCoexistingDemo() async {
        let descriptor = AtollLiveActivityDescriptor(
            id: activities.musicPolicy,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "Podcast",
            subtitle: "Coexisting",
            leadingIcon: .symbol(name: "headphones"),
            trailingContent: .text("LIVE"),
            accentColor: .white,
            allowsMusicCoexistence: true,

            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "Podcast",
            sneakPeekSubtitle: "Playing"
        )

        await present(descriptor)
    }

    // MARK: - Flight Live Activity (right text)

    private func presentFlightLiveActivityTextRight() async {
        flightProgress = 0.12
        let percent = Int(flightProgress * 100)

        let descriptor = AtollLiveActivityDescriptor(
            id: activities.flight,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            title: "Flight",
            subtitle: "SFO → JFK",
            leadingIcon: .symbol(name: "airplane"),
            trailingContent: .text("\(percent)%"),
            accentColor: .white,
            allowsMusicCoexistence: true,

            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),

            sneakPeekTitle: "SFO → JFK",
            sneakPeekSubtitle: "In flight • \(percent)%"
        )

        await present(descriptor)
    }

    private func updateFlightLiveActivityAdvance() async {
        flightProgress = min(flightProgress + 0.10, 1.0)
        let percent = Int(flightProgress * 100)

        let descriptor = AtollLiveActivityDescriptor(
            id: activities.flight,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            title: "Flight",
            subtitle: "SFO → JFK",
            leadingIcon: .symbol(name: "airplane"),
            trailingContent: .text("\(percent)%"),
            accentColor: .white,
            allowsMusicCoexistence: true,

            centerTextStyle: .inheritUser,
            sneakPeekConfig: AtollSneakPeekConfig(
                enabled: true,
                duration: 3.0,
                style: .standard,
                showOnUpdate: true
            ),

            sneakPeekTitle: "SFO → JFK",
            sneakPeekSubtitle: "\(percent)% complete"
        )

        await update(descriptor)
    }

    // MARK: - Mass dismiss live activities

    private func dismissAllLiveActivities() async {
        let all = [
            activities.download,
            activities.pomodoro,
            activities.news,
            activities.iconTrailing,
            activities.spectrum,
            activities.indicator,
            activities.musicPolicy,
            activities.flight
        ]
        for id in all {
            try? await client.dismissLiveActivity(activityID: id)
        }
        status = "Dismissed all live activities"
    }

    // MARK: - Widgets

    private func presentInlineWidget() async {
        let widget = AtollLockScreenWidgetDescriptor(
            id: widgets.inline,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            layoutStyle: .inline,
            position: .init(alignment: .center, verticalOffset: 110),
            material: .frosted,
            content: [
                .icon(.symbol(name: "airplane.departure")),
                .spacer(height: 4),
                .text("Flight", font: .system(size: 15, weight: .semibold), color: .white),
                .spacer(height: 2),
                .text("SFO → JFK", font: .system(size: 13, weight: .regular), color: .white)
            ],
            accentColor: .accent,
            dismissOnUnlock: true,
            priority: .normal
        )

        do {
            try await client.presentLockScreenWidget(widget)
            status = "Presented widget: inline"
        } catch {
            status = "Widget present failed: \(error.localizedDescription)"
        }
    }

    // ✅ Updated to reflect new Liquid Glass Variant docs
    private func presentCardWidgetLiquidVariant() async {
        let variant = AtollLiquidGlassVariant(liquidVariantValue)

        let widget = AtollLockScreenWidgetDescriptor(
            id: widgets.card,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            layoutStyle: .card,
            position: .init(alignment: .leading, verticalOffset: -40, horizontalOffset: 50),
            size: CGSize(width: 270, height: 160),
            material: .liquid,
            appearance: .init(
                tintColor: .white,
                tintOpacity: 0.06,
                enableGlassHighlight: true,
                liquidGlassVariant: variant
            ),
            cornerRadius: 24,
            content: [
                .text("Charging", font: .system(size: 14, weight: .semibold), color: .white),
                .spacer(height: 6),
                .progress(.bar(width: 190, height: 4), value: 0.76, color: .green),
                .spacer(height: 8),
                .divider(color: .white, thickness: 1),
                .spacer(height: 8),
                .gauge(value: 0.76, minValue: 0, maxValue: 1, style: .circular, color: .green),
                .spacer(height: 6),
                .text("Variant \(liquidVariantValue)", font: .system(size: 12, weight: .regular), color: .white)
            ],
            accentColor: .accent,
            dismissOnUnlock: true,
            priority: .normal
        )

        do {
            try await client.presentLockScreenWidget(widget)
            status = "Presented widget: liquid variant \(liquidVariantValue)"
        } catch {
            status = "Widget present failed: \(error.localizedDescription)"
        }
    }

    private func presentCircularWidget() async {
        let widget = AtollLockScreenWidgetDescriptor(
            id: widgets.circular,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            layoutStyle: .circular,
            position: .init(alignment: .trailing, verticalOffset: 140, horizontalOffset: -70),
            material: .frosted,
            content: [
                .gauge(value: 0.55, minValue: 0, maxValue: 1, style: .circular, color: .accent)
            ],
            accentColor: .white,
            dismissOnUnlock: true,
            priority: .normal
        )

        do {
            try await client.presentLockScreenWidget(widget)
            status = "Presented widget: circular"
        } catch {
            status = "Widget present failed: \(error.localizedDescription)"
        }
    }

    private func presentCustomWebWidget() async {
        let html = """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
          <style>
            body { margin:0; background:transparent; font-family:-apple-system; color:white; }
            .row { display:flex; align-items:center; gap:10px; margin-bottom:10px; }
            .dot { width:10px; height:10px; border-radius:999px; background:rgba(0,200,255,0.95); }
            .title { font-size:13px; font-weight:600; opacity:0.85; }
            canvas { width:100%; height:70px; display:block; }
          </style>
        </head>
        <body>
          <div class="row">
            <div class="dot"></div>
            <div class="title">Realtime Sparkline</div>
          </div>
          <canvas id="c"></canvas>
          <script>
            const canvas = document.getElementById("c");
            const ctx = canvas.getContext("2d");
            let pts = Array.from({length: 20}, () => Math.random());

            function resize() {
              canvas.width = canvas.clientWidth * devicePixelRatio;
              canvas.height = canvas.clientHeight * devicePixelRatio;
            }
            resize();
            window.addEventListener("resize", resize);

            function tick() {
              pts.shift();
              pts.push(Math.random());

              ctx.clearRect(0,0,canvas.width,canvas.height);
              ctx.beginPath();
              ctx.lineWidth = 3 * devicePixelRatio;

              for (let i=0; i<pts.length; i++) {
                const x = (i/(pts.length-1)) * canvas.width;
                const y = canvas.height - pts[i] * canvas.height;
                if (i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
              }

              ctx.strokeStyle = "rgba(0,200,255,0.95)";
              ctx.stroke();
            }

            setInterval(tick, 450);
            tick();
          </script>
        </body>
        </html>
        """

        let widget = AtollLockScreenWidgetDescriptor(
            id: widgets.web,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            layoutStyle: .custom,
            position: .init(alignment: .center, verticalOffset: -140),
            size: CGSize(width: 320, height: 160),
            material: .clear,
            cornerRadius: 24,
            content: [
                .webView(.init(
                    html: html,
                    preferredHeight: 140,
                    isTransparent: true,
                    allowLocalhostRequests: false
                ))
            ],
            accentColor: .white,
            dismissOnUnlock: true,
            priority: .normal
        )

        do {
            try await client.presentLockScreenWidget(widget)
            status = "Presented widget: custom web"
        } catch {
            status = "Web widget present failed: \(error.localizedDescription)"
        }
    }

    private func dismissAllWidgets() async {
        let all = [widgets.inline, widgets.card, widgets.circular, widgets.web]
        for id in all {
            try? await client.dismissLockScreenWidget(widgetID: id)
        }
        status = "Dismissed all widgets"
    }

    // MARK: - Notch Experiences

    private func presentSimpleTabExperience() async {
        let descriptor = AtollNotchExperienceDescriptor(
            id: experiences.simpleTab,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            accentColor: .white,
            tab: .init(
                title: "Demo",
                iconSymbolName: "sparkles",
                preferredHeight: 190,
                sections: [
                    .init(
                        id: "one",
                        title: "Hello",
                        layout: .stack,
                        elements: [
                            .text("Notch tab demo", font: .system(size: 16, weight: .semibold), color: .white),
                            .text("Small, clean, valid.", font: .system(size: 12, weight: .regular), color: .white)
                        ]
                    )
                ],
                allowWebInteraction: false
            )
        )

        do {
            try await client.presentNotchExperience(descriptor)
            status = "Presented notch tab: simple"
        } catch {
            status = "Notch present failed: \(error.localizedDescription)"
        }
    }

    private func presentMinimalisticOnlyExperience() async {
        let descriptor = AtollNotchExperienceDescriptor(
            id: experiences.minimalisticOnly,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            accentColor: .white,
            minimalistic: .init(
                headline: "Minimalistic",
                subtitle: "Override demo",
                sections: [
                    .init(
                        id: "m",
                        layout: .metrics,
                        elements: [
                            .text("Mode", font: .system(size: 12, weight: .regular), color: .white),
                            .text("Active", font: .system(size: 14, weight: .semibold), color: .white)
                        ]
                    )
                ],
                layout: .metrics,
                hidesMusicControls: false
            )
        )

        do {
            try await client.presentNotchExperience(descriptor)
            status = "Presented minimalistic notch override"
        } catch {
            status = "Notch present failed: \(error.localizedDescription)"
        }
    }

    private func presentCombinedExperience() async {
        let descriptor = AtollNotchExperienceDescriptor(
            id: experiences.combined,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            accentColor: .white,
            tab: .init(
                title: "Combined",
                iconSymbolName: "square.stack.3d.up.fill",
                preferredHeight: 210,
                sections: [
                    .init(
                        id: "a",
                        title: "Metrics",
                        layout: .metrics,
                        elements: [
                            .text("CPU", font: .system(size: 12, weight: .regular), color: .white),
                            .text("21%", font: .monospacedDigit(size: 14, weight: .semibold), color: .white),
                            .text("RAM", font: .system(size: 12, weight: .regular), color: .white),
                            .text("8.3 GB", font: .monospacedDigit(size: 14, weight: .semibold), color: .white)
                        ]
                    )
                ],
                allowWebInteraction: false
            ),
            minimalistic: .init(
                headline: "Combined Demo",
                subtitle: "Tab + minimalistic",
                sections: [
                    .init(
                        id: "b",
                        layout: .stack,
                        elements: [
                            .text("Everything works.", font: .system(size: 13, weight: .semibold), color: .white)
                        ]
                    )
                ],
                layout: .stack,
                hidesMusicControls: false
            )
        )

        do {
            try await client.presentNotchExperience(descriptor)
            status = "Presented notch experience: combined"
        } catch {
            status = "Notch present failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Flight Animation Notch

    private func presentFlightAnimationNotchExperience() async {
        flightProgress = max(0.05, min(flightProgress, 0.95))
        let html = flightAnimationProfessionalHTML(progress01: flightProgress)

        let descriptor = AtollNotchExperienceDescriptor(
            id: experiences.flightAnimation,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            accentColor: .white,
            tab: .init(
                title: "Flight",
                iconSymbolName: "airplane.circle.fill",
                preferredHeight: 220,
                sections: [],
                webContent: .init(
                    html: html,
                    preferredHeight: 230,
                    isTransparent: true,
                    allowLocalhostRequests: false
                ),
                allowWebInteraction: false
            ),
            minimalistic: .init(
                headline: nil,
                subtitle: nil,
                sections: [],
                webContent: .init(
                    html: html,
                    preferredHeight: 155,
                    isTransparent: true,
                    allowLocalhostRequests: false
                ),
                layout: .custom,
                hidesMusicControls: false
            )
        )

        do {
            try await client.presentNotchExperience(descriptor)
            status = "Presented notch: flight animation"
        } catch {
            status = "Notch present failed: \(error.localizedDescription)"
        }
    }

    private func updateFlightAnimationNotchExperienceAdvance() async {
        flightProgress = min(flightProgress + 0.10, 1.0)
        let html = flightAnimationProfessionalHTML(progress01: flightProgress)

        let descriptor = AtollNotchExperienceDescriptor(
            id: experiences.flightAnimation,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            accentColor: .white,
            metadata: ["progress": "\(flightProgress)"],
            tab: .init(
                title: "Flight",
                iconSymbolName: "airplane.circle.fill",
                preferredHeight: 220,
                sections: [],
                webContent: .init(
                    html: html,
                    preferredHeight: 230,
                    isTransparent: true,
                    allowLocalhostRequests: false
                ),
                allowWebInteraction: false
            ),
            minimalistic: .init(
                headline: nil,
                subtitle: nil,
                sections: [],
                webContent: .init(
                    html: html,
                    preferredHeight: 155,
                    isTransparent: true,
                    allowLocalhostRequests: false
                ),
                layout: .custom,
                hidesMusicControls: false
            )
        )

        do {
            try await client.updateNotchExperience(descriptor)
            status = "Updated notch: flight animation"
        } catch {
            status = "Notch update failed: \(error.localizedDescription)"
        }
    }

    private func dismissNotchExperience(id: String) async {
        do {
            try await client.dismissNotchExperience(experienceID: id)
            status = "Dismissed notch experience: \(id)"
        } catch {
            status = "Dismiss notch failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Flight Web Animation (Professional + safe bottom padding)

    private func flightAnimationProfessionalHTML(progress01: Double) -> String {
        let p = max(0.0, min(progress01, 1.0))

        return """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
          <style>
            body { margin:0; background:transparent; overflow:hidden; }
            canvas { width:100%; height:100%; display:block; }
          </style>
        </head>
        <body>
          <canvas id="c"></canvas>
          <script>
            const canvas = document.getElementById("c");
            const ctx = canvas.getContext("2d");

            function resize() {
              canvas.width = canvas.clientWidth * devicePixelRatio;
              canvas.height = canvas.clientHeight * devicePixelRatio;
            }
            resize();
            window.addEventListener("resize", resize);

            let progress = \(p.toJSString());
            let t = 0;

            const planeSvg = `
            <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
              <path fill="white" d="M62 30c0-1.1-.9-2-2-2H39.7L26.9 9.8c-.4-.6-1.1-1-1.9-1H21c-1.1 0-2 .9-2 2v17.2L9.4 28l-3.1-7.2c-.3-.8-1.1-1.3-1.9-1.3H2c-1.1 0-2 .9-2 2v3l8 8-8 8v3c0 1.1.9 2 2 2h2.4c.8 0 1.6-.5 1.9-1.3L9.4 36l9.6 0v17.2c0 1.1.9 2 2 2h4c.8 0 1.5-.4 1.9-1L39.7 36H60c1.1 0 2-.9 2-2z"/>
            </svg>
            `;
            const planeImg = new Image();
            planeImg.src = "data:image/svg+xml;charset=utf-8," + encodeURIComponent(planeSvg);

            function quadBezier(p0, p1, p2, tt) {
              const x = (1-tt)*(1-tt)*p0.x + 2*(1-tt)*tt*p1.x + tt*tt*p2.x;
              const y = (1-tt)*(1-tt)*p0.y + 2*(1-tt)*tt*p1.y + tt*tt*p2.y;
              return {x,y};
            }

            function drawLabel(x, y, code, name, align) {
              ctx.save();
              ctx.textAlign = align;
              ctx.textBaseline = "top";
              ctx.font = `${12*devicePixelRatio}px -apple-system`;
              ctx.fillStyle = "rgba(255,255,255,0.92)";
              ctx.fillText(code, x, y);
              ctx.font = `${10.5*devicePixelRatio}px -apple-system`;
              ctx.fillStyle = "rgba(255,255,255,0.65)";
              ctx.fillText(name, x, y + 14*devicePixelRatio);
              ctx.restore();
            }

            function draw() {
              ctx.clearRect(0,0,canvas.width,canvas.height);

              const w = canvas.width;
              const h = canvas.height;

              const padX = 26 * devicePixelRatio;

              // ✅ extra bottom space so labels never get clipped
              const bottomSafe = 34 * devicePixelRatio;

              // ✅ lift route above bottom edge
              const baseY = h - bottomSafe - (10 * devicePixelRatio);

              const left = { x: padX, y: baseY };
              const right = { x: w - padX, y: baseY };
              const control = { x: w * 0.5, y: h * 0.16 };

              // soft base line
              ctx.save();
              ctx.beginPath();
              ctx.moveTo(left.x, left.y);
              ctx.quadraticCurveTo(control.x, control.y, right.x, right.y);
              ctx.strokeStyle = "rgba(255,255,255,0.14)";
              ctx.lineWidth = 6 * devicePixelRatio;
              ctx.lineCap = "round";
              ctx.stroke();
              ctx.restore();

              // dotted overlay
              ctx.save();
              ctx.beginPath();
              ctx.moveTo(left.x, left.y);
              ctx.quadraticCurveTo(control.x, control.y, right.x, right.y);
              ctx.strokeStyle = "rgba(255,255,255,0.32)";
              ctx.lineWidth = 2.2 * devicePixelRatio;
              ctx.setLineDash([5*devicePixelRatio, 8*devicePixelRatio]);
              ctx.lineCap = "round";
              ctx.stroke();
              ctx.restore();

              // endpoints
              function drawEndpoint(pt) {
                ctx.beginPath();
                ctx.arc(pt.x, pt.y, 14*devicePixelRatio, 0, Math.PI*2);
                ctx.fillStyle = "rgba(0,200,255,0.16)";
                ctx.fill();

                ctx.beginPath();
                ctx.arc(pt.x, pt.y, 6*devicePixelRatio, 0, Math.PI*2);
                ctx.fillStyle = "rgba(255,255,255,0.92)";
                ctx.fill();
              }

              drawEndpoint(left);
              drawEndpoint(right);

              // labels under circles
              drawLabel(left.x, left.y + 14*devicePixelRatio, "SFO", "Boarding", "left");
              drawLabel(right.x, right.y + 14*devicePixelRatio, "JFK", "Arrivals", "right");

              // plane
              const microDrift = 0.012 * Math.sin(t * 0.9);
              const pp = Math.max(0.0, Math.min(1.0, progress + microDrift));

              const pos = quadBezier(left, control, right, pp);
              const ahead = quadBezier(left, control, right, Math.min(1.0, pp + 0.01));
              const angle = Math.atan2(ahead.y - pos.y, ahead.x - pos.x);

              const size = 24 * devicePixelRatio;

              ctx.save();
              ctx.translate(pos.x, pos.y);
              ctx.rotate(angle);

              ctx.beginPath();
              ctx.arc(0,0, 16*devicePixelRatio, 0, Math.PI*2);
              ctx.fillStyle = "rgba(0,200,255,0.18)";
              ctx.fill();

              if (planeImg.complete) {
                ctx.globalAlpha = 0.96;
                ctx.drawImage(planeImg, -size/2, -size/2, size, size);
                ctx.globalAlpha = 1.0;
              }

              ctx.restore();

              t += 0.04;
              requestAnimationFrame(draw);
            }

            draw();
          </script>
        </body>
        </html>
        """
    }
}

private extension Double {
    func toJSString() -> String {
        String(format: "%.4f", self)
    }
}

// MARK: - IDs

private struct ActivityIDs {
    let download = "activity.download"
    let pomodoro = "activity.pomodoro"
    let news = "activity.news"
    let iconTrailing = "activity.trailing.icon"
    let spectrum = "activity.trailing.spectrum"
    let indicator = "activity.indicator.demo"
    let musicPolicy = "activity.music.policy.demo"
    let flight = "activity.flight.demo"
}

private struct WidgetIDs {
    let inline = "widget.inline.demo"
    let card = "widget.card.demo"
    let circular = "widget.circular.demo"
    let web = "widget.web.demo"
}

private struct ExperienceIDs {
    let simpleTab = "experience.tab.simple"
    let minimalisticOnly = "experience.minimalistic.only"
    let combined = "experience.combined"
    let flightAnimation = "experience.flight.animation"
}
