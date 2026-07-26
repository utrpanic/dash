public struct BusArrivalListResponseDTO: Decodable, Equatable, Sendable {
  public let response: ResponseDTO

  func toDomain() -> [BusArrival] {
    response.msgBody.busArrivalList.values.map { $0.toDomain() }
  }
}

extension BusArrivalListResponseDTO: BusArrivalAPIResponseDTO {
  var resultCode: Int { response.msgHeader.resultCode }
  var resultMessage: String { response.msgHeader.resultMessage }
}

public extension BusArrivalListResponseDTO {
  struct ResponseDTO: Decodable, Equatable, Sendable {
    public let msgHeader: MessageHeaderDTO
    public let msgBody: MessageBodyDTO
  }

  struct MessageHeaderDTO: Decodable, Equatable, Sendable {
    public let resultCode: Int
    public let resultMessage: String
  }

  struct MessageBodyDTO: Decodable, Equatable, Sendable {
    public let busArrivalList: FlexibleArrayDTO<BusArrivalDTO>
  }
}

public struct BusArrivalItemResponseDTO: Decodable, Equatable, Sendable {
  public let response: ResponseDTO

  func toDomain() -> BusArrival {
    response.msgBody.busArrivalItem.toDomain()
  }
}

extension BusArrivalItemResponseDTO: BusArrivalAPIResponseDTO {
  var resultCode: Int { response.msgHeader.resultCode }
  var resultMessage: String { response.msgHeader.resultMessage }
}

public extension BusArrivalItemResponseDTO {
  struct ResponseDTO: Decodable, Equatable, Sendable {
    public let msgHeader: BusArrivalListResponseDTO.MessageHeaderDTO
    public let msgBody: MessageBodyDTO
  }

  struct MessageBodyDTO: Decodable, Equatable, Sendable {
    public let busArrivalItem: BusArrivalDTO
  }
}

public struct BusArrivalDTO: Decodable, Equatable, Sendable {
  public let flag: String?
  public let locationNo1: LossyOptionalIntDTO?
  public let locationNo2: LossyOptionalIntDTO?
  public let plateNo1: String?
  public let plateNo2: String?
  public let predictTime1: LossyOptionalIntDTO?
  public let predictTime2: LossyOptionalIntDTO?
  public let predictTimeSec1: LossyOptionalIntDTO?
  public let predictTimeSec2: LossyOptionalIntDTO?
  public let remainSeatCnt1: LossyOptionalIntDTO?
  public let remainSeatCnt2: LossyOptionalIntDTO?
  public let routeDestName: String?
  public let routeId: LossyIntDTO
  public let routeName: LossyStringDTO
  public let staOrder: LossyIntDTO
  public let stateCd1: LossyOptionalIntDTO?
  public let stateCd2: LossyOptionalIntDTO?
  public let stationId: LossyIntDTO
  public let stationNm1: String?
  public let stationNm2: String?
  public let vehId1: LossyOptionalIntDTO?
  public let vehId2: LossyOptionalIntDTO?

  func toDomain() -> BusArrival {
    BusArrival(
      stationId: stationId.value,
      route: BusRoute(id: routeId.value, number: routeName.value, region: .gyeonggi),
      stationOrder: staOrder.value,
      destinationName: routeDestName ?? "",
      operationState: flag ?? "",
      firstPrediction: prediction(
        minutes: predictTime1?.value,
        seconds: predictTimeSec1?.value,
        locationNumber: locationNo1?.value,
        plateNumber: plateNo1,
        remainingSeatCount: remainSeatCnt1?.value,
        stateCode: stateCd1?.value,
        stationName: stationNm1,
        vehicleId: vehId1?.value
      ),
      secondPrediction: prediction(
        minutes: predictTime2?.value,
        seconds: predictTimeSec2?.value,
        locationNumber: locationNo2?.value,
        plateNumber: plateNo2,
        remainingSeatCount: remainSeatCnt2?.value,
        stateCode: stateCd2?.value,
        stationName: stationNm2,
        vehicleId: vehId2?.value
      )
    )
  }

  private func prediction(
    minutes: Int?,
    seconds: Int?,
    locationNumber: Int?,
    plateNumber: String?,
    remainingSeatCount: Int?,
    stateCode: Int?,
    stationName: String?,
    vehicleId: Int?
  ) -> BusArrivalPrediction? {
    guard minutes != nil || seconds != nil || locationNumber != nil || vehicleId != nil else {
      return nil
    }

    return BusArrivalPrediction(
      minutes: minutes,
      seconds: seconds,
      locationNumber: locationNumber,
      plateNumber: plateNumber ?? "",
      remainingSeatCount: remainingSeatCount,
      stateCode: stateCode,
      stationName: stationName ?? "",
      vehicleId: vehicleId
    )
  }
}

public struct FlexibleArrayDTO<Element: Decodable & Equatable & Sendable>: Decodable, Equatable, Sendable {
  public let values: [Element]

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    do {
      self.values = [try container.decode(Element.self)]
    } catch {
      self.values = try container.decode([Element].self)
    }
  }
}

public struct LossyIntDTO: Decodable, Equatable, Sendable {
  public let value: Int

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let int = try? container.decode(Int.self) {
      value = int
    } else if let string = try? container.decode(String.self),
              let int = Int(string.trimmingCharacters(in: .whitespacesAndNewlines)) {
      value = int
    } else {
      throw DecodingError.typeMismatch(
        Int.self,
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Expected an integer or integer string value."
        )
      )
    }
  }
}

public struct LossyOptionalIntDTO: Decodable, Equatable, Sendable {
  public let value: Int?

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if container.decodeNil() {
      value = nil
    } else if let int = try? container.decode(Int.self) {
      value = int
    } else if let string = try? container.decode(String.self) {
      let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
      value = trimmedString.isEmpty ? nil : Int(trimmedString)
    } else {
      value = nil
    }
  }
}

protocol BusArrivalAPIResponseDTO {
  var resultCode: Int { get }
  var resultMessage: String { get }
}
