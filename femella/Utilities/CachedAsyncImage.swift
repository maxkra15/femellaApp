import SwiftUI

public struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let content: (AsyncImagePhase) -> Content
    
    @State private var phase: AsyncImagePhase
    
    public init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
        self._phase = State(initialValue: .empty)
    }
    
    public var body: some View {
        content(phase)
            .onAppear(perform: loadImage)
    }
    
    private func loadImage() {
        guard let url = url else {
            phase = .empty
            return
        }
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        
        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let uiImage = UIImage(data: cachedResponse.data) {
            self.phase = .success(Image(uiImage: uiImage))
            return
        }
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
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
                await MainActor.run {
                    self.phase = .failure(error)
                }
            }
        }
    }
}
