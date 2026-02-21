import Foundation

struct MockDataService {
    static let hubs: [Hub] = [
        Hub(id: "hub-zurich", name: "Zurich", country: "Switzerland", timezone: "Europe/Zurich", currency: "CHF", membershipPriceFormatted: "CHF 150.00", deregistrationDeadlineHours: 48, waitlistAutoPromoteCutoffHours: 24, defaultNoShowFeeAmount: 25, isActive: true),
        Hub(id: "hub-london", name: "London", country: "United Kingdom", timezone: "Europe/London", currency: "GBP", membershipPriceFormatted: "GBP 120.00", deregistrationDeadlineHours: 48, waitlistAutoPromoteCutoffHours: 24, defaultNoShowFeeAmount: 20, isActive: true),
        Hub(id: "hub-copenhagen", name: "Copenhagen", country: "Denmark", timezone: "Europe/Copenhagen", currency: "DKK", membershipPriceFormatted: "DKK 1,100.00", deregistrationDeadlineHours: 48, waitlistAutoPromoteCutoffHours: 24, defaultNoShowFeeAmount: 150, isActive: true),
        Hub(id: "hub-berlin", name: "Berlin", country: "Germany", timezone: "Europe/Berlin", currency: "EUR", membershipPriceFormatted: "EUR 130.00", deregistrationDeadlineHours: 48, waitlistAutoPromoteCutoffHours: 24, defaultNoShowFeeAmount: 20, isActive: true),
        Hub(id: "hub-munich", name: "Munich", country: "Germany", timezone: "Europe/Berlin", currency: "EUR", membershipPriceFormatted: "EUR 130.00", deregistrationDeadlineHours: 48, waitlistAutoPromoteCutoffHours: 24, defaultNoShowFeeAmount: 20, isActive: true),
    ]

    static let sampleUser = UserProfile(
        id: "user-1",
        firstName: "Anna",
        lastName: "Mueller",
        email: "anna@example.com",
        phone: "+41 79 123 4567",
        university: "ETH Zurich",
        degree: "MSc Computer Science",
        company: "UBS",
        jobTitle: "Product Manager",
        homeHubId: "hub-zurich",
        avatarURL: nil,
        showProfileToMembers: true
    )

    static let sampleMembership = Membership(
        id: "mem-1",
        userId: "user-1",
        hubId: "hub-zurich",
        status: .active,
        startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
        endDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!,
        source: .stripe
    )

    static func sampleEvents(hubId: String) -> [Event] {
        let cal = Calendar.current
        let now = Date()
        let imageURLs = [
            URL(string: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800"),
            URL(string: "https://images.unsplash.com/photo-1511578314322-379afb476865?w=800"),
            URL(string: "https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=800"),
            URL(string: "https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=800"),
            URL(string: "https://images.unsplash.com/photo-1559223607-180d0c16c333?w=800"),
            URL(string: "https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=800"),
        ]

        return [
            Event(id: "evt-1", hubId: hubId, category: .connect, title: "Networking Brunch", description: "Join us for a relaxed Saturday brunch where you'll meet inspiring women from different industries. Share stories, exchange ideas, and build meaningful connections over coffee and pastries in a warm, welcoming atmosphere.", heroImageURL: imageURLs[0], locationName: "Café Sprüngli", address: "Bahnhofstrasse 21, 8001 Zurich", latitude: 47.3697, longitude: 8.5392, startsAt: cal.date(byAdding: .day, value: 3, to: now)!, endsAt: cal.date(byAdding: .hour, value: 5, to: cal.date(byAdding: .day, value: 3, to: now)!)!, capacity: 25, registeredCount: 18, waitlistCount: 2, status: .published, registrationOpensAt: nil, registrationClosesAt: cal.date(byAdding: .day, value: 2, to: now), priceAmount: nil, currency: "CHF", isNonDeregisterable: false, deregistrationDeadlineHoursOverride: nil, noShowFeeAmountOverride: nil, hostName: "Sarah K.", attendeeAvatarURLs: []),

            Event(id: "evt-2", hubId: hubId, category: .learn, title: "Leadership Workshop: Finding Your Voice", description: "An interactive workshop designed to help you develop your leadership presence. Through exercises, role-playing, and guided reflection, you'll discover tools to communicate with authority and authenticity in any professional setting.", heroImageURL: imageURLs[1], locationName: "Impact Hub Zurich", address: "Sihlquai 131, 8005 Zurich", latitude: 47.3854, longitude: 8.5326, startsAt: cal.date(byAdding: .day, value: 5, to: now)!, endsAt: cal.date(byAdding: .hour, value: 3, to: cal.date(byAdding: .day, value: 5, to: now)!)!, capacity: 30, registeredCount: 30, waitlistCount: 5, status: .published, registrationOpensAt: nil, registrationClosesAt: cal.date(byAdding: .day, value: 4, to: now), priceAmount: 45, currency: "CHF", isNonDeregisterable: false, deregistrationDeadlineHoursOverride: 72, noShowFeeAmountOverride: 30, hostName: "Dr. Lisa M.", attendeeAvatarURLs: []),

            Event(id: "evt-3", hubId: hubId, category: .grow, title: "Career Pivot Panel Discussion", description: "Hear from four remarkable women who successfully pivoted their careers. From finance to tech, consulting to entrepreneurship — learn their strategies, setbacks, and how they found fulfillment in new paths.", heroImageURL: imageURLs[2], locationName: "Google Zurich", address: "Brandschenkestrasse 110, 8002 Zurich", latitude: 47.3653, longitude: 8.5246, startsAt: cal.date(byAdding: .day, value: 8, to: now)!, endsAt: cal.date(byAdding: .hour, value: 2, to: cal.date(byAdding: .day, value: 8, to: now)!)!, capacity: 50, registeredCount: 32, waitlistCount: 0, status: .published, registrationOpensAt: nil, registrationClosesAt: cal.date(byAdding: .day, value: 7, to: now), priceAmount: nil, currency: "CHF", isNonDeregisterable: false, deregistrationDeadlineHoursOverride: nil, noShowFeeAmountOverride: nil, hostName: "femella Board", attendeeAvatarURLs: []),

            Event(id: "evt-4", hubId: hubId, category: .connect, title: "Wine & Wisdom Evening", description: "An elegant evening combining fine Swiss wine tasting with inspiring short talks from members. Each speaker shares a 5-minute 'wisdom nugget' from their professional journey, followed by open networking.", heroImageURL: imageURLs[3], locationName: "Baur au Lac", address: "Talstrasse 1, 8001 Zurich", latitude: 47.3664, longitude: 8.5399, startsAt: cal.date(byAdding: .day, value: 12, to: now)!, endsAt: cal.date(byAdding: .hour, value: 3, to: cal.date(byAdding: .day, value: 12, to: now)!)!, capacity: 20, registeredCount: 15, waitlistCount: 0, status: .published, registrationOpensAt: nil, registrationClosesAt: cal.date(byAdding: .day, value: 11, to: now), priceAmount: 35, currency: "CHF", isNonDeregisterable: true, deregistrationDeadlineHoursOverride: nil, noShowFeeAmountOverride: nil, hostName: "Marie V.", attendeeAvatarURLs: []),

            Event(id: "evt-5", hubId: hubId, category: .learn, title: "Salary Negotiation Masterclass", description: "Learn proven strategies for negotiating your compensation package. Topics include market research, framing techniques, handling counteroffers, and building long-term earning power.", heroImageURL: imageURLs[4], locationName: "WeWork Seestrasse", address: "Seestrasse 353, 8038 Zurich", latitude: 47.3477, longitude: 8.5312, startsAt: cal.date(byAdding: .day, value: 16, to: now)!, endsAt: cal.date(byAdding: .hour, value: 2, to: cal.date(byAdding: .day, value: 16, to: now)!)!, capacity: 40, registeredCount: 22, waitlistCount: 0, status: .published, registrationOpensAt: nil, registrationClosesAt: cal.date(byAdding: .day, value: 15, to: now), priceAmount: 25, currency: "CHF", isNonDeregisterable: false, deregistrationDeadlineHoursOverride: nil, noShowFeeAmountOverride: nil, hostName: "Coach Julia R.", attendeeAvatarURLs: []),

            Event(id: "evt-past-1", hubId: hubId, category: .connect, title: "Spring Kick-off Dinner", description: "Our annual spring gathering to celebrate the new season and welcome new members to the femella community.", heroImageURL: imageURLs[5], locationName: "Hiltl Restaurant", address: "Sihlstrasse 28, 8001 Zurich", latitude: 47.3733, longitude: 8.5345, startsAt: cal.date(byAdding: .day, value: -10, to: now)!, endsAt: cal.date(byAdding: .hour, value: 3, to: cal.date(byAdding: .day, value: -10, to: now)!)!, capacity: 35, registeredCount: 35, waitlistCount: 0, status: .completed, registrationOpensAt: nil, registrationClosesAt: nil, priceAmount: nil, currency: "CHF", isNonDeregisterable: false, deregistrationDeadlineHoursOverride: nil, noShowFeeAmountOverride: nil, hostName: "femella Board", attendeeAvatarURLs: []),
        ]
    }

    static func sampleRegistrations() -> [EventRegistration] {
        [
            EventRegistration(id: "reg-1", eventId: "evt-1", userId: "user-1", status: .registered, registeredAt: Date(), canceledAt: nil, position: nil),
            EventRegistration(id: "reg-2", eventId: "evt-past-1", userId: "user-1", status: .attended, registeredAt: Calendar.current.date(byAdding: .day, value: -15, to: Date())!, canceledAt: nil, position: nil),
        ]
    }

    static func sampleNotifications() -> [AppNotification] {
        let now = Date()
        return [
            AppNotification(id: "notif-1", hubId: "hub-zurich", title: "Welcome to femella!", body: "Thank you for joining the Zurich hub. Explore upcoming events and connect with fellow members.", type: .system, sentAt: Calendar.current.date(byAdding: .hour, value: -2, to: now)!, isRead: false),
            AppNotification(id: "notif-2", hubId: "hub-zurich", title: "New Event: Networking Brunch", body: "A new Connect event has been added to the calendar. Spots are limited — register now!", type: .eventUpdate, sentAt: Calendar.current.date(byAdding: .day, value: -1, to: now)!, isRead: false),
            AppNotification(id: "notif-3", hubId: "hub-zurich", title: "Membership Renewal Reminder", body: "Your annual membership will renew in 30 days. Ensure your payment method is up to date.", type: .membership, sentAt: Calendar.current.date(byAdding: .day, value: -3, to: now)!, isRead: true),
            AppNotification(id: "notif-4", hubId: "hub-zurich", title: "Event Reminder", body: "Your registered event 'Spring Kick-off Dinner' is tomorrow at 18:00. See you there!", type: .eventUpdate, sentAt: Calendar.current.date(byAdding: .day, value: -11, to: now)!, isRead: true),
            AppNotification(id: "notif-5", hubId: nil, title: "femella Expanding!", body: "We're excited to announce femella is launching in two new cities this year. Stay tuned for updates!", type: .announcement, sentAt: Calendar.current.date(byAdding: .day, value: -7, to: now)!, isRead: true),
        ]
    }

    static func sampleSurveys() -> [Survey] {
        [
            Survey(id: "surv-1", hubId: "hub-zurich", eventId: "evt-past-1", title: "Spring Kick-off Feedback", description: "Help us improve! Share your thoughts about the Spring Kick-off Dinner.", status: .open, closesAt: Calendar.current.date(byAdding: .day, value: 5, to: Date()), questions: [
                SurveyQuestion(id: "q-1", type: .likert, prompt: "How would you rate the overall experience?", options: ["1", "2", "3", "4", "5"], orderIndex: 0),
                SurveyQuestion(id: "q-2", type: .multipleChoice, prompt: "What did you enjoy most?", options: ["Networking", "Food & Drinks", "Talks", "Venue", "Other"], orderIndex: 1),
                SurveyQuestion(id: "q-3", type: .text, prompt: "Any suggestions for future events?", options: nil, orderIndex: 2),
            ], isCompleted: false),
            Survey(id: "surv-2", hubId: "hub-zurich", eventId: nil, title: "Annual Member Satisfaction", description: "Your feedback shapes the future of femella Zurich. This 3-minute survey helps us understand what matters most to you.", status: .open, closesAt: Calendar.current.date(byAdding: .day, value: 14, to: Date()), questions: [
                SurveyQuestion(id: "q-4", type: .likert, prompt: "How satisfied are you with your femella membership?", options: ["1", "2", "3", "4", "5"], orderIndex: 0),
                SurveyQuestion(id: "q-5", type: .multipleChoice, prompt: "Which event category do you prefer?", options: ["Connect", "Learn", "Grow"], orderIndex: 1),
                SurveyQuestion(id: "q-6", type: .text, prompt: "What topics would you like to see covered?", options: nil, orderIndex: 2),
            ], isCompleted: false),
            Survey(id: "surv-3", hubId: "hub-zurich", eventId: nil, title: "Q4 Feedback Survey", description: "Share your thoughts on last quarter's events and activities.", status: .closed, closesAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()), questions: [], isCompleted: true),
        ]
    }

    static func sampleMembers() -> [UserProfile] {
        [
            UserProfile(id: "u-2", firstName: "Sophie", lastName: "Bauer", email: "sophie@example.com", phone: "", university: "University of Zurich", degree: "MBA", company: "McKinsey", jobTitle: "Senior Consultant", homeHubId: "hub-zurich", avatarURL: nil, showProfileToMembers: true),
            UserProfile(id: "u-3", firstName: "Elena", lastName: "Fischer", email: "elena@example.com", phone: "", university: "HSG St. Gallen", degree: "MSc Finance", company: "Credit Suisse", jobTitle: "VP Investments", homeHubId: "hub-zurich", avatarURL: nil, showProfileToMembers: true),
            UserProfile(id: "u-4", firstName: "Clara", lastName: "Weber", email: "clara@example.com", phone: "", university: "EPFL", degree: "PhD Engineering", company: "ABB", jobTitle: "R&D Lead", homeHubId: "hub-zurich", avatarURL: nil, showProfileToMembers: true),
            UserProfile(id: "u-5", firstName: "Mia", lastName: "Schneider", email: "mia@example.com", phone: "", university: "ETH Zurich", degree: "MSc Data Science", company: "Google", jobTitle: "Software Engineer", homeHubId: "hub-zurich", avatarURL: nil, showProfileToMembers: true),
        ]
    }
}
