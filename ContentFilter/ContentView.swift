//
//  ContentView.swift
//  ContentFilter
//
//  Created by Joeseph Joestar（JOJO） on 2025/5/24.
//

import SwiftUI
import CoreData
import Vision
import PhotosUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    @State private var isContentSafe = true
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .padding()
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                Button(action: {
                    isShowingImagePicker = true
                }) {
                    Text("选择图片")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                if selectedImage != nil {
                    Button(action: analyzeContent) {
                        Text("分析内容")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("内容过滤器")
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert(isPresented: $isShowingAlert) {
                Alert(
                    title: Text(isContentSafe ? "内容安全" : "警告"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
    
    private func analyzeContent() {
        guard let image = selectedImage else { return }
        
        // 创建图像分析请求
        let request = VNClassifyImageRequest()
        
        // 创建图像处理处理器
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        
        do {
            try handler.perform([request])
            
            // 处理分析结果
            if let observations = request.results {
                // 定义可能的不适当内容关键词
                let inappropriateKeywords = [
                    "nude", "naked", "underwear", "bikini", "swimsuit",
                    "violence", "weapon", "blood", "gore"
                ]
                
                // 设置置信度阈值
                let confidenceThreshold: Float = 0.8
                
                // 检查每个分类结果
                var isInappropriate = false
                var detectedCategories: [String] = []
                
                for observation in observations {
                    let identifier = observation.identifier.lowercased()
                    let confidence = observation.confidence
                    
                    // 检查是否匹配不适当关键词且置信度超过阈值
                    if inappropriateKeywords.contains(where: { identifier.contains($0) })
                        && confidence > confidenceThreshold {
                        isInappropriate = true
                        detectedCategories.append("\(identifier) (\(Int(confidence * 100))%)")
                    }
                }
                
                // 更新UI状态
                isContentSafe = !isInappropriate
                if isInappropriate {
                    alertMessage = "检测到可能的不适当内容：\n" + detectedCategories.joined(separator: "\n")
                } else {
                    alertMessage = "内容分析完成。未检测到不适当内容。"
                }
            }
        } catch {
            isContentSafe = false
            alertMessage = "分析内容时出错: \(error.localizedDescription)"
        }
        
        isShowingAlert = true
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
} 
