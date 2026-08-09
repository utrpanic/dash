import ComposableArchitecture
import DashDomain
import Foundation

public struct BusStationAPIClient: Sendable {
  public var fetchRoutes: @Sendable (_ stationId: Int) async throws -> [BusRoute]

  public init(
    fetchRoutes: @escaping @Sendable (_ stationId: Int) async throws -> [BusRoute]
  ) {
    self.fetchRoutes = fetchRoutes
  }
}

extension BusStationAPIClient: DependencyKey {
  public static let liveValue = Self(
    fetchRoutes: { stationId in
      let responseDTO: BusStationViaRouteListResponseDTO = try await Self.fetch(
        .viaRouteList(stationId: stationId, serviceKey: serviceKey())
      )
      return responseDTO.toDomain()
    }
  )

  public static let testValue = Self(fetchRoutes: { _ in [] })
}

extension DependencyValues {
  public var busStationAPIClient: BusStationAPIClient {
    get { self[BusStationAPIClient.self] }
    set { self[BusStationAPIClient.self] = newValue }
  }
}

public enum BusStationAPIError: Error, Equatable, Sendable {
  case missingServiceKey
  case invalidURL
  case invalidResponse
  case invalidStatusCode(Int)
  case apiFailure(resultCode: Int, message: String)
}

private enum BusStationAPIRequest {
  case viaRouteList(stationId: Int, serviceKey: String)

  func url() throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "apis.data.go.kr"
    components.path = "/6410000/busstationservice/v2/getBusStationViaRouteListv2"
    components.percentEncodedQuery = [
      "serviceKey=\(percentEncodedQueryValue(serviceKey))",
      "stationId=\(stationId)",
      "format=json"
    ].joined(separator: "&")

    guard let url = components.url else {
      throw BusStationAPIError.invalidURL
    }

    return url
  }

  private var stationId: Int {
    switch self {
    case let .viaRouteList(stationId, _):
      stationId
    }
  }

  private var serviceKey: String {
    switch self {
    case let .viaRouteList(_, serviceKey):
      serviceKey
    }
  }

  private func percentEncodedQueryValue(_ value: String) -> String {
    if value.contains("%") {
      return value
    }

    var allowedCharacters = CharacterSet.urlQueryAllowed
    allowedCharacters.remove(charactersIn: "&=+")

    return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
  }
}

private extension BusStationAPIClient {
  static func fetch<ResponseDTO: Decodable & BusStationAPIResponseDTO>(
    _ request: BusStationAPIRequest
  ) async throws -> ResponseDTO {
    let url = try request.url()
    var urlRequest = URLRequest(url: url)
    urlRequest.timeoutInterval = 15

    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw BusStationAPIError.invalidResponse
    }
    guard httpResponse.statusCode == 200 else {
      throw BusStationAPIError.invalidStatusCode(httpResponse.statusCode)
    }

    let responseDTO = try JSONDecoder().decode(ResponseDTO.self, from: data)
    guard responseDTO.resultCode == 0 else {
      throw BusStationAPIError.apiFailure(
        resultCode: responseDTO.resultCode,
        message: responseDTO.resultMessage
      )
    }

    return responseDTO
  }

  static func serviceKey() throws -> String {
    let serviceKey = Secrets.serviceKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !serviceKey.isEmpty else {
      throw BusStationAPIError.missingServiceKey
    }

    return serviceKey
  }
}
