//
//  FileDownloadViewModel.swift
//  TestFileDownload
//
//  Created by jaehwikim on 2/17/25.
//

import Foundation

@MainActor
final class FileDownloadViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var downloadedFilePath: String?

    let fileURL = "https://jsoncompare.org/LearningContainer/SampleFiles/PDF/sample-500mb-pdf-download.pdf"
    
    func startDownload() {
        downloadedFilePath = nil
        progress = 0.0
        
        Task {
            do {
                let stream = FileDownloadService.shared.downloadFile(urlString: fileURL)
                for try await event in stream {
                    switch event {
                    case .progress(let value):
                        await MainActor.run {
                            self.progress = value
                        }
                    case .finished(let location):
                        await MainActor.run {
                            self.progress = 1.0
                            self.downloadedFilePath = location.absoluteString
                        }
                    }
                }
            } catch {
                print("다운로드 에러: \(error)")
            }
        }
    }
}
