import CoreFoundation
import Foundation

enum SeoulBusAPIError: Error, Equatable, Sendable {
  case missingServiceKey
  case invalidURL
  case invalidResponse
  case invalidStatusCode(Int)
  case apiFailure(code: String, message: String)
  case malformedResponse(String)
  case invalidField(String)
}

struct SeoulBusAPIResponse: Equatable, Sendable {
  let header: [String: String]
  let items: [[String: String]]
}

enum SeoulBusAPITransport {
  static func fetch(
    path: String,
    parameters: [(name: String, value: String)]
  ) async throws -> SeoulBusAPIResponse {
    var components = URLComponents()
    components.scheme = "http"
    components.host = "ws.bus.go.kr"
    components.path = path
    components.percentEncodedQuery = (parameters + [("resultType", "json")])
      .map { "\($0.name)=\(percentEncodedQueryValue($0.value))" }
      .joined(separator: "&")

    guard let url = components.url else {
      throw SeoulBusAPIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.timeoutInterval = 15

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw SeoulBusAPIError.invalidResponse
    }
    guard httpResponse.statusCode == 200 else {
      throw SeoulBusAPIError.invalidStatusCode(httpResponse.statusCode)
    }

    let apiResponse = try SeoulBusAPIJSONParser.parse(data)
    let resultCode = apiResponse.header["headerCd"]
      ?? apiResponse.header["resultCode"]
      ?? apiResponse.header["returnReasonCode"]
    let resultMessage = apiResponse.header["headerMsg"]
      ?? apiResponse.header["resultMessage"]
      ?? apiResponse.header["returnAuthMsg"]
      ?? ""

    guard let resultCode else {
      throw SeoulBusAPIError.malformedResponse("Missing result code.")
    }
    guard resultCode == "0" || resultCode == "00" else {
      throw SeoulBusAPIError.apiFailure(code: resultCode, message: resultMessage)
    }

    return apiResponse
  }

  static func serviceKey() throws -> String {
    let serviceKey = Secrets.serviceKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !serviceKey.isEmpty else {
      throw SeoulBusAPIError.missingServiceKey
    }

    return serviceKey
  }

  private static func percentEncodedQueryValue(_ value: String) -> String {
    if value.contains("%") {
      return value
    }

    var allowedCharacters = CharacterSet.urlQueryAllowed
    allowedCharacters.remove(charactersIn: "&=+")

    return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
  }
}

struct SeoulBusAPIFields {
  let values: [String: String]

  func string(_ name: String) -> String {
    values[name]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  func requiredInt(_ name: String) throws -> Int {
    guard let value = Int(string(name)) else {
      throw SeoulBusAPIError.invalidField(name)
    }

    return value
  }

  func optionalInt(_ name: String) -> Int? {
    Int(string(name))
  }

  func requiredDouble(_ name: String) throws -> Double {
    guard let value = Double(string(name)) else {
      throw SeoulBusAPIError.invalidField(name)
    }

    return value
  }
}

enum SeoulBusAPIJSONParser {
  static func parse(_ data: Data) throws -> SeoulBusAPIResponse {
    let json: Any
    do {
      json = try JSONSerialization.jsonObject(with: data)
    } catch {
      throw SeoulBusAPIError.malformedResponse("Unable to parse JSON response.")
    }

    guard let root = json as? [String: Any] else {
      throw SeoulBusAPIError.malformedResponse("Invalid JSON response root.")
    }

    var header = try strings(in: root["msgHeader"], fieldName: "msgHeader")
    let commonHeader = try strings(in: root["comMsgHeader"], fieldName: "comMsgHeader")
    header.merge(commonHeader) { current, _ in current }

    guard let body = root["msgBody"] as? [String: Any] else {
      return SeoulBusAPIResponse(header: header, items: [])
    }

    let items: [[String: String]]
    switch body["itemList"] {
    case let itemList as [[String: Any]]:
      items = try itemList.map { try strings(in: $0, fieldName: "itemList") }
    case let item as [String: Any]:
      items = [try strings(in: item, fieldName: "itemList")]
    case nil, is NSNull:
      items = []
    default:
      throw SeoulBusAPIError.malformedResponse("Invalid itemList field.")
    }

    return SeoulBusAPIResponse(header: header, items: items)
  }

  private static func strings(in value: Any?, fieldName: String) throws -> [String: String] {
    guard let value, !(value is NSNull) else {
      return [:]
    }
    guard let object = value as? [String: Any] else {
      throw SeoulBusAPIError.malformedResponse("Invalid \(fieldName) field.")
    }

    return try object.reduce(into: [:]) { result, field in
      guard !(field.value is NSNull) else {
        return
      }
      guard let string = string(from: field.value) else {
        throw SeoulBusAPIError.malformedResponse("Invalid \(fieldName).\(field.key) field.")
      }
      result[field.key] = string
    }
  }

  private static func string(from value: Any) -> String? {
    if let value = value as? String {
      return value
    }
    guard let value = value as? NSNumber else {
      return nil
    }
    if CFGetTypeID(value) == CFBooleanGetTypeID() {
      return value.boolValue ? "true" : "false"
    }
    return value.stringValue
  }
}
