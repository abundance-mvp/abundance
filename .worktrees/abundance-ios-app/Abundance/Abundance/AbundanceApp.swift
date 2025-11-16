//
//  AbundanceApp.swift
//  Abundance
//
//  Created by w on 11/16/25.
//

import SwiftUI
@preconcurrency import FirebaseCore

@main
struct AbundanceApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView(viewModel: authViewModel)
                }
            }
        }
    }
}
