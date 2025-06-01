//
//  ContentFilterTests.swift
//  ContentFilterTests
//
//  Created by Joeseph Joestar（JOJO） on 2025/5/24.
//

import XCTest
import Vision
@testable import ContentFilter

final class ContentFilterTests: XCTestCase {
    
    // 测试单张图片分析
    func testSingleImageAnalysis() {
        // 创建一个测试用例，模拟analyzeContent功能
        print("hello world")
        let expectation = XCTestExpectation(description: "Image analysis completed")
        
        // 使用工具类加载测试图片
        let testImages = ContentFilterTestUtils.loadTestImages()
        print("🔍 开始加载测试图片...")
        print("📊 找到 \(testImages.count) 张测试图片")
                
        for (name, _) in testImages {
            print("✅ 成功加载图片: \(name)")
        }
        guard let testImage = testImages["monica_nude"] ?? loadTestImage() else {
            XCTFail("无法加载测试图片")
            return
        }
        
        // 创建图像分析请求
        let request = VNClassifyImageRequest()
        
        // 创建图像处理处理器
        guard let cgImage = testImage.cgImage else {
            XCTFail("无法获取CGImage")
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
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
                let confidenceThreshold: Float = 0.4
                
                // 检查每个分类结果
                var isInappropriate = false
                var detectedCategories: [String] = []
                
                for observation in observations {
                    let identifier = observation.identifier.lowercased()
                    let confidence = observation.confidence
                    
                    print("观察到: \(identifier) 置信度: \(confidence)")
                    
                    // 检查是否匹配不适当关键词且置信度超过阈值
                    if inappropriateKeywords.contains(where: { identifier.contains($0) })
                        && confidence > confidenceThreshold {
                        isInappropriate = true
                        detectedCategories.append("\(identifier) (\(Int(confidence * 100))%)")
                    }
                }
                
                // 打印结果
                print("\n===== 单张图片分析结果 =====")
                print("图片: monica_nude")
                print("内容类型: \(isInappropriate ? "不适当内容" : "适当内容")")
                print("检测到的分类: \(detectedCategories.isEmpty ? "无" : detectedCategories.joined(separator: ", "))")
                print("===============================\n")
                
                expectation.fulfill()
            }
        } catch {
            XCTFail("分析内容时出错: \(error.localizedDescription)")
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // 测试多张图片分析
    func testMultipleImagesAnalysis() {
        // 使用工具类加载所有测试图片
        let testImages = ContentFilterTestUtils.loadTestImages()
        XCTAssertFalse(testImages.isEmpty, "没有找到测试图片")
        
        print("\n===== 多张图片分析结果 =====")
        
        // 遍历并分析每张图片
        for (imageName, image) in testImages {
            if let result = ContentFilterTestUtils.analyzeImage(image) {
                print("\n图片: \(imageName)")
                print("内容类型: \(result.isInappropriate ? "不适当内容" : "适当内容")")
                print("检测到的分类: \(result.categories.isEmpty ? "无" : result.categories.joined(separator: ", "))")
                
                // 如果图片名称包含"nude"，期望它被标记为不适当内容
                if imageName.contains("nude") {
                    XCTAssertTrue(result.isInappropriate, "包含'nude'的图片应被检测为不适当内容")
                }
            } else {
                print("\n图片: \(imageName)")
                print("分析失败")
            }
        }
        
        print("\n============================\n")
    }
    
    // 使用批量分析功能测试
    func testBatchAnalysis() {
        // 使用工具类加载所有测试图片
        let testImages = ContentFilterTestUtils.loadTestImages()
        XCTAssertFalse(testImages.isEmpty, "没有找到测试图片")
        
        // 使用批量分析功能
        let results = ContentFilterTestUtils.batchAnalyzeImages(testImages)
        
        // 打印结果
        print("\n===== 批量分析结果 =====")
        for (imageName, result) in results {
            print("\n图片: \(imageName)")
            print("分析状态: \(result.success ? "成功" : "失败")")
            if result.success {
                print("内容类型: \(result.isInappropriate ? "不适当内容" : "适当内容")")
                print("检测到的分类: \(result.categories.isEmpty ? "无" : result.categories.joined(separator: ", "))")
                
                // 验证结果
                if imageName.contains("nude") {
                    XCTAssertTrue(result.isInappropriate, "包含'nude'的图片应被检测为不适当内容")
                }
            }
        }
        print("\n=========================\n")
    }
    
    // 备用方法：加载单张测试图片
    private func loadTestImage() -> UIImage? {
        // 尝试从测试包加载图片
        if let path = Bundle(for: ContentFilterTests.self).path(forResource: "monica_bellucci_4f95d3", ofType: "jpg") {
            return UIImage(contentsOfFile: path)
        }
        
        // 如果无法加载，创建一个简单的图片
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        return renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
    }
}
