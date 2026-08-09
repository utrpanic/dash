import DashDomain
import Foundation

public struct GyeonggiBusArrivalAPIService: GyeonggiBusArrivalAPI {
  private let dataGoKrServiceKey: String

  public static let liveValue = Self(dataGoKrServiceKey: DashDataServiceKey.dataGoKrServiceKey)

  public init(dataGoKrServiceKey: String) {
    self.dataGoKrServiceKey = dataGoKrServiceKey
  }

  public func fetchArrival(
    _ stationId: Int,
    _ routeId: Int,
    _ stationOrder: Int
  ) async throws -> BusArrival {
    let responseDTO: BusArrivalItemResponseDTO = try await fetch(
      .arrivalItem(
        stationId: stationId,
        routeId: routeId,
        stationOrder: stationOrder,
        serviceKey: serviceKey()
      )
    )
    return responseDTO.toDomain()
  }

  public func fetchArrivals(_ stationId: Int) async throws -> [BusArrival] {
    let responseDTO: BusArrivalListResponseDTO = try await fetch(
      .arrivalList(stationId: stationId, serviceKey: serviceKey())
    )
    return responseDTO.toDomain()
  }
}

public enum GyeonggiBusArrivalAPIError: Error, Equatable, Sendable {
  case missingServiceKey
  case invalidURL
  case invalidResponse
  case invalidStatusCode(Int)
  case apiFailure(resultCode: Int, message: String)
}

private enum GyeonggiBusArrivalAPIRequest {
  case arrivalItem(stationId: Int, routeId: Int, stationOrder: Int, serviceKey: String)
  case arrivalList(stationId: Int, serviceKey: String)

  func url() throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "apis.data.go.kr"
    components.path = path
    components.percentEncodedQuery = query

    guard let url = components.url else {
      throw GyeonggiBusArrivalAPIError.invalidURL
    }

    return url
  }

  private var path: String {
    switch self {
    case .arrivalItem:
      "/6410000/busarrivalservice/v2/getBusArrivalItemv2"
    case .arrivalList:
      "/6410000/busarrivalservice/v2/getBusArrivalListv2"
    }
  }

  private var query: String {
    switch self {
    case let .arrivalItem(stationId, routeId, stationOrder, serviceKey):
      [
        "serviceKey=\(percentEncodedQueryValue(serviceKey))",
        "stationId=\(stationId)",
        "routeId=\(routeId)",
        "staOrder=\(stationOrder)",
        "format=json"
      ].joined(separator: "&")

    case let .arrivalList(stationId, serviceKey):
      [
        "serviceKey=\(percentEncodedQueryValue(serviceKey))",
        "stationId=\(stationId)",
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

private extension GyeonggiBusArrivalAPIService {
  func fetch<ResponseDTO: Decodable & BusArrivalAPIResponseDTO>(
    _ request: GyeonggiBusArrivalAPIRequest
  ) async throws -> ResponseDTO {
    let url = try request.url()
    var urlRequest = URLRequest(url: url)
    urlRequest.timeoutInterval = 15

    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw GyeonggiBusArrivalAPIError.invalidResponse
    }
    guard httpResponse.statusCode == 200 else {
      throw GyeonggiBusArrivalAPIError.invalidStatusCode(httpResponse.statusCode)
    }

    let responseDTO = try JSONDecoder().decode(ResponseDTO.self, from: data)
    guard responseDTO.resultCode == 0 else {
      throw GyeonggiBusArrivalAPIError.apiFailure(
        resultCode: responseDTO.resultCode,
        message: responseDTO.resultMessage
      )
    }

    return responseDTO
  }

  func serviceKey() throws -> String {
    let serviceKey = dataGoKrServiceKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !serviceKey.isEmpty else {
      throw GyeonggiBusArrivalAPIError.missingServiceKey
    }

    return serviceKey
  }
}
