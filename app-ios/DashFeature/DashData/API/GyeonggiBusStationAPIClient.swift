import DashDomain
import Foundation

public struct GyeonggiBusStationAPIService: Sendable {
  private let dataGoKrServiceKey: String

  public static let liveValue = Self(dataGoKrServiceKey: DashDataServiceKey.dataGoKrServiceKey)

  public init(dataGoKrServiceKey: String) {
    self.dataGoKrServiceKey = dataGoKrServiceKey
  }

  public func fetchRoutes(_ stationId: Int) async throws -> [BusStationViaRouteDTO] {
    let responseDTO: BusStationViaRouteListResponseDTO = try await fetch(
      .viaRouteList(stationId: stationId, serviceKey: serviceKey())
    )
    return responseDTO.response.msgBody?.busRouteList.values ?? []
  }

  public func searchStops(matching keyword: String) async throws -> [BusStop] {
    let response: GyeonggiBusStopListResponseDTO = try await fetch(
      .stationList(keyword: keyword, serviceKey: serviceKey())
    )
    return response.stops()
  }

  public func fetchNearbyStops(latitude: Double, longitude: Double) async throws -> [BusStop] {
    let response: GyeonggiBusStopAroundListResponseDTO = try await fetch(
      .stationAroundList(latitude: latitude, longitude: longitude, serviceKey: serviceKey())
    )
    return response.stops()
  }
}

public enum GyeonggiBusStationAPIError: Error, Equatable, Sendable {
  case missingServiceKey
  case invalidURL
  case invalidResponse
  case invalidStatusCode(Int)
  case apiFailure(resultCode: Int, message: String)
}

private enum GyeonggiBusStationAPIRequest {
  case viaRouteList(stationId: Int, serviceKey: String)
  case stationList(keyword: String, serviceKey: String)
  case stationAroundList(latitude: Double, longitude: Double, serviceKey: String)

  func url() throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "apis.data.go.kr"
    switch self {
    case .viaRouteList:
      components.path = "/6410000/busstationservice/v2/getBusStationViaRouteListv2"
      components.percentEncodedQuery = [
        "serviceKey=\(percentEncodedQueryValue(serviceKey))",
        "stationId=\(stationId)",
        "format=json"
      ].joined(separator: "&")
    case .stationList:
      components.path = "/6410000/busstationservice/v2/getBusStationListv2"
      components.percentEncodedQuery = [
        "serviceKey=\(percentEncodedQueryValue(serviceKey))",
        "keyword=\(percentEncodedQueryValue(keyword))",
        "format=json"
      ].joined(separator: "&")
    case .stationAroundList:
      components.path = "/6410000/busstationservice/v2/getBusStationAroundListv2"
      components.percentEncodedQuery = [
        "serviceKey=\(percentEncodedQueryValue(serviceKey))",
        "x=\(longitude)",
        "y=\(latitude)",
        "format=json"
      ].joined(separator: "&")
    }

    guard let url = components.url else {
      throw GyeonggiBusStationAPIError.invalidURL
    }

    return url
  }

  private var stationId: Int {
    switch self {
    case let .viaRouteList(stationId, _):
      stationId
    case .stationList, .stationAroundList:
      0
    }
  }

  private var keyword: String {
    if case let .stationList(keyword, _) = self { return keyword }
    return ""
  }

  private var latitude: Double {
    if case let .stationAroundList(latitude, _, _) = self { return latitude }
    return 0
  }

  private var longitude: Double {
    if case let .stationAroundList(_, longitude, _) = self { return longitude }
    return 0
  }

  private var serviceKey: String {
    switch self {
    case let .viaRouteList(_, serviceKey):
      serviceKey
    case let .stationList(_, serviceKey), let .stationAroundList(_, _, serviceKey):
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

private extension GyeonggiBusStationAPIService {
  func fetch<ResponseDTO: Decodable & BusStationAPIResponseDTO>(
    _ request: GyeonggiBusStationAPIRequest
  ) async throws -> ResponseDTO {
    let url = try request.url()
    var urlRequest = URLRequest(url: url)
    urlRequest.timeoutInterval = 15

    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw GyeonggiBusStationAPIError.invalidResponse
    }
    guard httpResponse.statusCode == 200 else {
      throw GyeonggiBusStationAPIError.invalidStatusCode(httpResponse.statusCode)
    }

    let responseDTO = try JSONDecoder().decode(ResponseDTO.self, from: data)
    guard responseDTO.resultCode == 0 else {
      throw GyeonggiBusStationAPIError.apiFailure(
        resultCode: responseDTO.resultCode,
        message: responseDTO.resultMessage
      )
    }

    return responseDTO
  }

  func serviceKey() throws -> String {
    let serviceKey = dataGoKrServiceKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !serviceKey.isEmpty else {
      throw GyeonggiBusStationAPIError.missingServiceKey
    }

    return serviceKey
  }
}
