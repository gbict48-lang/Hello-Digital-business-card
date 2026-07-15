import SwiftUI

struct SocialLinksSection: View {
    @Binding var socials: [SocialLink]

    var body: some View {
        Section("Social & Links") {
            ForEach($socials) { $social in
                HStack(spacing: 12) {
                    Picker("", selection: $social.platform) {
                        ForEach(SocialLink.Platform.allCases) { platform in
                            Text(platform.title).tag(platform)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)

                    TextField("URL or handle", text: $social.value)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
            }
            .onDelete { socials.remove(atOffsets: $0) }

            Button {
                socials.append(SocialLink(platform: .linkedin, value: ""))
            } label: {
                Label("Add link", systemImage: "plus.circle")
            }
        }
    }
}
