struct SeoulBusArrivalDTO: Equatable, Sendable {
  let stationId: Int
  let routeId: Int
  let routeNumber: String
  let stationOrder: Int
  let destinationName: String
  let isDetouring: Bool
  let firstPrediction: PredictionDTO?
  let secondPrediction: PredictionDTO?

  init(fields: [String: String]) throws {
    let fields = SeoulBusAPIFields(values: fields)
    stationId = try fields.requiredInt("stId")
    routeId = try fields.requiredInt("busRouteId")
    routeNumber = {
      let routeName = fields.string("rtNm")
      return routeName.isEmpty ? fields.string("busRouteAbrv") : routeName
    }()
    stationOrder = try fields.requiredInt("staOrd")
    destinationName = fields.string("dir")
    isDetouring = fields.string("deTourAt") == "11"
    firstPrediction = PredictionDTO(index: 1, fields: fields)
    secondPrediction = PredictionDTO(index: 2, fields: fields)
  }

  func toDomain() -> BusArrival {
    BusArrival(
      stationId: stationId,
      route: BusRoute(id: routeId, number: routeNumber, region: .seoul),
      stationOrder: stationOrder,
      destinationName: destinationName,
      operationState: isDetouring ? "우회" : "",
      firstPrediction: firstPrediction?.toDomain(),
      secondPrediction: secondPrediction?.toDomain()
    )
  }
}

extension SeoulBusArrivalDTO {
  struct PredictionDTO: Equatable, Sendable {
    let seconds: Int?
    let plateNumber: String
    let remainingSeatCount: Int?
    let stateCode: Int?
    let stationName: String
    let vehicleId: Int?

    init?(index: Int, fields: SeoulBusAPIFields) {
      let seconds = fields.optionalInt("exps\(index)")
      let plateNumber = fields.string("plainNo\(index)")
      let vehicleId = fields.optionalInt("vehId\(index)").flatMap { $0 > 0 ? $0 : nil }
      let arrivalMessage = fields.string("arrmsg\(index)")

      guard vehicleId != nil
        || !plateNumber.isEmpty
        || (seconds ?? 0) > 0
        || (!arrivalMessage.isEmpty && arrivalMessage != "운행종료")
      else {
        return nil
      }

      self.seconds = seconds
      self.plateNumber = plateNumber
      self.remainingSeatCount = fields.optionalInt("rerdie_Div\(index)") == 2
        ? fields.optionalInt("reride_Num\(index)")
        : nil
      self.stateCode = fields.optionalInt("isArrive\(index)")
      self.stationName = fields.string("stationNm\(index)")
      self.vehicleId = vehicleId
    }

    func toDomain() -> BusArrivalPrediction {
      BusArrivalPrediction(
        minutes: seconds.map { $0 / 60 },
        seconds: seconds,
        locationNumber: nil,
        plateNumber: plateNumber,
        remainingSeatCount: remainingSeatCount,
        stateCode: stateCode,
        stationName: stationName,
        vehicleId: vehicleId
      )
    }
  }
}
