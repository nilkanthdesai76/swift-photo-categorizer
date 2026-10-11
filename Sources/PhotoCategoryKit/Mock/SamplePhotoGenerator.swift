import Foundation
import CoreGraphics

/// Generates synthetic test images for unit testing and demo mode without external network or asset dependencies.
public enum SamplePhotoGenerator {
    
    /// Generates a CGImage of specified dimensions simulating different semantic scenes.
    public static func generatePhoto(for category: PhotoCategory, width: Int = 360, height: Int = 360) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        
        switch category {
        case .nature:
            drawNatureScene(in: context, rect: rect)
        case .people:
            drawPeopleScene(in: context, rect: rect)
        case .food:
            drawFoodScene(in: context, rect: rect)
        case .vehicle:
            drawVehicleScene(in: context, rect: rect)
        case .indoor:
            drawIndoorScene(in: context, rect: rect)
        case .documents:
            drawDocumentScene(in: context, rect: rect)
        case .cityscape:
            drawCityscapeScene(in: context, rect: rect)
        case .pets:
            drawPetScene(in: context, rect: rect)
        case .other:
            drawAbstractScene(in: context, rect: rect)
        }
        
        return context.makeImage()
    }
    
    // MARK: - Scene Drawings
    
    private static func drawNatureScene(in ctx: CGContext, rect: CGRect) {
        // Sky gradient (sunset orange to blue)
        let colors = [
            CGColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0),
            CGColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0)
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: rect.height), end: CGPoint(x: 0, y: rect.height * 0.4), options: [])
        
        // Sun
        ctx.setFillColor(CGColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0))
        ctx.fillEllipse(in: CGRect(x: rect.width * 0.4, y: rect.height * 0.5, width: 80, height: 80))
        
        // Mountain triangles
        ctx.setFillColor(CGColor(red: 0.1, green: 0.4, blue: 0.2, alpha: 1.0))
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.6))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.closeSubpath()
        ctx.addPath(path)
        ctx.fillPath()
    }
    
    private static func drawPeopleScene(in ctx: CGContext, rect: CGRect) {
        // Background
        ctx.setFillColor(CGColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1.0))
        ctx.fill(rect)
        
        // Body / Shoulders
        ctx.setFillColor(CGColor(red: 0.2, green: 0.3, blue: 0.6, alpha: 1.0))
        ctx.fillEllipse(in: CGRect(x: rect.width * 0.15, y: -rect.height * 0.2, width: rect.width * 0.7, height: rect.height * 0.6))
        
        // Head / Face
        let faceRect = CGRect(x: rect.width * 0.3, y: rect.height * 0.35, width: rect.width * 0.4, height: rect.height * 0.45)
        ctx.setFillColor(CGColor(red: 0.95, green: 0.78, blue: 0.65, alpha: 1.0)) // Skin tone
        ctx.fillEllipse(in: faceRect)
        
        // Eyes
        ctx.setFillColor(CGColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0))
        ctx.fillEllipse(in: CGRect(x: faceRect.origin.x + faceRect.width * 0.25, y: faceRect.origin.y + faceRect.height * 0.55, width: 12, height: 8))
        ctx.fillEllipse(in: CGRect(x: faceRect.origin.x + faceRect.width * 0.65, y: faceRect.origin.y + faceRect.height * 0.55, width: 12, height: 8))
        
        // Smile
        ctx.setStrokeColor(CGColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0))
        ctx.setLineWidth(4.0)
        ctx.beginPath()
        ctx.addArc(center: CGPoint(x: faceRect.midX, y: faceRect.origin.y + faceRect.height * 0.35), radius: 25, startAngle: 0.2, endAngle: 2.9, clockwise: false)
        ctx.strokePath()
    }
    
    private static func drawFoodScene(in ctx: CGContext, rect: CGRect) {
        // Tablecloth / Wooden table background
        ctx.setFillColor(CGColor(red: 0.82, green: 0.65, blue: 0.45, alpha: 1.0))
        ctx.fill(rect)
        
        // Plate
        let plateRect = rect.insetBy(dx: 40, dy: 40)
        ctx.setFillColor(CGColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0))
        ctx.fillEllipse(in: plateRect)
        
        // Pizza / Dish center
        let foodRect = plateRect.insetBy(dx: 25, dy: 25)
        ctx.setFillColor(CGColor(red: 0.9, green: 0.6, blue: 0.1, alpha: 1.0))
        ctx.fillEllipse(in: foodRect)
        
        // Tomato toppings
        ctx.setFillColor(CGColor(red: 0.85, green: 0.15, blue: 0.1, alpha: 1.0))
        ctx.fillEllipse(in: CGRect(x: foodRect.midX - 30, y: foodRect.midY - 20, width: 25, height: 25))
        ctx.fillEllipse(in: CGRect(x: foodRect.midX + 15, y: foodRect.midY + 10, width: 25, height: 25))
        ctx.fillEllipse(in: CGRect(x: foodRect.midX - 10, y: foodRect.midY + 30, width: 25, height: 25))
        
        // Basil leaves
        ctx.setFillColor(CGColor(red: 0.1, green: 0.7, blue: 0.2, alpha: 1.0))
        ctx.fillEllipse(in: CGRect(x: foodRect.midX + 5, y: foodRect.midY - 35, width: 20, height: 12))
        ctx.fillEllipse(in: CGRect(x: foodRect.midX - 35, y: foodRect.midY + 15, width: 20, height: 12))
    }
    
    private static func drawVehicleScene(in ctx: CGContext, rect: CGRect) {
        // Road background
        ctx.setFillColor(CGColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0))
        ctx.fill(rect)
        
        // Car Body (Red sports car)
        ctx.setFillColor(CGColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0))
        let carBody = CGRect(x: 50, y: 130, width: rect.width - 100, height: 70)
        ctx.fill(carBody)
        
        // Car Roof
        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: 100, y: 200))
        roofPath.addLine(to: CGPoint(x: 140, y: 245))
        roofPath.addLine(to: CGPoint(x: 230, y: 245))
        roofPath.addLine(to: CGPoint(x: 270, y: 200))
        roofPath.closeSubpath()
        ctx.addPath(roofPath)
        ctx.fillPath()
        
        // Wheels
        ctx.setFillColor(CGColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0))
        ctx.fillEllipse(in: CGRect(x: 80, y: 105, width: 50, height: 50))
        ctx.fillEllipse(in: CGRect(x: rect.width - 130, y: 105, width: 50, height: 50))
    }
    
    private static func drawIndoorScene(in ctx: CGContext, rect: CGRect) {
        // Wall (warm beige)
        ctx.setFillColor(CGColor(red: 0.93, green: 0.90, blue: 0.85, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 100, width: rect.width, height: rect.height - 100))
        
        // Wooden floor
        ctx.setFillColor(CGColor(red: 0.65, green: 0.45, blue: 0.3, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: rect.width, height: 100))
        
        // Sofa / Furniture
        ctx.setFillColor(CGColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1.0))
        ctx.fill(CGRect(x: 40, y: 60, width: rect.width - 80, height: 80))
        
        // Wall Picture Frame
        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0))
        ctx.setLineWidth(5)
        ctx.stroke(CGRect(x: 110, y: 220, width: 140, height: 90))
    }
    
    private static func drawDocumentScene(in ctx: CGContext, rect: CGRect) {
        // Dark desk
        ctx.setFillColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.fill(rect)
        
        // White paper sheet
        let paperRect = CGRect(x: 50, y: 30, width: rect.width - 100, height: rect.height - 60)
        ctx.setFillColor(CGColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0))
        ctx.fill(paperRect)
        
        // Simulated lines of text
        ctx.setFillColor(CGColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0))
        for line in 0..<12 {
            let y = paperRect.origin.y + Double(line * 20) + 30
            let lineWidth = (line % 3 == 0) ? paperRect.width * 0.5 : paperRect.width * 0.8
            ctx.fill(CGRect(x: paperRect.origin.x + 20, y: y, width: lineWidth, height: 8))
        }
    }
    
    private static func drawCityscapeScene(in ctx: CGContext, rect: CGRect) {
        // Night sky
        ctx.setFillColor(CGColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 1.0))
        ctx.fill(rect)
        
        // Moon
        ctx.setFillColor(CGColor(red: 0.95, green: 0.95, blue: 0.8, alpha: 1.0))
        ctx.fillEllipse(in: CGRect(x: 40, y: 280, width: 40, height: 40))
        
        // Skyscrapers
        ctx.setFillColor(CGColor(red: 0.15, green: 0.2, blue: 0.3, alpha: 1.0))
        ctx.fill(CGRect(x: 30, y: 0, width: 60, height: 210))
        ctx.fill(CGRect(x: 100, y: 0, width: 80, height: 260))
        ctx.fill(CGRect(x: 190, y: 0, width: 70, height: 180))
        ctx.fill(CGRect(x: 270, y: 0, width: 60, height: 230))
    }
    
    private static func drawPetScene(in ctx: CGContext, rect: CGRect) {
        // Grass background
        ctx.setFillColor(CGColor(red: 0.3, green: 0.65, blue: 0.25, alpha: 1.0))
        ctx.fill(rect)
        
        // Dog / Pet body
        ctx.setFillColor(CGColor(red: 0.75, green: 0.5, blue: 0.25, alpha: 1.0))
        ctx.fillEllipse(in: CGRect(x: 90, y: 100, width: 180, height: 120))
        
        // Head
        ctx.fillEllipse(in: CGRect(x: 190, y: 170, width: 90, height: 90))
        
        // Ears
        ctx.fillEllipse(in: CGRect(x: 240, y: 220, width: 35, height: 60))
    }
    
    private static func drawAbstractScene(in ctx: CGContext, rect: CGRect) {
        ctx.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        ctx.fill(rect)
    }
}
