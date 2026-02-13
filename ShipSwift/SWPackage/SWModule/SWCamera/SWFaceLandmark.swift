//
//  SWFaceLandmark.swift
//  ShipSwift
//
//  Face landmark data models for Vision framework regions.
//  Defines the enum of face landmark region types and a group model
//  that holds normalized coordinate points for each detected region.
//
//  Usage:
//    // 1. SWFaceLandmarkRegion enum cases:
//    //    .faceContour, .leftEye, .rightEye,
//    //    .leftEyebrow, .rightEyebrow,
//    //    .nose, .noseCrest,
//    //    .outerLips, .innerLips,
//    //    .leftPupil, .rightPupil
//
//    // 2. SWFaceLandmarkGroup model
//    let group = SWFaceLandmarkGroup(
//        region: .leftEye,
//        points: [CGPoint(x: 0.3, y: 0.4), CGPoint(x: 0.35, y: 0.42), ...]
//    )
//    group.region    // .leftEye
//    group.points    // [CGPoint] in normalized coordinates (0...1)
//    group.isClosed  // true if points.count > 2 (pupils are not closed)
//
//    // 3. Typically consumed from SWCameraManager.faceLandmarks
//    for group in cameraManager.faceLandmarks {
//        switch group.region {
//        case .outerLips: drawLips(group.points)
//        case .leftEye:   drawEye(group.points)
//        default: break
//        }
//    }
//
//  Created by Wei Zhong on 3/1/26.
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
