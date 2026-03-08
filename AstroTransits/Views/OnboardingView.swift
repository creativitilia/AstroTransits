import SwiftUI

struct OnboardingView: View {
    
    @ObservedObject var appViewModel: AppViewModel
    
    // Controls which section is currently expanded
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
            
            // Stars background layer
            StarsBackgroundView()
            
            ScrollView {
                VStack(spacing: 32) {
                    
                    // MARK: - Header
                    headerSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -20)
                    
                    // MARK: - Form Cards
                    VStack(spacing: 16) {
                        dateCard
                        timeCard
                        cityCard
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 30)
                    
                    // MARK: - Error Message
                    if let error = appViewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    // MARK: - Submit Button
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
        FormCard(
            icon: "calendar",
            title: "Birth Date",
            isActive: currentStep == .date
        ) {
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
        FormCard(
            icon: "clock",
            title: "Birth Time",
            isActive: currentStep == .time
        ) {
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
        FormCard(
            icon: "mappin.circle",
            title: "Birth City",
            isActive: currentStep == .city
        ) {
            TextField("e.g. Paris, London, New York", text: $appViewModel.birthCity)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .light))
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
                .onTapGesture { currentStep = .city }
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

// MARK: - Form Card Component
// A reusable dark card that wraps each form section
struct FormCard<Content: View>: View {
    let icon: String
    let title: String
    let isActive: Bool
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Card header
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
                
                // Active indicator dot
                if isActive {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 6, height: 6)
                }
            }
            
            // Divider
            Rectangle()
                .fill(isActive ? Color.purple.opacity(0.5) : Color.white.opacity(0.08))
                .frame(height: 1)
            
            // The actual form content (DatePicker, TextField, etc.)
            content
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
// Simple decorative stars scattered behind the form
struct StarsBackgroundView: View {
    
    // Pre-generated star positions so they don't move on redraw
    private let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: CGFloat)] = {
        var result: [(CGFloat, CGFloat, CGFloat, CGFloat)] = []
        // Use a fixed seed pattern for consistent placement
        let positions: [(CGFloat, CGFloat)] = [
            (0.1, 0.05), (0.9, 0.08), (0.3, 0.12), (0.7, 0.15),
            (0.5, 0.03), (0.2, 0.20), (0.8,
