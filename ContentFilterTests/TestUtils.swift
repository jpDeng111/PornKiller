//
//  TestUtils.swift
//  ContentFilterTests
//
//  Created by Joeseph Joestar（JOJO） on 2025/5/27.
//

import Foundation
import UIKit
import Vision
import XCTest

class ContentFilterTestUtils {
    
    // 测试图片集
    static func loadTestImages() -> [String: UIImage] {
        var images: [String: UIImage] = [:]
        
        // 1. 创建一个空白的测试图片
        images["blank"] = createColoredImage(color: .white)
        
        // 2. 创建一个红色测试图片
        images["red"] = createColoredImage(color: .red)
        
        // 3. 加载测试包中的所有测试图片
        loadAllTestImages(into: &images)
        
        return images
    }
    
    // 批量加载测试图片
    private static func loadAllTestImages(into images: inout [String: UIImage]) {
        // 定义要加载的图片名称和类型
        let testImageData: [(name: String, type: String)] = [
            ("monica_bellucci_4f95d3", "jpg"),
            ("monica_nude", "jpg"),
            ("monica-bellucci-combien-scoopy-n-01", "jpg"),
            //("unsafe_image2", "jpg"),
            // 添加更多测试图片...
        ]
        
        for imageData in testImageData {
            if let path =  Bundle(for: ContentFilterTestUtils.self).path(
                forResource: imageData.name, ofType: imageData.type),
               let image = UIImage(contentsOfFile: path) {
                images[imageData.name] = image
            } else {
                print("警告: 无法加载图片 \(imageData.name).\(imageData.type)")
            }
        }
    }
    
    // 创建纯色图片
    static func createColoredImage(color: UIColor, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    // 分析图片并返回结果
    static func analyzeImage(_ image: UIImage) -> (isInappropriate: Bool, categories: [String])? {
        let expectation = XCTestExpectation(description: "Image analysis")
        
        guard let cgImage = image.cgImage else { return nil }
        
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        var result: (isInappropriate: Bool, categories: [String])?
        
        do {
            try handler.perform([request])
            
            if let observations = request.results {
                let inappropriateKeywords = [
                    "nude", "naked", "underwear", "bikini", "swimsuit",
                    "violence", "weapon", "blood", "gore"
                ]
                
                let confidenceThreshold: Float = 0.6
                var isInappropriate = false
                var detectedCategories: [String] = []
                
                for observation in observations {
                    let identifier = observation.identifier.lowercased()
                    let confidence = observation.confidence
                    
                    if inappropriateKeywords.contains(where: { identifier.contains($0) })
                        && confidence > confidenceThreshold {
                        isInappropriate = true
                        detectedCategories.append("\(identifier) (\(Int(confidence * 100))%)")
                    }
                }
                
                result = (isInappropriate, detectedCategories)
                expectation.fulfill()
            }
        } catch {
            print("分析错误: \(error)")
            return nil
        }
        
        return result
    }
    
    // 批量分析多张图片
    static func batchAnalyzeImages(_ images: [String: UIImage]) -> [String: (isInappropriate: Bool, categories: [String], success: Bool)] {
        var results: [String: (isInappropriate: Bool, categories: [String], success: Bool)] = [:]
        
        for (name, image) in images {
            if let analysisResult = analyzeImage(image) {
                results[name] = (analysisResult.isInappropriate, analysisResult.categories, true)
            } else {
                results[name] = (false, [], false)
            }
        }
        
        return results
    }
} 
