//
//  PreviewProvider.swift
//  mscz-ql-plugin
//
//  Created by Ben on 3/18/25.
//

import Cocoa
import Quartz
import ZIPFoundation

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    

    /*
     Use a QLPreviewProvider to provide data-based previews.
     
     To set up your extension as a data-based preview extension:

     - Modify the extension's Info.plist by setting
       <key>QLIsDataBasedPreview</key>
       <true/>
     
     - Add the supported content types to QLSupportedContentTypes array in the extension's Info.plist.

     - Change the NSExtensionPrincipalClass to this class.
       e.g.
       <key>NSExtensionPrincipalClass</key>
       <string>$(PRODUCT_MODULE_NAME).PreviewProvider</string>
     
     - Implement providePreview(for:)
     */
    
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        print("previewing from PP")

        //You can create a QLPreviewReply in several ways, depending on the format of the data you want to return.
        //To return Data of a supported content type:
        
        if let pdf = readFileFromZip(at: request.fileURL, fileName: "Thumbnails/score.pdf") {
            print("found \(pdf.count) byte pdf")
            let reply = QLPreviewReply.init(forPDFWithPageSize: CGSize.init(width: 800, height: 800)) { (reply: QLPreviewReply) in
                
                reply.title = "MSCZ QL PDF"
                
                if let doc = PDFDocument.init(data: pdf) {
                    return doc
                } else {
                    throw NSError(domain: "PreviewProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF preview"])
                }
            }
            
            return reply
        } else {
            print("failed to read the file")
            return QLPreviewReply() // todo: throw error
        }
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
}
