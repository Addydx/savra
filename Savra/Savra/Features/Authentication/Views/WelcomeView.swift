import SwiftUI

struct WelcomeView: View {
    let container: AppViewModel
    @State private var showSignIn = false
    @State private var showCreateAccount = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.bottom, 24)

            Text("Savra")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)

            Text("Registra tus comidas de forma\nsimple y organizada")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 16) {
                Button(action: { showCreateAccount = true }) {
                    Text("Crear cuenta")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: { showSignIn = true }) {
                    Text("Iniciar sesión")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .sheet(isPresented: $showCreateAccount) {
            CreateAccountView(container: container)
        }
        .sheet(isPresented: $showSignIn) {
            SignInView(container: container)
        }
    }
}
