import Foundation

class DownloadDelegate: NSObject, URLSessionDataDelegate {
    var expectedContentLength = 0
    var totalBytesReceived = 0
    var onCompletion: ((Result<Data, Error>) -> Void)?
    var downloadedData = Data()

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        expectedContentLength = Int(response.expectedContentLength)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        totalBytesReceived += data.count
        downloadedData.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onCompletion?(.failure(error))
        } else {
            onCompletion?(.success(downloadedData))
        }
    }
}

class MultiThreadDownloader: NSObject, URLSessionTaskDelegate {
    let originalUrl: URL
    var finalUrl: URL?
    let numberOfThreads: Int
    var fileSize: Int = 0
    var downloadedData: [Data?]
    var tasks: [URLSessionDataTask?] = [] // Array to keep track of tasks for cancellation

    init(url: URL, fileSize: Int = 0, numberOfThreads: Int = 4) {
        self.originalUrl = url
        self.finalUrl = url
        self.fileSize = fileSize
        self.numberOfThreads = numberOfThreads
        self.downloadedData = Array(repeating: nil, count: numberOfThreads)
        self.tasks = Array(repeating: nil, count: numberOfThreads)
    }

    func fetchFileSize() async throws -> Int {
        var request = URLRequest(url: finalUrl!)
        request.httpMethod = "HEAD"

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
              let fileSize = Int(contentLength) else {
            throw URLError(.badServerResponse)
        }

        return fileSize
    }

    func downloadChunkWithProgress(from start: Int, to end: Int, index: Int) async throws -> Data {
        var request = URLRequest(url: finalUrl!)
        request.addValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
        print("Download Chunk With Progress: \(index), start: \(start), end: \(end)")

        let delegate = DownloadDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: request)

        tasks[index] = task

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            delegate.onCompletion = { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            task.resume()
        }
    }

    func mergeChunks() throws -> URL {
        let fileName = "downloaded_file.mp4"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let outputStream = OutputStream(url: fileURL, append: false)!
        outputStream.open()

        for data in downloadedData {
            if let data = data {
                data.withUnsafeBytes {
                    outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
                }
            }
        }
        
        outputStream.close()
        return fileURL
    }

    func start() async throws -> URL {

        finalUrl = try await getRedirectedURL(from: originalUrl)

        self.fileSize = fileSize > 0 ? fileSize : try await fetchFileSize()
        let chunkSize = fileSize / numberOfThreads

        try await withThrowingTaskGroup(of: (Int, Data).self) { group in
            for i in 0..<numberOfThreads {
                let start = i * chunkSize
                let end = (i == numberOfThreads - 1) ? fileSize - 1 : (start + chunkSize - 1)
                
                group.addTask {
                    let data = try await self.downloadChunkWithProgress(from: start, to: end, index: i)
                    return (i, data)
                }
            }

            for try await (index, data) in group {
                self.downloadedData[index] = data
                print("Chunk \(index) downloaded")
            }
        }

        let mergedFileURL = try mergeChunks()
        print("File merged at: \(mergedFileURL.path)")
        return mergedFileURL
    }

    func getRedirectedURL(from originalUrl: URL) async throws -> URL {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let request = URLRequest(url: originalUrl)
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           let location = httpResponse.value(forHTTPHeaderField: "Location"),
           let url = URL(string: location) {
            return url
        } else {
            return originalUrl
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if let redirectedUrl = request.url {
            print("Redirected to: \(redirectedUrl)")
            self.finalUrl = redirectedUrl
            completionHandler(nil)
        } else {
            completionHandler(request)
        }
    }

    func cancelDownload() {
        tasks.forEach { $0?.cancel() }
        print("Download cancelled.")
    }
}
