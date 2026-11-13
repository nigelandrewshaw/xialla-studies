import SwiftUI

/// Kit fulfillment timing TBD with Jeff — UI stub only.
struct KitFulfillmentStubView: View {
    @EnvironmentObject private var session: StudySession

    var body: some View {
        ZStack {
            AtmosphereBackground()

            VStack(alignment: .leading, spacing: 24) {
                SectionIntro(
                    headline: "Study kit",
                    support: "Fulfillment timing is undecided. This screen is a placeholder so the app can record intent without shipping logic."
                )

                if let kit = session.snapshot.kit {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledContent("Status", value: kit.status.rawValue)
                        LabeledContent("Study code", value: kit.meta.studyCode)
                        LabeledContent("Site code", value: kit.meta.siteCode)
                        if let notes = kit.notes {
                            Text(notes)
                                .font(BrandTheme.body(14))
                                .foregroundStyle(BrandTheme.graphite)
                        }
                    }
                } else {
                    Text("No kit record yet — created when a prospective arm is selected.")
                        .font(BrandTheme.body(15))
                        .foregroundStyle(BrandTheme.graphite)
                }

                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("Kit")
        .navigationBarTitleDisplayMode(.inline)
    }
}
