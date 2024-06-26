//
//  SettingsMenuView.swift
//  ishare
//
//  Created by Adrian Castro on 12.07.23.
//

import SwiftUI
import Defaults
import LaunchAtLogin
import KeyboardShortcuts
import BezelNotification
import UniformTypeIdentifiers
import ScreenCaptureKit

struct SettingsMenuView: View {
    @Default(.aussieMode) var aussieMode

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            UploaderSettingsView()
                .tabItem {
                    Label("Uploaders", systemImage: "icloud.and.arrow.up")
                }
            
            KeybindSettingsView()
                .tabItem {
                    Label("Keybinds", systemImage: "command.circle")
                }
            
            CaptureSettingsView()
                .tabItem {
                    Label("Captures", systemImage: "photo")
                }
            
            RecordingSettingsView()
                .tabItem {
                    Label("Recordings", systemImage: "menubar.dock.rectangle.badge.record")
                }
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "hammer.circle").rotationEffect(aussieMode ? .degrees(180) : .zero)
                }
        }
        .frame(width: 550, height: 350).rotationEffect(aussieMode ? .degrees(180) : .zero)
    }
}

struct GeneralSettingsView: View {
    @Default(.menuBarIcon) var menubarIcon
    @Default(.toastTimeout) var toastTimeout
    @Default(.aussieMode) var aussieMode
    @Default(.uploadHistory) var uploadHistory
    
    var body: some View {
        VStack {
            LaunchAtLogin.Toggle()
            Toggle("I am in Australia", isOn: $aussieMode)
            Picker("MenuBar Icon", selection: $menubarIcon) {
                ForEach(MenuBarIcon.allCases, id: \.self) { choice in
                    Button {} label: {
                        switch choice {
                            case .DEFAULT: Image(nsImage: GlyphIcon)
                            case .APPICON: Image(nsImage: AppIcon)
                            case .SYSTEM: Image(systemName: "photo.on.rectangle.angled")
                        }
                    }.tag(choice.id)
                }
            }.padding().frame(width: 200)
            HStack {
                Button("Export Settings") {
                    exportUserDefaults()
                }
                Button("Import Settings") {
                    importUserDefaults()
                }
                Button("Clear History") {
                    uploadHistory = []
                    BezelNotification.show(messageText: "Cleared history", icon: ToastIcon)
                }
            }
            VStack {
                Text("Toast Timeout: \(Int(toastTimeout)) seconds")
                    .padding()
                Slider(value: $toastTimeout, in: 1...10, step: 1)
                    .frame(width: 200)
            }
        }
    }
}

struct KeybindSettingsView: View {
    var body: some View {
        VStack {
            Form {
                KeyboardShortcuts.Recorder("Open Main Menu:", name: .toggleMainMenu)
                KeyboardShortcuts.Recorder("Open History Window:", name: .openHistoryWindow)
                KeyboardShortcuts.Recorder("Capture Region:", name: .captureRegion)
                KeyboardShortcuts.Recorder("Capture Window:", name: .captureWindow)
                KeyboardShortcuts.Recorder("Capture Screen:", name: .captureScreen)
                KeyboardShortcuts.Recorder("Record Screen:", name: .recordScreen)
                KeyboardShortcuts.Recorder("Record GIF:", name: .recordGif)
            }
            Button("Reset") {
                KeyboardShortcuts.reset([.toggleMainMenu,.openHistoryWindow, .captureRegion, .captureWindow, .captureScreen, .recordScreen, .recordGif])
                BezelNotification.show(messageText: "Reset keybinds", icon: ToastIcon)
            }
        }
    }
}

struct CaptureSettingsView: View {
    @Default(.capturePath) var capturePath
    @Default(.captureFileType) var fileType
    @Default(.captureFileName) var fileName
    
    var body: some View {
        VStack {
            HStack {
                Text("Capture path:")
                TextField(text: $capturePath) {}
                Button("Select directory") {
                    selectFolder { folderURL in
                        if let url = folderURL {
                            capturePath = url.path()
                        }
                    }
                }
            }.padding(10)
            
            HStack {
                Text("File name:")
                TextField(String(), text: $fileName)
                Button("Default") {
                    fileName = Defaults.Keys.captureFileName.defaultValue
                }
            }.padding(20)
            
            Picker("File format:", selection: $fileType) {
                ForEach(FileType.allCases, id: \.self) {
                    Text($0.rawValue.uppercased())
                }
            }.padding(10)
        }
    }
}

struct RecordingSettingsView: View {
    @Default(.recordingPath) var recordingPath
    @Default(.recordingFileName) var fileName
    @Default(.recordAudio) var recordAudio
    @Default(.recordMP4) var recordMP4
    @Default(.useHEVC) var useHEVC
    @Default(.compressVideo) var compressVideo
    
    @State private var isExcludedAppSheetPresented = false
    
    var body: some View {
        VStack {
            Toggle("Record as .mp4 instead of .mov", isOn: $recordMP4)
            Toggle("Use HEVC", isOn: $useHEVC)
            Toggle("Apply heavy compression", isOn: $compressVideo)
            Toggle("Record audio", isOn: $recordAudio)
            HStack {
                Text("Recording path:")
                TextField(text: $recordingPath) {}
                Button("Select directory") {
                    selectFolder { folderURL in
                        if let url = folderURL {
                            recordingPath = url.path()
                        }
                    }
                }
            }.padding(10)
            
            HStack {
                Text("File name:")
                TextField(String(), text: $fileName)
                Button("Default") {
                    fileName = Defaults.Keys.recordingFileName.defaultValue
                    BezelNotification.show(messageText: "Reset filename", icon: ToastIcon)
                }
            }.padding(20)
            
            Button("Excluded applications") {
                isExcludedAppSheetPresented.toggle()
            }
            .sheet(isPresented: $isExcludedAppSheetPresented) {
                ExcludedAppsView()
            }
        }
    }
}
    
struct AdvancedSettingsView: View {
    @State private var showingAlert: Bool = false
    @Default(.imgurClientId) var imgurClientId
    @Default(.captureBinary) var captureBinary
    
    var body: some View {
        VStack{
            HStack {
                Text("Imgur Client ID:")
                TextField(String(), text: $imgurClientId)
                Button("Default") {
                    imgurClientId = Defaults.Keys.imgurClientId.defaultValue
                }
            }.padding(20)
            HStack {
                Text("Screencapture binary:")
                TextField(String(), text: $captureBinary)
                Button("Default") {
                    captureBinary = Defaults.Keys.captureBinary.defaultValue
                    BezelNotification.show(messageText: "Reset captureBinary", icon: ToastIcon)
                }
            }.padding(20)
            
        }.alert(Text("Advanced Settings"),
                isPresented: $showingAlert,
                actions: {
            Button("I understand") {
                showingAlert = false
            }
        }, message: {
            Text("Warning! Only modify these settings if you know what you're doing!")
        }
        )
        .onAppear{
            showingAlert = true
        }
    }
}
