//
//  FileDownloadService.swift
//  TestFileDownload
//
//  Created by jaehwikim on 2/17/25.
//

import Foundation
import UniformTypeIdentifiers

enum DownloadStatus {
    case progress(Double)  // 0.0 ~ 1.0 사이의 진행률 값
    case finished(URL)     // 다운로드 완료 후 파일이 위치한 URL
}

final class FileDownloadService: NSObject, URLSessionDownloadDelegate {
    static let shared = FileDownloadService()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }()
    
    private var streamContinuation: AsyncThrowingStream<DownloadStatus, Error>.Continuation?

    private override init() {
        super.init()
    }
    
    func downloadFile(urlString: String) -> AsyncThrowingStream<DownloadStatus, Error> {
        guard let url = URL(string: urlString) else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: NSError(domain: "Invalid URL", code: -1))
            }
        }
        
        return AsyncThrowingStream { continuation in
            self.streamContinuation = continuation
            let task = self.session.downloadTask(with: url)
            task.resume()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Download finished at: \(location)")
        
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            streamContinuation?.finish(throwing: NSError(domain: "Invalid File Document Directory", code: -4))
            return
        }
        
        // 1. 파일명 결정: response의 suggestedFilename이 있으면 사용하고, 없으면 UUID로 생성
        var fileName = downloadTask.response?.suggestedFilename ?? UUID().uuidString
        
        // 2. 만약 파일명에 확장자가 없다면, response의 MIME 타입을 통해 확장자를 추론해 추가
        if (fileName as NSString).pathExtension.isEmpty,
           let mimeType = downloadTask.response?.mimeType,
           let utType = UTType(mimeType: mimeType),
           let ext = utType.preferredFilenameExtension {
            fileName += ".\(ext)"
        }
        
        // 3. 사용자가 지정한 Documents 내의 폴더 (예제에서는 "MyDownloads")
        let folderURL = documentsDirectory.appendingPathComponent("MyDownloads", isDirectory: true)
        try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        
        let destinationURL = folderURL.appendingPathComponent(fileName)
        
        do {
            // 기존에 같은 이름의 파일이 있다면 삭제
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            // 임시 파일을 지정한 destination으로 이동
            try fileManager.moveItem(at: location, to: destinationURL)
            print("File moved successfully to: \(destinationURL.path)")
            streamContinuation?.yield(.finished(destinationURL))
        } catch {
            print("File move error: \(error)")
            streamContinuation?.finish(throwing: error)
            return
        }
        streamContinuation?.finish()
        streamContinuation = nil
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        print("Downloading: \(totalBytesWritten/1024/1024)MB of \(totalBytesExpectedToWrite/1024/1024)MB, \(String(format: "%.0f", progress*100))%")
        streamContinuation?.yield(.progress(progress))
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("Download Resume: \(fileOffset/1024/1024)MB of \(expectedTotalBytes/1024/1024)MB")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download Error: \(error.localizedDescription)")
            streamContinuation?.finish(throwing: error)
            streamContinuation = nil
        }
    }
}
