//
//  ContentView1.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import SwiftUI
import SwiftData

struct ContentView1: View {

    @StateObject private var model = DataModel()
    
    private static let barHeightFactor = 0.15
    @State private var selectedTab = 0

    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            
            TabView(selection: $selectedTab) {
                MediaPage(size: size, safeArea: safeArea)
                    .preferredColorScheme(.none)
                    .tabItem {
                        Label("Local", systemImage: "play.circle")
                    }
                    .tag(0)
                
                NetworkSourcePage(size: size, safeArea: safeArea)
                    .preferredColorScheme(.none)
                    .tabItem {
                        Label("Network", systemImage: "livephoto.play")
                    }
                    .tag(1)
                
                WebrtcMediaPage(size: size, safeArea: safeArea)
                    .preferredColorScheme(.none)
                    .tabItem {
                        Label("Chat", systemImage: "livephoto")
                    }
                    .tag(2)
                
                ViewfinderView(image:  $model.viewfinderImage )
                    .overlay(alignment: .top) {
                        Color.black
                            .opacity(0.75)
                            .frame(height: size.height * Self.barHeightFactor)
                    }
                    .overlay(alignment: .bottom) {
                        buttonsView()
                            .frame(height: size.height * Self.barHeightFactor)
                            .background(.black.opacity(0.75))
                    }
                    .overlay(alignment: .center)  {
                        Color.clear
                            .frame(height: size.height * (1 - (Self.barHeightFactor * 2)))
                            .accessibilityElement()
                            .accessibilityLabel("View Finder")
                            .accessibilityAddTraits([.isImage])
                    }
                    .background(.black)
                    .preferredColorScheme(.none)
                    .tabItem {
                        Label("Camera", systemImage: "camera")
                    }
                    .tag(3)
            }
            .onAppear {
                UITabBar.appearance().backgroundColor = .white
                UITabBar.appearance().unselectedItemTintColor = .gray
                UITabBar.appearance().tintColor = .tintColor
            }
        }
        .task {
            await model.camera.start()
            await model.loadPhotos()
            await model.loadThumbnail()
        }
        .statusBar(hidden: false)
    }
    
    private func buttonsView() -> some View {
            HStack(spacing: 60) {
                
                Spacer()
                
                NavigationLink {
                    PhotoCollectionView(photoCollection: model.photoCollection)
                        .onAppear {
                            model.camera.isPreviewPaused = true
                        }
                        .onDisappear {
                            model.camera.isPreviewPaused = false
                        }
                } label: {
                    Label {
                        Text("Gallery")
                    } icon: {
                        ThumbnailView(image: model.thumbnailImage)
                    }
                }
                
                Button {
                    model.camera.takePhoto()
                } label: {
                    Label {
                        Text("Take Photo")
                    } icon: {
                        ZStack {
                            Circle()
                                .strokeBorder(.white, lineWidth: 3)
                                .frame(width: 62, height: 62)
                            Circle()
                                .fill(.white)
                                .frame(width: 50, height: 50)
                        }
                    }
                }
                
                Button {
                    model.camera.switchCaptureDevice()
                } label: {
                    Label("Switch Camera", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            
            }
            .buttonStyle(.plain)
            .labelStyle(.iconOnly)
            .padding()
    }
}

#Preview {
    ContentView1()
        .modelContainer(SampleData.shared.modelContainer)
}
