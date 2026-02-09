//
//  slFaceLandmark.swift
//  ShipSwift
//
//  面部地标数据模型
//  支持 Vision 框架的 11 种面部区域类型
//

import Foundation

/// 面部地标区域类型
enum slFaceLandmarkRegion: String, Sendable {
    case faceContour
    case leftEye, rightEye
    case leftEyebrow, rightEyebrow
    case nose, noseCrest
    case outerLips, innerLips
    case leftPupil, rightPupil
}

/// 单个面部地标组
struct slFaceLandmarkGroup: Sendable {
    let region: slFaceLandmarkRegion
    let points: [CGPoint]
    /// 是否闭合路径（瞳孔等单点区域不闭合）
    var isClosed: Bool { points.count > 2 }
}
