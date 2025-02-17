//
//  FileDownloadViewModel.swift
//  TestFileDownload
//
//  Created by jaehwikim on 2/17/25.
//

import Foundation

@MainActor
class FileDownloadViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var isDownloading = false
    @Published var downloadedFilePath: String?
    @Published var errorMessage: String?

    let fileURL = "https://feeds.soundcloud.com/stream/1447464973-jonathan-pageau-307491252-275-michael-legaspi.mp3" // Sample 200MB file
    
    func startDownload() {
        guard !isDownloading else { return }
        
        isDownloading = true
        errorMessage = nil
        downloadedFilePath = nil
        progress = 0.0
        
        Task {
            await self.trackDownloadProgress()
            do {
                let downloadedURL = try await FileDownloadService.shared.downloadFile(urlString: fileURL)
                self.downloadedFilePath = downloadedURL.path()
            } catch {
                self.errorMessage = "Download Failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func trackDownloadProgress() async {
        for await progress in FileDownloadService.shared.downloadProgress() {
            self.progress = progress
        }
    }
}
