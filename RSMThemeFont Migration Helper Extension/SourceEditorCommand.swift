//
//  SourceEditorCommand.swift
//  RSMThemeFont Migration Helper Extension
//
//  Created by Sergi on 14/01/2020.
//  Copyright © 2020 Readdle. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {

    // MARK: - Definitions

    public class var name: String {
        return self.className()
    }
    
    public class var identifier: String {
        let bundleIdentifiler = Bundle.main.bundleIdentifier!
        return bundleIdentifiler + "." + name.replacingOccurrences(of: " ", with: "-")
    }

    public class var commandDefinition: [XCSourceEditorCommandDefinitionKey: Any] {
        return [
            XCSourceEditorCommandDefinitionKey(rawValue: "XCSourceEditorCommandName"): name,
            XCSourceEditorCommandDefinitionKey(rawValue: "XCSourceEditorCommandClassName"): className(),
            XCSourceEditorCommandDefinitionKey(rawValue: "XCSourceEditorCommandIdentifier"): identifier
        ]
    }
    
    // MARK: - Errors
    
    enum RSMThemeFontMigrationError: Error {
        case invalidFileType
        case invalidFileFormat
        case noSelection
    }
    
    // MARK: - Status
    
    enum CommandStatus {
        case ok
        case error
    }
    
    var status: CommandStatus = .ok
    
    // MARK: -
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {

        // Check file type

        let isObjectiveCFile = invocation.buffer.contentUTI.contains("objective")
        let isSwiftFile = invocation.buffer.contentUTI.contains("swift")
        
        guard isObjectiveCFile || isSwiftFile else {
            completionHandler(RSMThemeFontMigrationError.invalidFileType)
            status = .error
            return
        }

        guard let lines = invocation.buffer.lines as? [String] else {
            completionHandler(RSMThemeFontMigrationError.invalidFileFormat)
            status = .error
            return
        }

        // Insert Swift header if needed

        if isObjectiveCFile {
            let swiftHeaderImport = #"#import "Spark-Swift.h""#

            let shouldInsertUpperBlankLine: Bool
            let shouldInsertLowerBlankLine: Bool

            if invocation.buffer.completeBuffer.contains(swiftHeaderImport) == false {
                let indexToInsert: Int

                if let lastImportLine = lines.lastIndex(where: { $0.contains("#import") }) {
                    indexToInsert = lastImportLine + 1

                    shouldInsertUpperBlankLine = true
                    shouldInsertLowerBlankLine = lines[lastImportLine + 1].isBlankLine == false
                }
                else if let firstPreprocessorDirectiveLine = lines.firstIndex(where: { $0.hasPrefix("#") }) {
                    indexToInsert = max(0, firstPreprocessorDirectiveLine)

                    shouldInsertUpperBlankLine = false
                    shouldInsertLowerBlankLine = true
                }
                else if let firstObjectiveCSpecificLine = lines.firstIndex(where: { $0.hasPrefix("@") }) {
                    indexToInsert = max(0, firstObjectiveCSpecificLine)

                    shouldInsertUpperBlankLine = false
                    shouldInsertLowerBlankLine = true
                }
                else if let lastDocumentationLine = lines.lastIndex(where: { $0 == "//\n" }) {
                    indexToInsert = lastDocumentationLine + 1

                    shouldInsertUpperBlankLine = true
                    shouldInsertLowerBlankLine = lines[lastDocumentationLine + 1].isBlankLine == false
                }
                else {
                    indexToInsert = 0

                    shouldInsertUpperBlankLine = false
                    shouldInsertLowerBlankLine = true
                }

                if shouldInsertLowerBlankLine {
                    invocation.buffer.lines.insert("", at: indexToInsert)
                }

                invocation.buffer.lines.insert(swiftHeaderImport, at: indexToInsert)

                if shouldInsertUpperBlankLine {
                    invocation.buffer.lines.insert("", at: indexToInsert)
                }
            }
        }
    }
}

// MARK: -
// MARK: -
// MARK: Commands

final class ConvertSelectionCommand: SourceEditorCommand {
    override class var name: String {
        return "Convert Font Declarations at Current Line"
    }

    override func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        super.perform(with: invocation, completionHandler: completionHandler)

        guard status == .ok else {
            return
        }

        guard let selections = invocation.buffer.selections as? [XCSourceTextRange] else {
            completionHandler(RSMThemeFontMigrationError.noSelection)
            return
        }

        for selection in selections {
            guard var line = invocation.buffer.lines[selection.start.line] as? NSString else {
                continue
            }


            FontType.values.forEach {
                let patterns = fontDeclarationPatterns(for: $0, scaling: .notSpecified)

                let updatedLine = line.replacingOccurrences(of: patterns.legacy, with: patterns.new, options: [.regularExpression], range: NSMakeRange(0, line.length)) as NSString

                    line = updatedLine
            }

            invocation.buffer.lines[selection.start.line] = line
        }

        completionHandler(nil)
    }
}

final class ConvertAllMatchesCommand: SourceEditorCommand {
    override class var name: String {
        return "Convert Font Declarations in Current File"
    }

    override func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        super.perform(with: invocation, completionHandler: completionHandler)

        guard status == .ok else {
            return
        }

        var updatedCompleteBuffer = invocation.buffer.completeBuffer as NSString

        FontType.values.forEach {
            let patterns = fontDeclarationPatterns(for: $0, scaling: .notSpecified)

            let updatedBuffer = updatedCompleteBuffer.replacingOccurrences(of: patterns.legacy, with: patterns.new, options: [.regularExpression], range: NSMakeRange(0, updatedCompleteBuffer.length)) as NSString

            updatedCompleteBuffer = updatedBuffer
        }

        invocation.buffer.completeBuffer = updatedCompleteBuffer as String

        completionHandler(nil)
    }
}

extension String {
    var isBlankLine: Bool {
        return self.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "").replacingOccurrences(of: "\n", with: "").isEmpty
    }
}
