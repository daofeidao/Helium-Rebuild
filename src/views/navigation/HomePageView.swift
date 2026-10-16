//
//  HomePageView.swift
//  Helium UI
//
//  Created by lemin on 10/19/23.
//

import Foundation
import SwiftUI

// MARK: Home Page View
struct HomePageView: View {
  @State private var isNowEnabled: Bool = false
  @State private var buttonDisabled: Bool = false
  @State private var inProgress = false
  /// Something worth saying about the process behind the HUD. It is a separate
  /// process, so an install replaces the file on disk but not the code that is
  /// already on screen; this says when that has just been put right.
  @State private var hudNote: String? = nil

  var body: some View {
    NavigationView {
      VStack(spacing: 10) {
        Spacer()

        // Activate HUD Button
        Button(
          action: {
            #if targetEnvironment(simulator)
              isNowEnabled.toggle()
            #else
              toggleHUD(!isNowEnabled)
            #endif
          },
          label: {
            HStack(spacing: 10) {
              if inProgress {
                if #available(iOS 16.0, *) {
                  ProgressView()
                    .tint(isNowEnabled ? .red : .blue)
                } else {
                  ProgressView()
                    .foregroundColor(isNowEnabled ? .red : .blue)
                }
              }
              Text(
                isNowEnabled
                  ? NSLocalizedString("Disable HUD", comment: "")
                  : NSLocalizedString("Enable HUD", comment: ""))
            }
          }
        )
        .buttonStyle(TintedButton(color: isNowEnabled ? .red : .blue))
        .padding(5)
        .offset(y: isNowEnabled ? -10 : 0)
        Text(
          NSLocalizedString(
            "You can quit the app now.\nThe HUD will persist on your screen.", comment: "")
        )
        .multilineTextAlignment(.center)
        .offset(y: isNowEnabled ? 5 : 15)
        .foregroundColor(.blue)
        .opacity(isNowEnabled ? 1 : 0)

        Spacer()
        // HUD Info Text
        Text(
          isNowEnabled
            ? NSLocalizedString("Status: Running", comment: "")
            : NSLocalizedString("Status: Stopped", comment: "")
        )
        .font(.caption)
        .foregroundColor(isNowEnabled ? .blue : .red)
        .padding(.bottom, hudNote == nil ? 10 : 4)
        .multilineTextAlignment(.center)

        if let hudNote = hudNote {
          Text(hudNote)
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
        }
      }
      .disabled(buttonDisabled)
      .onAppear {
        #if !targetEnvironment(simulator)
          isNowEnabled = IsHUDEnabledBridger()
          if isNowEnabled && IsHUDBuildStaleBridger() {
            // An install replaces the binary on disk but not the process that is
            // already running, so the HUD on screen can still be the previous
            // build: the app's settings screen is there, the code behind it is
            // not. Rather than leave that to be discovered as "the new option
            // does nothing", notice it and put it right.
            replaceStaleHUD()
          } else if !isNowEnabled {
            hudNote = nil
          }
        #endif
      }
      .onOpenURL(perform: { url in
        let _ = FileManager.default
        // MARK: URL Schemes
        if url.absoluteString == "helium://toggle" {
          #if !targetEnvironment(simulator)
            toggleHUD(!isNowEnabled)
          #endif
        } else if url.absoluteString == "helium://on" {
          #if !targetEnvironment(simulator)
            toggleHUD(true)
          #endif
        } else if url.absoluteString == "helium://off" {
          #if !targetEnvironment(simulator)
            toggleHUD(false)
          #endif
        }
      })
      .navigationTitle(Text(NSLocalizedString("Helium", comment: "")))
    }
    .navigationViewStyle(StackNavigationViewStyle())
    .animation(.timingCurve(0.25, 0.1, 0.35, 1.75).speed(1.2), value: isNowEnabled)
    .animation(.timingCurve(0.25, 0.1, 0.35, 1.75).speed(1.2), value: inProgress)
  }

  func toggleHUD(_ isActive: Bool) {
    inProgress.toggle()
    Haptic.shared.play(.medium)
    if isNowEnabled == isActive { return }
    if !isActive {
      // What the HUD *was* stops mattering once there is no HUD.
      hudNote = nil
    }
    print(
      !isActive
        ? NSLocalizedString("Closing HUD", comment: "")
        : NSLocalizedString("Opening HUD", comment: ""))
    SetHUDEnabledBridger(isActive)

    buttonDisabled = true
    waitForNotificationBridger(
      {
        isNowEnabled = isActive
        buttonDisabled = false
        inProgress.toggle()
      }, !isNowEnabled)
  }

  /// Restart a HUD that is running code from before this install.
  ///
  /// The HUD is a separate process spawned from this same bundle, and installing
  /// a new tipa does not touch a process that is already running. The record a
  /// HUD writes when it starts is what makes that visible: if it does not match
  /// the build of this binary, the process on screen is older. The version
  /// fields cannot be used for this (they are frozen at the upstream 3.2.6 on
  /// purpose), which is why the executable itself is what gets compared.
  func replaceStaleHUD() {
    inProgress = true
    buttonDisabled = true
    SetHUDEnabledBridger(false)
    SetHUDEnabledBridger(true)
    waitForNotificationBridger(
      {
        inProgress = false
        buttonDisabled = false
        isNowEnabled = true
        if IsHUDBuildStaleBridger() {
          hudNote = NSLocalizedString(
            "The HUD is still running an older build. Turn the HUD off and on again.",
            comment: "")
        } else {
          hudNote = NSLocalizedString(
            "The HUD was running an older build, so it was restarted.", comment: "")
        }
      }, true)
  }
}
