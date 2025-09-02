//
//  callaiApp.swift
//  callai
//
//  Created by Edward Harrison on 9/2/25.
//

import SwiftUI

@main
struct callaiApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
