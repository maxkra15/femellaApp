import SwiftUI
import MapKit
import CoreLocation

struct EventDetailView: View {
    let event: Event
    let eventsVM: EventsViewModel
    @State private var isProcessing: Bool = false
    @State private var showDeregisterAlert: Bool = false
    @State private var mapRegion: MKCoordinateRegion?

    private var displayedEvent: Event {
        eventsVM.events.first(where: { $0.id == event.id }) ?? event
    }

    private var registration: EventRegistration? {
        eventsVM.registrationFor(eventId: displayedEvent.id)
    }

    private var isRegistered: Bool {
        registration != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage

                VStack(alignment: .leading, spacing: FemSpacing.xl) {
                    headerSection
                    detailsSection
                    descriptionSection
                    if displayedEvent.registeredCount > 0 {
                        attendeesSection
                    }
                    mapSection
                    ctaButton
                }
                .padding(FemSpacing.lg)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(FemColor.ivory.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert("Deregister from Event", isPresented: $showDeregisterAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Deregister", role: .destructive) {
                Task { await deregister() }
            }
        } message: {
            Text("Are you sure you want to deregister from \"\(displayedEvent.title)\"?")
        }
        .task {
            await geocodeAddress()
        }
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        Color(FemColor.ivory)
            .frame(height: 260)
            .overlay {
                CachedAsyncImage(url: displayedEvent.heroImageURL) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    }
                }
                .allowsHitTesting(false)
            }
            .clipped()
            .overlay(alignment: .bottomLeading) {
                LinearGradient(
                    stops: [.init(color: .clear, location: 0.3), .init(color: .black.opacity(0.6), location: 1.0)],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(displayedEvent.category.rawValue)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(categoryColor.opacity(0.9))
                            .clipShape(Capsule())

                        if !displayedEvent.isFree {
                            Text(displayedEvent.priceDisplay)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }

                    Text(displayedEvent.title)
                        .font(FemFont.display(24))
                        .foregroundStyle(.white)
                }
                .padding(FemSpacing.lg)
            }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            if !displayedEvent.hostName.isEmpty {
                Label("Hosted by \(displayedEvent.hostName)", systemImage: "person.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(FemColor.darkBlue.opacity(0.6))
            }
            Spacer()
            if isRegistered {
                StatusBadge(
                    text: registration?.status == .waitlisted ? "Waitlisted" : "Registered",
                    color: registration?.status == .waitlisted ? FemColor.orangeRed : FemColor.green
                )
            }
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(spacing: 0) {
            detailRow(
                icon: "calendar",
                color: FemColor.pink,
                title: displayedEvent.startsAt.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
            )

            Divider().padding(.leading, 52)

            detailRow(
                icon: "clock",
                color: FemColor.lightBlue,
                title: "\(displayedEvent.startsAt.formatted(.dateTime.hour().minute())) – \(displayedEvent.endsAt.formatted(.dateTime.hour().minute()))"
            )

            Divider().padding(.leading, 52)

            detailRow(
                icon: "mappin.circle.fill",
                color: FemColor.orangeRed,
                title: displayedEvent.locationName,
                subtitle: displayedEvent.address
            )

            Divider().padding(.leading, 52)

            detailRow(
                icon: "person.2.fill",
                color: FemColor.green,
                title: "\(displayedEvent.registeredCount)/\(displayedEvent.capacity) registered",
                subtitle: displayedEvent.waitlistCount > 0 ? "\(displayedEvent.waitlistCount) on waitlist" : nil
            )

            if displayedEvent.isNonDeregisterable {
                Divider().padding(.leading, 52)
                HStack(spacing: 12) {
                    Circle()
                        .fill(FemColor.orangeRed.opacity(0.1))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "lock.fill")
                                .font(.subheadline)
                                .foregroundStyle(FemColor.orangeRed)
                        }

                    Text("Non-deregisterable event")
                        .font(.subheadline)
                        .foregroundStyle(FemColor.orangeRed)
                }
                .padding(.vertical, FemSpacing.sm)
            }
        }
        .padding(FemSpacing.lg)
        .background(FemColor.cardBackground)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: FemColor.darkBlue.opacity(0.04), radius: 8, y: 4)
    }

    private func detailRow(icon: String, color: Color, title: String, subtitle: String? = nil) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(color)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FemColor.darkBlue)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(FemColor.darkBlue.opacity(0.5))
                }
            }

            Spacer()
        }
        .padding(.vertical, FemSpacing.sm)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(FemFont.title(18))
                .foregroundStyle(FemColor.darkBlue)
            Text(displayedEvent.description)
                .font(.body)
                .foregroundStyle(FemColor.darkBlue.opacity(0.7))
        }
    }

    // MARK: - Attendees

    private var attendeesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attendees")
                .font(FemFont.title(18))
                .foregroundStyle(FemColor.darkBlue)

            HStack(spacing: -8) {
                ForEach(0..<min(5, displayedEvent.registeredCount), id: \.self) { i in
                    Circle()
                        .fill(FemColor.pink.opacity(Double(5 - i) * 0.15 + 0.2))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text(String(Character(UnicodeScalar(65 + i % 26)!)))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(FemColor.darkBlue)
                        }
                        .overlay(Circle().stroke(FemColor.cardBackground, lineWidth: 2))
                }
                if displayedEvent.registeredCount > 5 {
                    Circle()
                        .fill(FemColor.ivory)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text("+\(displayedEvent.registeredCount - 5)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(FemColor.darkBlue.opacity(0.5))
                        }
                        .overlay(Circle().stroke(FemColor.cardBackground, lineWidth: 2))
                }
            }
        }
    }

    // MARK: - Map (geocoded from address)

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(FemFont.title(18))
                .foregroundStyle(FemColor.darkBlue)

            if let region = mapRegion {
                Map(initialPosition: .region(region)) {
                    Marker(displayedEvent.locationName, coordinate: region.center)
                        .tint(FemColor.pink)
                }
                .frame(height: 180)
                .clipShape(.rect(cornerRadius: 20))
                .allowsHitTesting(false)
            } else {
                // Loading or geocoding fallback
                RoundedRectangle(cornerRadius: 20)
                    .fill(FemColor.cardBackground)
                    .frame(height: 180)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "map")
                                .font(.title)
                                .foregroundStyle(FemColor.darkBlue.opacity(0.2))
                            Text("Loading map...")
                                .font(.caption)
                                .foregroundStyle(FemColor.darkBlue.opacity(0.3))
                        }
                    }
            }

            // Tappable address that opens Apple Maps
            Button {
                openInMaps()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .foregroundStyle(FemColor.pink)
                    Text(displayedEvent.address)
                        .font(.caption)
                        .foregroundStyle(FemColor.darkBlue.opacity(0.6))
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(FemColor.darkBlue.opacity(0.3))
                }
            }
        }
    }

    // MARK: - CTA

    @ViewBuilder
    private var ctaButton: some View {
        if displayedEvent.isPast {
            StatusBadge(text: "Event Ended", color: .secondary)
                .frame(maxWidth: .infinity)
        } else if isRegistered && !displayedEvent.isNonDeregisterable {
            Button {
                showDeregisterAlert = true
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Deregister")
                }
                .font(.headline)
                .foregroundStyle(FemColor.orangeRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FemColor.orangeRed.opacity(0.1))
                .clipShape(Capsule())
            }
        } else if isRegistered {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("You're registered!")
            }
            .font(.headline)
            .foregroundStyle(FemColor.green)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(FemColor.green.opacity(0.1))
            .clipShape(Capsule())
        } else {
            Button {
                Task { await registerForEvent() }
            } label: {
                Group {
                    if isProcessing {
                        ProgressView().tint(.white)
                    } else if displayedEvent.isFull {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                            Text("Join Waitlist")
                        }
                    } else if displayedEvent.isFree {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Sign Up")
                        }
                    } else {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Pay & Sign Up")
                        }
                    }
                }
                .femPrimaryButton(isEnabled: !isProcessing)
            }
            .disabled(isProcessing)
        }

        Spacer().frame(height: FemSpacing.lg)
    }

    // MARK: - Helpers

    private var categoryColor: Color {
        switch displayedEvent.category {
        case .connect: FemColor.pink
        case .learn: FemColor.lightBlue
        case .grow: FemColor.green
        }
    }

    private func geocodeAddress() async {
        let addressString = [displayedEvent.locationName, displayedEvent.address]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        guard !addressString.isEmpty else { return }

        // If we already have valid coordinates from the database, use those
        if displayedEvent.latitude != 0 || displayedEvent.longitude != 0 {
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: displayedEvent.latitude, longitude: displayedEvent.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
            return
        }

        // Otherwise, use MKLocalSearch to find the coordinates
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = addressString
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            if let mapItem = response.mapItems.first {
                let location: CLLocation? = mapItem.location
                if let coordinate = location?.coordinate {
                    await MainActor.run {
                        self.mapRegion = MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                        )
                    }
                }
            }
        } catch {
            print("Geocoding failed: \(error.localizedDescription)")
        }
    }

    private func openInMaps() {
        let address = displayedEvent.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(address)") {
            UIApplication.shared.open(url)
        }
    }

    private func registerForEvent() async {
        isProcessing = true
        await eventsVM.registerForEvent(displayedEvent)
        isProcessing = false
    }

    private func deregister() async {
        isProcessing = true
        await eventsVM.deregisterFromEvent(displayedEvent)
        isProcessing = false
    }
}
