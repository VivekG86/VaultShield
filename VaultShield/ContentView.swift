//
//  ContentView.swift
//  VaultShield
//
//  Created by Vivek Gopalan on 1/18/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var masterPassword = ""          // Master password to encrypt/decrypt
    @State private var password = ""     // password
    @State private var outputText = ""         // Resulting output
    @State private var selectedAction = "Decrypt"
    @State private var showPassword = false
    @State private var showMasterPassword = false

    private let crypto = AESCryptoService()

    let actions = ["Encrypt", "Decrypt"]

    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack(spacing: 12) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text("Vault Shield")
                        .font(.largeTitle.weight(.bold))
                }
                .padding(.top, 8)

                // Card Container
                VStack(spacing: 20) {
                    // Action Row
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("Select Action:")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("Action", selection: $selectedAction) {
                            ForEach(actions, id: \.self) { action in
                                Text(action)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Divider()

                    // Password Row
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter Password:")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("Enter password", text: $password)
                                } else {
                                    SecureField("Enter password", text: $password)
                                }
                            }
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)

                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)

                            Button(action: { password = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter Master Password:")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Group {
                                if showMasterPassword {
                                    TextField("Enter Password", text: $masterPassword)
                                } else {
                                    SecureField("Enter Password", text: $masterPassword)
                                }
                            }
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)

                            Button(action: { showMasterPassword.toggle() }) {
                                Image(systemName: showMasterPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)

                            Button(action: { masterPassword = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Primary Action Button
                    Button(action: {
                        do {
                            if selectedAction == "Encrypt" {
                                outputText = try crypto.encrypt(text: password, password: masterPassword)
                            } else {
                                outputText = try crypto.decrypt(base64Package: password, password: masterPassword)
                            }
                        } catch {
                            outputText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                        }
                    }) {
                        HStack {
                            Image(systemName: selectedAction == "Encrypt" ? "lock.fill" : "lock.open.fill")
                            Text(selectedAction)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Output Value:")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        HStack {
                            TextField("Output", text: $outputText, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .disabled(true)
                            Button(action: {
                                UIPasteboard.general.string = outputText
                            }) {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                .padding(.horizontal)

                Spacer(minLength: 0)
            }
            .padding(.top, 16)
        }
    }
}


#Preview {
    ContentView()
}

