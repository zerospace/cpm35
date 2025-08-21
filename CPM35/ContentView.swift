//
//  ContentView.swift
//  CPM35
//
//  Created by Oleksandr Fedko on 18.08.2025.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var imagePicker: PhotosPickerItem?
    @State private var image: Image?
    @State private var inputImage: CIImage?
    
    var body: some View {
        NavigationStack {
            VStack {
                image?.resizable()
                    .scaledToFit()
                    .frame(maxHeight: .infinity)
                
                Spacer(minLength: 15.0)
                
                Button {
                    if let ciImage = inputImage {
                        let filter = CPM35Filter(image: ciImage)
                        guard let outputImage = filter.outputImage else { return }
                        if let cgImage = CIContext().createCGImage(outputImage, from: ciImage.extent) {
                            let uiImage = UIImage(cgImage: cgImage)
                            image = Image(uiImage: uiImage)
                        }
                    }
                } label: {
                    Text("Process the image")
                        .font(.system(size: 17.0, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
                .padding(.horizontal, 15.0)
                .padding(.bottom, 15.0)
            }
            .onChange(of: imagePicker) { oldValue, newValue in
                Task {
                    if let data = try? await imagePicker?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data)
                    {
                        inputImage = CIImage(data: data)
                        image = Image(uiImage: uiImage)
                    }
                }
            }
            .navigationTitle("CPM35 Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    PhotosPicker(selection: $imagePicker, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "camera")
                    }
                }
                
                if let share = image {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: share, preview: SharePreview("CPM35", image: share)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
}
