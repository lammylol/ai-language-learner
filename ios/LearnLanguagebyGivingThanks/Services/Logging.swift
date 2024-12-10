//
//  Logging.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 12/8/24.
//

import Foundation
import OSLog

let NetworkingLogger = Logger(subsystem: "com.languagelearner.networking", category: "languagelearner.debugging" )
let ViewLogger = Logger(subsystem: "com.languagelearner.views", category: "languagelearner.debugging" )
let ModelLogger = Logger(subsystem: "com.languagelearner.models", category: "languagelearner.debugging" )
let NotificationLogger = Logger(subsystem: "com.languagelearner.notifications", category: "languagelearner.debugging" )
