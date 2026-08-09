# Specs

This directory contains reference materials used to design and implement Dash.

## Project

Overall service design is tracked in [Project](https://app.notion.com/p/Project-392b093902d180da9307d6170d5a90c8).

## Design

`design/` contains visual design references for the app UI.

Current reference:

- `design/initial-design.png`

## API

서비스 그룹과 현재 구현 상태는 [api/README.md](api/README.md)에 정리한다.

## 경기도_버스노선 조회

File:
`api/경기도-버스노선-swagger.json`

Source page:
https://www.data.go.kr/data/15080662/openapi.do

Extracted from inline `swaggerJson` in the saved HTML page.

## 경기도_버스도착정보 조회

File:
`api/경기도-버스도착정보-swagger.json`

Source page:
https://www.data.go.kr/data/15080346/openapi.do

Extracted from inline `swaggerJson` in the saved HTML page.

## 서울특별시_노선정보조회 서비스

File:
`api/서울-버스노선-api-spec.json`

Source page:
https://www.data.go.kr/data/15000193/openapi.do

The source page does not provide Swagger JSON. This project-owned Swagger 2.0
specification was generated from the request and response tables for all four
detailed functions on the source page. The filename intentionally uses
`api-spec` instead of `swagger` because this is not a provider-supplied Swagger
document.

## 서울특별시_버스도착정보조회 서비스

File:
`api/서울-버스도착정보-api-spec.json`

Source page:
https://www.data.go.kr/data/15000314/openapi.do

The source page does not provide Swagger JSON. This project-owned Swagger 2.0
specification was generated from the request and response tables for all four
detailed functions on the source page. The filename intentionally uses
`api-spec` instead of `swagger` because this is not a provider-supplied Swagger
document.
