import SwiftUI
import MapKit
import CoreLocation

struct EventDetailView: View {
    let event: Event
    let eventsVM: EventsViewModel
    @State private var isProcessing: Bool = false
    @State private var showDeregisterAlert: Bool = false
    @State private var mapRegion: MKCoordinateRegion?

    private var registration: EventRegistration? {
        eventsVM.registrationFor(eventId: event.id)
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
                    if event.registeredCount > 0 {
                        attendeesSection
                    }
                    mapSection
                    ctaButton
                }
                .padding(FemSpacing.lg)
            }
        }
        .background(FemColor.ivory.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert("Deregister from Event", isPresented: $showDeregisterAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Deregister", role: .destructive) {
                Task { await deregister() }
            }
        } message: {
            Text("Are you sure you want to deregister from \"\(event.title)\"?")
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
                AsyncImage(url: event.heroImageURL) { phase in
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
                        Text(event.category.rawValue)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(categoryColor.opacity(0.9))
                            .clipShape(Capsule())

                        if !event.isFree {
                            Text(event.priceDisplay)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }

                    Text(event.title)
                        .font(FemFont.display(24))
                        .foregroundStyle(.white)
                }
                .padding(FemSpacing.lg)
            }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            if !event.hostName.isEmpty {
                Label("Hosted by \(event.hostName)", systemImage: "person.circle.fill")
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
                title: event.startsAt.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
            )

            Divider().padding(.leading, 52)

            detailRow(
                icon: "clock",
                color: FemColor.lightBlue,
                title: "\(event.startsAt.formatted(.dateTime.hour().minute())) – \(event.endsAt.formatted(.dateTime.hour().minute()))"
            )

            Divider().padding(.leading, 52)

            detailRow(
                icon: "mappin.circle.fill",
                color: FemColor.orangeRed,
                title: event.locationName,
                subtitle: event.address
            )

            Divider().padding(.leading, 52)

            detailRow(
                icon: "person.2.fill",
                color: FemColor.green,
                title: "\(event.registeredCount)/\(event.capacity) registered",
                subtitle: event.waitlistCount > 0 ? "\(event.waitlistCount) on waitlist" : nil
            )

            if event.isNonDeregisterable {
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
            Text(event.description)
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
                ForEach(0..<min(5, event.registeredCount), id: \.self) { i in
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
                if event.registeredCount > 5 {
                    Circle()
                        .fill(FemColor.ivory)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text("+\(event.registeredCount - 5)")
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
                    Marker(event.locationName, coordinate: region.center)
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
                    Text(event.address)
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
        if event.isPast {
            StatusBadge(text: "Event Ended", color: .secondary)
                .frame(maxWidth: .infinity)
        } else if isRegistered && !event.isNonDeregisterable {
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
                    } else if event.isFull {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                            Text("Join Waitlist")
                        }
                    } else if event.isFree {
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
        switch event.category {
        case .connect: FemColor.pink
        case .learn: FemColor.lightBlue
        case .grow: FemColor.green
        }
    }

    private func geocodeAddress() async {
        let addressString = [event.locationName, event.address]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        guard !addressString.isEmpty else { return }

        // If we already have valid coordinates from the database, use those
        if event.latitude != 0 || event.longitude != 0 {
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
            return
        }

        // Otherwise, geocode the address string
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(addressString)
            if let location = placemarks.first?.location {
                await MainActor.run {
                    mapRegion = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                    )
                }
            }
        } catch {
            print("Geocoding failed: \(error.localizedDescription)")
        }
    }

    private func openInMaps() {
        let address = event.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(address)") {
            UIApplication.shared.open(url)
        }
    }

    private func registerForEvent() async {
        isProcessing = true
        await eventsVM.registerForEvent(event)
        isProcessing = false
    }

    private func deregister() async {
        isProcessing = true
        await eventsVM.deregisterFromEvent(event)
        isProcessing = false
    }
}
