//
//  DrawingTool.swift
//  Sahara
//
//  Created by 금가경 on 3/25/26.
//

import PencilKit
import UIKit

enum DrawingTool: CaseIterable {
    case pen
    case pencil
    case marker
    case fountainPen
    case watercolor
    case crayon
    case monoline
    case eraser
    case lasso

    var inkType: PKInkingTool.InkType? {
        switch self {
        case .pen:         return .pen
        case .pencil:      return .pencil
        case .marker:      return .marker
        case .fountainPen: return .fountainPen
        case .watercolor:  return .watercolor
        case .crayon:      return .crayon
        case .monoline:    return .monoline
        case .eraser:      return nil
        case .lasso:       return nil
        }
    }

    var iconName: String {
        switch self {
        case .pen:         return "pencil.tip"
        case .pencil:      return "pencil"
        case .marker:      return "highlighter"
        case .fountainPen: return "paintbrush.pointed"
        case .watercolor:  return "paintbrush"
        case .crayon:      return "scribble"
        case .monoline:    return "line.diagonal"
        case .eraser:      return "eraser"
        case .lasso:       return "lasso"
        }
    }

    var localizedName: String {
        switch self {
        case .pen:         return NSLocalizedString("media_editor.tool.pen", comment: "")
        case .pencil:      return NSLocalizedString("media_editor.tool.pencil", comment: "")
        case .marker:      return NSLocalizedString("media_editor.tool.marker", comment: "")
        case .fountainPen: return NSLocalizedString("media_editor.tool.fountain_pen", comment: "")
        case .watercolor:  return NSLocalizedString("media_editor.tool.watercolor", comment: "")
        case .crayon:      return NSLocalizedString("media_editor.tool.crayon", comment: "")
        case .monoline:    return NSLocalizedString("media_editor.tool.monoline", comment: "")
        case .eraser:      return NSLocalizedString("media_editor.tool.eraser", comment: "")
        case .lasso:       return NSLocalizedString("media_editor.tool.lasso", comment: "")
        }
    }

    func pkTool(color: UIColor, width: CGFloat) -> PKTool {
        switch self {
        case .lasso:
            return PKLassoTool()
        case .eraser:
            return PKEraserTool(.bitmap)
        default:
            return PKInkingTool(inkType!, color: color, width: width)
        }
    }
}
