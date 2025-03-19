//
//  ThumbnailProvider.swift
//  mscz-thumb-plugin
//
//  Created by Ben on 3/18/25.
//

import QuickLookThumbnailing
import Foundation
import ZIPFoundation
import CoreGraphics
import ImageIO

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        // There are three ways to provide a thumbnail through a QLThumbnailReply. Only one of them should be used.
        
        
        // First way: Draw the thumbnail into the current context, set up with UIKit's coordinate system.
//        handler(QLThumbnailReply(contextSize: request.maximumSize, currentContextDrawing: { () -> Bool in
//            // Draw the thumbnail here.
//            
//            // Return true if the thumbnail was successfully drawn inside this block.
//            return true
//        }), nil)
        
        
        // Second way: Draw the thumbnail into a context passed to your block, set up with Core Graphics's coordinate system.
        handler(QLThumbnailReply(contextSize: request.maximumSize, drawing: { (context) -> Bool in
            if let content = self.readFileFromZip(at: request.fileURL, fileName: "Thumbnails/thumbnail.png") {
                print("found \(content.count) byte thumbnail")
                self.drawPNGDataToContext(content, context: context)
                return true
            } else {
                print("failed to read the file")
                return false
            }
        }), nil)
         
        /*
        // Third way: Set an image file URL.
        handler(QLThumbnailReply(imageFileURL: Bundle.main.url(forResource: "fileThumbnail", withExtension: "jpg")!), nil)
        
        */
    }
    
    func readFileFromZip(at zipFileURL: URL, fileName: String) -> Data? {
        let fileManager = FileManager.default
        
        // Ensure the file exists
        guard fileManager.fileExists(atPath: zipFileURL.path) else {
            print("ZIP file not found at \(zipFileURL.path)")
            return nil
        }
        
        do {
            // Open the archive directly from the URL
            guard let archive = Archive(url: zipFileURL, accessMode: .read) else {
                print("Failed to open ZIP archive.")
                return nil
            }
            
            // Look for the desired file inside the ZIP archive
            if let entry = archive[fileName] {
                var data = Data()
                
                // Extract the entry directly into memory
                _ = try archive.extract(entry, consumer: { dataChunk in
                    data.append(dataChunk)
                })
                
                return data
            } else {
                print("File not found in ZIP archive.")
                return nil
            }
        } catch {
            print("Error: \(error)")
            return nil
        }
    }
    
    func drawPNGDataToContext(_ data: Data, context: CGContext) {
        // Create a CGImageSource from the data
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("Failed to create CGImageSource.")
            return
        }

        // Create a CGImage from the source
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("Failed to create CGImage.")
            return
        }
        
        // Draw the CGImage into the provided context
        let imageAspect = CGFloat(cgImage.width) / CGFloat(cgImage.height)
        let contextAspect = CGFloat(context.width) / CGFloat(context.height)

        var drawRect = CGRect.zero

        if imageAspect > contextAspect {
            // Image is wider relative to the context
            let scaledHeight = CGFloat(context.width) / imageAspect
            drawRect = CGRect(x: 0, y: (CGFloat(context.height) - scaledHeight) / 2, width: CGFloat(context.width), height: scaledHeight)
        } else {
            // Image is taller relative to the context
            let scaledWidth = CGFloat(context.height) * imageAspect
            drawRect = CGRect(x: (CGFloat(context.width) - scaledWidth) / 2, y: 0, width: scaledWidth, height: CGFloat(context.height))
        }

        context.draw(cgImage, in: drawRect)
    }
}
