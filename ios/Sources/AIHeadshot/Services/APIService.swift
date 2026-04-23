import Foundation

actor APIService {
    static let shared = APIService()
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL = Constants.baseURL) {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: - Templates
    func fetchTemplates() async throws -> [Template] {
        let request = makeRequest(path: Constants.API.templates)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        let result = try decoder.decode(TemplateListResponse.self, from: data)
        return result.templates
    }

    // MARK: - Generate Order
    func createOrder(userID: String, templateID: String, imageURL: String) async throws -> String {
        let body = OrderCreateRequest(userID: userID, templateID: templateID, originalImageURL: imageURL)
        var request = makeRequest(path: Constants.API.generate, method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        let result = try decoder.decode(OrderCreateResponse.self, from: data)
        return result.orderID
    }

    // MARK: - SSE Progress
    func streamOrderStatus(orderID: String) -> AsyncThrowingStream<SSEProgressEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let request = self.makeRequest(path: Constants.API.orderStatus(orderID: orderID))
                do {
                    let (bytes, response) = try await self.session.bytes(for: request, delegate: nil)
                    try self.validate(response: response, data: Data())
                    var buffer = Data()
                    for try await byte in bytes {
                        buffer.append(byte)
                        if let string = String(data: buffer, encoding: .utf8), string.contains("\n\n") {
                            let lines = string.components(separatedBy: "\n")
                            for line in lines {
                                if line.hasPrefix("data: ") {
                                    let json = String(line.dropFirst(6))
                                    if let jsonData = json.data(using: .utf8) {
                                        if let event = try? self.decoder.decode(SSEProgressEvent.self, from: jsonData) {
                                            continuation.yield(event)
                                            let terminalStatuses = [
                                                Constants.OrderStatus.completed.rawValue,
                                                Constants.OrderStatus.failed.rawValue,
                                                Constants.OrderStatus.paid.rawValue
                                            ]
                                            if event.progress >= 100.0 || terminalStatuses.contains(event.status) {
                                                continuation.finish()
                                                return
                                            }
                                        }
                                    }
                                }
                            }
                            buffer.removeAll()
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Verify Payment
    func verifyPayment(orderID: String, receiptData: String) async throws -> VerifyPaymentResponse {
        let body = VerifyPaymentRequest(receiptData: receiptData)
        var request = makeRequest(path: Constants.API.verifyPayment(orderID: orderID), method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(VerifyPaymentResponse.self, from: data)
    }

    // MARK: - Private Helpers
    private func makeRequest(path: String, method: String = "GET") -> URLRequest {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var request = URLRequest(url: baseURL.appendingPathComponent(cleanPath))
        request.httpMethod = method
        request.setJSONContentType()
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            if let error = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw NSError(domain: "APIService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: error.message])
            }
            throw URLError(.badServerResponse)
        }
    }
}
