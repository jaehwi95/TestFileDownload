//
//  FileDownloadService.swift
//  TestFileDownload
//
//  Created by jaehwikim on 2/17/25.
//

import Foundation

final class FileDownloadService: NSObject, URLSessionDownloadDelegate {
    static let shared = FileDownloadService()
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    private var progressContinuation: AsyncStream<Double>.Continuation?
    
    func downloadFile(urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        let session = urlSession
        
        return try await withCheckedThrowingContinuation { continuation in
            let downloadTask = session.downloadTask(with: url) { location, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // file is downloaded temporarily and stored in location
                guard let location = location else {
                    continuation.resume(throwing: NSError(domain: "Download Error", code: -3))
                    return
                }

                // Move downloaded file to a temporary directory
                let fileManager = FileManager.default
                guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    continuation.resume(throwing: NSError(domain: "Invalid File Document Directory", code: -4))
                    return
                }
                let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)

                do {
                    // if file with same name already exists, remove it before saving the new file
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    // move the file from the temporary location to destinationURL
                    try fileManager.moveItem(at: location, to: destinationURL)
                    continuation.resume(returning: destinationURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            downloadTask.resume()
        }
    }
    
    func downloadProgress() -> AsyncStream<Double> {
        return AsyncStream { continuation in
            self.progressContinuation = continuation
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("finished: \(location)")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("downloading: \(totalBytesWritten/1024/1024)MB of \(totalBytesExpectedToWrite/1024/1024)MB")
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progressContinuation?.yield(progress)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("resume: \(fileOffset/1024/1024)MB of \(expectedTotalBytes/1024/1024)MB")
    }
}
