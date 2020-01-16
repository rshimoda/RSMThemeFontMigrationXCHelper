//
//  Patterns.swift
//  RSMThemeFont Migration Helper Extension
//
//  Created by Sergi on 16/01/2020.
//  Copyright © 2020 Readdle. All rights reserved.
//

import Foundation

enum FontType: String {
    case light = "lighApp"
    case lightItalic = "lightItalicApp"
    case thin = "thinApp"
    case thinItalic = "thinItalic"
    case regular = "app"
    case regularItalic = "italicApp"
    case medium = "mediumApp"
    case mediumItalic = "italicMediumApp"
    case semibold = "semiboldApp"
    case semiboldItalic = "italicSemiboldApp"
    case bold = "boldApp"
    case boldItalic = "italicBoldApp"
    case heavy = "heavyApp"
    case heavyItalic = "italicHevyApp"
    case black = "blackApp"
    case blackItalic = "italicBlackApp"

    var isItalic: Bool {
        return self == .lightItalic || self == .thinItalic || self == .regularItalic || self == .mediumItalic || self == .semiboldItalic || self == .boldItalic || self == .blackItalic
    }

    var weight: String {
        switch self {
        case .light, .lightItalic:
            return "NSUIFontWeightLight"
        case .thin, .thinItalic:
            return "NSUIFontWeightThin"
        case .regular, .regularItalic:
            return "NSUIFontWeightRegular"
        case .medium, .mediumItalic:
            return "NSUIFontWeightMedium"
        case .semibold, .semiboldItalic:
            return "NSUIFontWeightSemibold"
        case .bold, .boldItalic:
            return "NSUIFontWeightBold"
        case .heavy, .heavyItalic:
            return "NSUIFontWeightHeavy"
        case .black, .blackItalic:
            return "NSUIFontWeightBlack"
        }
    }

    static var values: [FontType] {
        return [
                .light,
                .lightItalic,
                .thin,
                .thinItalic,
                .regular,
                .regularItalic,
                .medium,
                .mediumItalic,
                .semibold,
                .semiboldItalic,
                .bold,
                .boldItalic,
                .heavy,
                .heavyItalic,
                .black,
                .blackItalic
        ]
    }
}

enum FontScaling {
    case scalable
    case unscalable
    case notSpecified
}

// MARK: -

typealias FontDeclarationPatterns = (legacy: String, new: String)

func fontDeclarationPatterns(for fontType: FontType, scaling: FontScaling = .notSpecified) -> FontDeclarationPatterns  {
    return (legacyFontDeclarationPattern(for: fontType), newFontDeclarationPattern(for: fontType, scaling: scaling))
}

// MARK: -

let legacyFontDeclarationCommonPattern = #"""
\[
RSMTheme
\s
<REPLACE_WITH_FONT_TYPE>
FontOfSize:
(\d*\.?\d*f?)
\]
"""#

let newFontDeclarationCommonPattern = #"""
\[\[RSMThemeFont alloc\] initWithSize:$1 weight:<REPLACE_WITH_FONT_WEIGTH><REPLACE_WITH_IS_ITALIC>\]<REPLACE_WITH_SCALING>
"""#

func legacyFontDeclarationPattern(for fontType: FontType) -> String {
    return legacyFontDeclarationCommonPattern.replacingOccurrences(of: "\n", with: "")
                                             .replacingOccurrences(of: "<REPLACE_WITH_FONT_TYPE>", with: fontType.rawValue)
}

func newFontDeclarationPattern(for fontType: FontType, scaling: FontScaling = .notSpecified) -> String {
    let scalingString: String

    switch scaling {
    case .scalable:
        scalingString = ".scalable"
    case .unscalable:
        scalingString = ".unscalable"
    case .notSpecified:
        scalingString = ""
    }

    return newFontDeclarationCommonPattern.replacingOccurrences(of: "\n", with: "")
                                          .replacingOccurrences(of: "<REPLACE_WITH_FONT_WEIGTH>", with: fontType.weight)
                                          .replacingOccurrences(of: "<REPLACE_WITH_IS_ITALIC>", with: fontType.isItalic ? " isItalic:YES" : "")
                                          .replacingOccurrences(of: "<REPLACE_WITH_SCALING>", with: scalingString)
}
