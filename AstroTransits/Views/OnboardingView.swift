import SwiftUI
import MapKit

struct OnboardingView: View {
    
    @ObservedObject var appViewModel: AppViewModel
    @State private var currentStep: OnboardingStep = .date
    @State private var animateIn: Bool = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.10, green: 0.05, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            StarsBackgroundView()
            
            ScrollView {
                VStack(spacing: 32) {
                    
                    headerSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -20)
                    
                    VStack(spacing: 16) {
                        dateCard
                        timeCard
                        cityCard
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 30)
                    
                    if let error = appViewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    submitButton
                        .opacity(animateIn ? 1 : 0)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("✦")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.6))
            
            Text("AstroTransits")
                .font(.system(size: 34, weight: .thin, design: .serif))
                .foregroundColor(.white)
            
            Text("Enter your birth details to reveal\nthe planetary story of your life.")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Date Card
    private var dateCard: some View {
        FormCard(icon: "calendar", title: "Birth Date", isActive: currentStep == .date) {
            DatePicker(
                "",
                selection: $appViewModel.birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .frame(maxWidth: .infinity)
        }
        .onTapGesture { currentStep = .date }
    }
    
    // MARK: - Time Card
    private var timeCard: some View {
        FormCard(icon: "clock", title: "Birth Time", isActive: currentStep == .time) {
            DatePicker(
                "",
                selection: $appViewModel.birthTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .frame(maxWidth: .infinity)
            
            Text("Use your birth certificate if possible.\nIf unknown, use 12:00 noon.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .onTapGesture { currentStep = .time }
    }
    
    // MARK: - City Card
    private var cityCard: some View {
        FormCard(icon: "mappin.circle", title: "Birth City", isActive: currentStep == .city) {
            TextField("e.g. Paris, London, New York", text: $appViewModel.birthCity)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .light))
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
        }
        .onTapGesture { currentStep = .city }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            Task {
                await appViewModel.submitBirthData()
            }
        } label: {
            ZStack {
                if appViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                        Text("Calculate My Chart")
                            .font(.system(size: 16, weight: .medium))
                        Image(systemName: "sparkles")
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.2, blue: 0.8),
                        Color(red: 0.6, green: 0.2, blue: 0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .purple.opacity(0.4), radius: 12, y: 6)
        }
        .disabled(appViewModel.isLoading)
        .padding(.top, 8)
    }
}

// MARK: - Form Card
struct FormCard<Content: View>: View {
    let icon: String
    let title: String
    let isActive: Bool
    @ViewBuilder let content: () -> Content
    
    init(icon: String, title: String, isActive: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.icon = icon
        self.title = title
        self.isActive = isActive
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(isActive ? .purple : .white.opacity(0.4))
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundColor(isActive ? .white.opacity(0.9) : .white.opacity(0.4))
                
                Spacer()
                
                if isActive {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 6, height: 6)
                }
            }
            
            Rectangle()
                .fill(isActive ? Color.purple.opacity(0.5) : Color.white.opacity(0.08))
                .frame(height: 1)
            
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(isActive ? 0.07 : 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isActive ? Color.purple.opacity(0.4) : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Stars Background
struct StarData {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: CGFloat
}

struct StarsBackgroundView: View {
    
    private let stars: [StarData] = {
        let positions: [(CGFloat, CGFloat)] = [
            (0.1, 0.05), (0.9, 0.08), (0.3, 0.12), (0.7, 0.15),
            (0.5, 0.03), (0.2, 0.20), (0.8, 0.22), (0.4, 0.28),
            (0.6, 0.18), (0.15, 0.35), (0.85, 0.32), (0.55, 0.40),
            (0.25, 0.45), (0.75, 0.48), (0.45, 0.55), (0.05, 0.60),
            (0.95, 0.58), (0.35, 0.65), (0.65, 0.70), (0.50, 0.75),
            (0.10, 0.80), (0.90, 0.82), (0.30, 0.88), (0.70, 0.92),
            (0.20, 0.95), (0.80, 0.97), (0.60, 0.85), (0.40, 0.90)
        ]
        // Use fixed values instead of random so stars don't shift on redraw
        let sizes:    [CGFloat] = [1,2,3,1,2,1,3,2,1,2,3,1,2,1,3,2,1,2,3,1,2,3,1,2,3,1,2,3]
        let opacities:[CGFloat] = [0.4,0.6,0.3,0.5,0.7,0.3,0.5,0.4,0.6,0.3,0.5,0.7,0.4,0.6,0.3,0.5,0.4,0.6,0.3,0.5,0.4,0.3,0.6,0.5,0.4,0.7,0.3,0.5]
        
        return positions.enumerated().map { i, pos in
            StarData(x: pos.0, y: pos.1, size: sizes[i], opacity: opacities[i])
        }
    }()
    
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<stars.count, id: \.self) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: stars[i].size, height: stars[i].size)
                    .opacity(stars[i].opacity)
                    .position(
                        x: stars[i].x * geo.size.width,
                        y: stars[i].y * geo.size.height
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Onboarding Steps
enum OnboardingStep {
    case date, time, city
}

#Preview {
    OnboardingView(appViewModel: AppViewModel())
}
