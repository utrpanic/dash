import DashDomain
import Foundation

public struct GyeonggiBusStationAPIService: GyeonggiBusStationAPI {
  private let dataGoKrServiceKey: String

  public static let liveValue = Self(dataGoKrServiceKey: DashDataServiceKey.dataGoKrServiceKey)

  public init(dataGoKrServiceKey: String) {
    self.dataGoKrServiceKey = dataGoKrServiceKey
  }

  public func fetchRoutes(_ stationId: Int) async throws -> [BusRoute] {
    let responseDTO: BusStationViaRouteListResponseDTO = try await fetch(
      .viaRouteList(stationId: stationId, serviceKey: serviceKey())
    )
    return responseDTO.toDomain()
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
      throw GyeonggiBusStationAPIError.invalidURL
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
