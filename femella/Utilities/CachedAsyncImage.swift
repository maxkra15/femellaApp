import SwiftUI

enum ImageCacheManager {
    static func removeCachedImage(for url: URL?) {
        guard let url else { return }

        var candidates = Set<URL>()
        candidates.insert(url)

        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.query = nil
            components.fragment = nil
            if let normalizedURL = components.url {
                candidates.insert(normalizedURL)
            }
        }

        for candidate in candidates {
            URLCache.shared.removeCachedResponse(
                for: URLRequest(url: candidate, cachePolicy: .returnCacheDataElseLoad)
            )
            URLCache.shared.removeCachedResponse(
                for: URLRequest(url: candidate, cachePolicy: .useProtocolCachePolicy)
            )
        }
    }
}

public struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let content: (AsyncImagePhase) -> Content
    
    @State private var phase: AsyncImagePhase
    @State private var loadTask: Task<Void, Never>?
    
    public init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
        self._phase = State(initialValue: .empty)
    }
    
    public var body: some View {
        content(phase)
            .onAppear(perform: loadImage)
            .onChange(of: url?.absoluteString) { _, _ in
                loadImage()
            }
            .onDisappear {
                loadTask?.cancel()
                loadTask = nil
            }
    }
    
    private func loadImage() {
        loadTask?.cancel()
        loadTask = nil

        guard let url = url else {
            phase = .empty
            return
        }

        phase = .empty
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)

        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let uiImage = UIImage(data: cachedResponse.data) {
            self.phase = .success(Image(uiImage: uiImage))
            return
        }

        loadTask = Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard !Task.isCancelled else { return }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    await MainActor.run {
                        self.phase = .failure(URLError(.badServerResponse))
                    }
                    return
                }

                if let uiImage = UIImage(data: data) {
                    let cachedData = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedData, for: request)
                    await MainActor.run {
                        self.phase = .success(Image(uiImage: uiImage))
                    }
                } else {
                    await MainActor.run {
                        self.phase = .failure(URLError(.cannotDecodeRawData))
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.phase = .failure(error)
                }
            }
        }
    }
}
