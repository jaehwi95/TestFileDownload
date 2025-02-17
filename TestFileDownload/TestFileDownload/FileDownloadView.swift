//
//  FileDownloadView.swift
//  TestFileDownload
//
//  Created by jaehwikim on 2/17/25.
//

import SwiftUI

struct FileDownloadView: View {
    @StateObject private var viewModel = FileDownloadViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Download Large File")
                .font(.title)
                .padding()

            if viewModel.isDownloading {
                VStack {
                    ProgressView(value: viewModel.progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 250)
                    
                    Text("\(Int(viewModel.progress * 100))% completed")
                        .font(.caption)
                        .padding()
                }
            } else {
                Button(action: {
                    viewModel.startDownload()
                }) {
                    Text("Start Download")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            if let filePath = viewModel.downloadedFilePath {
                Text("Downloaded File: \(filePath)")
                    .font(.footnote)
                    .padding()
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
}

#Preview {
    FileDownloadView()
}
