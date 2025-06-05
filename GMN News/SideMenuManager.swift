//
//  SideMenuManager.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/17/25.
//

import SwiftUI

@MainActor
class SideMenuManager: ObservableObject {
    @Published var isOpen: Bool = false
    
    func toggle() {
        withAnimation(.easeInOut) {
            isOpen.toggle()
        }
    }
    
    func close() {
        withAnimation(.easeInOut) {
            isOpen = false
        }
    }
}
