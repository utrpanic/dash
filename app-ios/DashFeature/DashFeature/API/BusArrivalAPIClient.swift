import ComposableArchitecture
import Foundation

public struct BusArrivalAPIClient: Sendable {
  public var fetchArrival: @Sendable (
    _ stationId: Int,
    _ routeId: Int,
    _ stationOrder: Int
  ) async throws -> BusArrival
  public var fetchArrivals: @Sendable (_ stationId: Int) async throws -> [BusArrival]

  public init(
    fetchArrival: @escaping @Sendable (
      _ stationId: Int,
      _ routeId: Int,
      _ stationOrder: Int
    ) async throws -> BusArrival,
    fetchArrivals: @escaping @Sendable (_ stationId: Int) async throws -> [BusArrival]
  ) {
    self.fetchArrival = fetchArrival
    self.fetchArrivals = fetchArrivals
  }
}

extension BusArrivalAPIClient: DependencyKey {
  public static let liveValue = Self(
    fetchArrival: { stationId, routeId, stationOrder in
      let responseDTO: BusArrivalItemResponseDTO = try await Self.fetch(
        .arrivalItem(
          stationId: stationId,
          routeId: routeId,
          stationOrder: stationOrder,
          serviceKey: serviceKey()
        )
      )
      return responseDTO.toDomain()
    },
    fetchArrivals: { stationId in
      let responseDTO: BusArrivalListResponseDTO = try await Self.fetch(
        .arrivalList(stationId: stationId, serviceKey: serviceKey())
      )
      return responseDTO.toDomain()
    }
  )

  public static let testValue = Self(
    fetchArrival: { _, _, _ in
      BusArrival(
        stationId: 0,
        route: BusRoute(id: 0, number: "", region: .gyeonggi),
        stationOrder: 0,
        destinationName: "",
        operationState: "",
        firstPrediction: nil,
        secondPrediction: nil
      )
    },
    fetchArrivals: { _ in [] }
  )
}

extension DependencyValues {
  public var busArrivalAPIClient: BusArrivalAPIClient {
    get { self[BusArrivalAPIClient.self] }
    set { self[BusArrivalAPIClient.self] = newValue }
  }
}

public enum BusArrivalAPIError: Error, Equatable, Sendable {
  case missingServiceKey
  case invalidURL
  case invalidResponse
  case invalidStatusCode(Int)
  case apiFailure(resultCode: Int, message: String)
}

private enum BusArrivalAPIRequest {
  case arrivalItem(stationId: Int, routeId: Int, stationOrder: Int, serviceKey: String)
  case arrivalList(stationId: Int, serviceKey: String)

  func url() throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "apis.data.go.kr"
    components.path = path
    components.percentEncodedQuery = query

    guard let url = components.url else {
      throw BusArrivalAPIError.invalidURL
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

private extension BusArrivalAPIClient {
  static func fetch<ResponseDTO: Decodable & BusArrivalAPIResponseDTO>(
    _ request: BusArrivalAPIRequest
  ) async throws -> ResponseDTO {
    let url = try request.url()
    var urlRequest = URLRequest(url: url)
    urlRequest.timeoutInterval = 15

    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw BusArrivalAPIError.invalidResponse
    }
    guard httpResponse.statusCode == 200 else {
      throw BusArrivalAPIError.invalidStatusCode(httpResponse.statusCode)
    }

    let responseDTO = try JSONDecoder().decode(ResponseDTO.self, from: data)
    guard responseDTO.resultCode == 0 else {
      throw BusArrivalAPIError.apiFailure(
        resultCode: responseDTO.resultCode,
        message: responseDTO.resultMessage
      )
    }

    return responseDTO
  }

  static func serviceKey() throws -> String {
    let serviceKey = Secrets.serviceKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !serviceKey.isEmpty else {
      throw BusArrivalAPIError.missingServiceKey
    }

    return serviceKey
  }
}
