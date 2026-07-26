import ComposableArchitecture
import Foundation

public struct BusRouteAPIClient: Sendable {
  public var fetchRouteInfo: @Sendable (_ routeId: Int) async throws -> BusRouteInfo
  public var fetchRouteLine: @Sendable (_ routeId: Int) async throws -> [BusRouteLinePoint]
  public var searchRoutes: @Sendable (_ keyword: String) async throws -> [BusRoute]

  public init(
    fetchRouteInfo: @escaping @Sendable (_ routeId: Int) async throws -> BusRouteInfo,
    fetchRouteLine: @escaping @Sendable (_ routeId: Int) async throws -> [BusRouteLinePoint],
    searchRoutes: @escaping @Sendable (_ keyword: String) async throws -> [BusRoute]
  ) {
    self.fetchRouteInfo = fetchRouteInfo
    self.fetchRouteLine = fetchRouteLine
    self.searchRoutes = searchRoutes
  }
}

extension BusRouteAPIClient: DependencyKey {
  public static let liveValue = Self(
    fetchRouteInfo: { routeId in
      let responseDTO: BusRouteInfoResponseDTO = try await Self.fetch(
        .routeInfo(routeId: routeId, serviceKey: serviceKey())
      )
      return responseDTO.toDomain()
    },
    fetchRouteLine: { routeId in
      let responseDTO: BusRouteLineResponseDTO = try await Self.fetch(
        .routeLine(routeId: routeId, serviceKey: serviceKey())
      )
      return responseDTO.toDomain()
    },
    searchRoutes: { keyword in
      let responseDTO: BusRouteListResponseDTO = try await Self.fetch(
        .routeList(keyword: keyword, serviceKey: serviceKey())
      )
      return responseDTO.toDomain()
    }
  )

  public static let testValue = Self(
    fetchRouteInfo: { _ in
      BusRouteInfo(
        route: BusRoute(id: 0, number: "", region: .gyeonggi),
        routeTypeName: "",
        regionName: "",
        companyName: "",
        startStationName: "",
        endStationName: ""
      )
    },
    fetchRouteLine: { _ in [] },
    searchRoutes: { _ in [] }
  )
}

extension DependencyValues {
  public var busRouteAPIClient: BusRouteAPIClient {
    get { self[BusRouteAPIClient.self] }
    set { self[BusRouteAPIClient.self] = newValue }
  }
}

public enum BusRouteAPIError: Error, Equatable, Sendable {
  case missingServiceKey
  case invalidURL
  case invalidResponse
  case invalidStatusCode(Int)
  case apiFailure(resultCode: Int, message: String)
}

private enum BusRouteAPIRequest {
  case routeInfo(routeId: Int, serviceKey: String)
  case routeLine(routeId: Int, serviceKey: String)
  case routeList(keyword: String, serviceKey: String)

  func url() throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "apis.data.go.kr"
    components.path = path
    components.percentEncodedQuery = query

    guard let url = components.url else {
      throw BusRouteAPIError.invalidURL
    }

    return url
  }

  private var path: String {
    switch self {
    case .routeInfo:
      "/6410000/busrouteservice/v2/getBusRouteInfoItemv2"
    case .routeLine:
      "/6410000/busrouteservice/v2/getBusRouteLineListv2"
    case .routeList:
      "/6410000/busrouteservice/v2/getBusRouteListv2"
    }
  }

  private var query: String {
    switch self {
    case let .routeInfo(routeId, serviceKey),
         let .routeLine(routeId, serviceKey):
      [
        "serviceKey=\(percentEncodedQueryValue(serviceKey))",
        "routeId=\(routeId)",
        "format=json"
      ].joined(separator: "&")

    case let .routeList(keyword, serviceKey):
      [
        "serviceKey=\(percentEncodedQueryValue(serviceKey))",
        "keyword=\(percentEncodedQueryValue(keyword))",
        "format=json"
      ].joined(separator: "&")
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

private extension BusRouteAPIClient {
  static func fetch<ResponseDTO: Decodable & BusRouteAPIResponseDTO>(
    _ request: BusRouteAPIRequest
  ) async throws -> ResponseDTO {
    let url = try request.url()
    var urlRequest = URLRequest(url: url)
    urlRequest.timeoutInterval = 15

    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw BusRouteAPIError.invalidResponse
    }
    guard httpResponse.statusCode == 200 else {
      throw BusRouteAPIError.invalidStatusCode(httpResponse.statusCode)
    }

    let responseDTO = try JSONDecoder().decode(ResponseDTO.self, from: data)
    guard responseDTO.resultCode == 0 else {
      throw BusRouteAPIError.apiFailure(
        resultCode: responseDTO.resultCode,
        message: responseDTO.resultMessage
      )
    }

    return responseDTO
  }

  static func serviceKey() throws -> String {
    let serviceKey = Secrets.serviceKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !serviceKey.isEmpty else {
      throw BusRouteAPIError.missingServiceKey
    }

    return serviceKey
  }
}
