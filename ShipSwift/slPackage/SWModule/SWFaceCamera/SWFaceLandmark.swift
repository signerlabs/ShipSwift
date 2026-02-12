//
//  SWFaceLandmark.swift
//  ShipSwift
//
//  Face landmark data models
//  Supports 11 face region types from the Vision framework
//

import Foundation

/// Face landmark region type
enum SWFaceLandmarkRegion: String, Sendable {
    case faceContour
    case leftEye, rightEye
    case leftEyebrow, rightEyebrow
    case nose, noseCrest
    case outerLips, innerLips
    case leftPupil, rightPupil
}

/// Single face landmark group
struct SWFaceLandmarkGroup: Sendable {
    let region: SWFaceLandmarkRegion
    let points: [CGPoint]
    /// Whether the path is closed (single-point regions like pupils are not closed)
    var isClosed: Bool { points.count > 2 }
}
