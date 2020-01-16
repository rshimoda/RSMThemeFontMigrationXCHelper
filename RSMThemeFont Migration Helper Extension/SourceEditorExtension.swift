//
//  SourceEditorExtension.swift
//  RSMThemeFont Migration Helper Extension
//
//  Created by Sergi on 14/01/2020.
//  Copyright © 2020 Readdle. All rights reserved.
//

import Foundation
import XcodeKit
import os.log

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    
    func extensionDidFinishLaunching() {
        os_log(.debug, "Extension Ready")
    }
    
    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        return [ConvertSelectionCommand.commandDefinition, ConvertAllMatchesCommand.commandDefinition]
    }
    
}
