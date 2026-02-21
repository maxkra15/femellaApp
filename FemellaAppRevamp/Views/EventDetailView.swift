import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: Event
    let eventsVM: EventsViewModel
    @State private var isProcessing: Bool = false
    @State private var showDeregisterAlert: Bool = false

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
                    attendeesSection
                    mapSection
                    ctaButton
                }
                .padding(FemSpacing.lg)
            }
        }
        .background(FemColor.blush.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert("Deregister from Event", isPresented: $showDeregisterAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Deregister", role: .destructive) {
                Task { await deregister() }
            }
        } message: {
            Text("Are you sure you want to deregister from \"\(event.title)\"?")
        }
    }

    private var heroImage: some View {
        Color(.secondarySystemBackground)
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
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(event.category.rawValue)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(categoryColor.opacity(0.8))
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
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                .padding(FemSpacing.lg)
            }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Hosted by \(event.hostName)", systemImage: "person.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if isRegistered {
                    StatusBadge(
                        text: registration?.status == .waitlisted ? "Waitlisted" : "Registered",
                        color: registration?.status == .waitlisted ? .orange : FemColor.success
                    )
                }
            }
        }
    }

    private var detailsSection: some View {
        VStack(spacing: FemSpacing.md) {
            DetailRow(icon: "calendar", title: "Date", value: event.startsAt.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
            DetailRow(icon: "clock", title: "Time", value: "\(event.startsAt.formatted(.dateTime.hour().minute())) – \(event.endsAt.formatted(.dateTime.hour().minute()))")
            DetailRow(icon: "mappin.circle", title: "Location", value: "\(event.locationName)\n\(event.address)")
            DetailRow(icon: "person.2", title: "Capacity", value: "\(event.registeredCount)/\(event.capacity) registered" + (event.waitlistCount > 0 ? " · \(event.waitlistCount) waitlisted" : ""))

            if event.isNonDeregisterable {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(FemColor.danger)
                    Text("Non-deregisterable event")
                        .font(.caption)
                        .foregroundStyle(FemColor.danger)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FemColor.danger.opacity(0.08))
                .clipShape(.rect(cornerRadius: 10))
            }
        }
        .padding(FemSpacing.lg)
        .background(FemColor.cardBackground)
        .clipShape(.rect(cornerRadius: 16))
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
                .foregroundStyle(FemColor.navy)
            Text(event.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var attendeesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attendees")
                .font(.headline)
                .foregroundStyle(FemColor.navy)

            HStack(spacing: -8) {
                ForEach(0..<min(5, event.registeredCount), id: \.self) { i in
                    Circle()
                        .fill(FemColor.accentPink.opacity(Double(5 - i) * 0.15 + 0.2))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text(String(Character(UnicodeScalar(65 + i % 26)!)))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(FemColor.accentPinkDark)
                        }
                        .overlay(Circle().stroke(FemColor.cardBackground, lineWidth: 2))
                }
                if event.registeredCount > 5 {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text("+\(event.registeredCount - 5)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .overlay(Circle().stroke(FemColor.cardBackground, lineWidth: 2))
                }
            }
        }
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)
                .foregroundStyle(FemColor.navy)

            Map(initialPosition: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))) {
                Marker(event.locationName, coordinate: CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude))
                    .tint(FemColor.accentPink)
            }
            .frame(height: 180)
            .clipShape(.rect(cornerRadius: 16))
            .allowsHitTesting(false)

            Text(event.address)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

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
                .foregroundStyle(FemColor.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FemColor.danger.opacity(0.1))
                .clipShape(.rect(cornerRadius: 14))
            }
        } else if isRegistered {
            Text("You're registered!")
                .font(.headline)
                .foregroundStyle(FemColor.success)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FemColor.success.opacity(0.1))
                .clipShape(.rect(cornerRadius: 14))
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
            .sensoryFeedback(.impact(weight: .medium), trigger: isProcessing)
        }

        Spacer().frame(height: FemSpacing.lg)
    }

    private var categoryColor: Color {
        switch event.category {
        case .connect: FemColor.accentPink
        case .learn: FemColor.ctaBlue
        case .grow: FemColor.success
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

private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(FemColor.accentPink)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
    }
}
