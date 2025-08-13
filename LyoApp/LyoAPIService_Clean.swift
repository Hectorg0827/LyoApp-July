// LyoAPIService_Clean.swift
import Foundation

class LyoAPIService_Clean: ObservableObject {
    static let shared = LyoAPIService_Clean()
    
    private init() {}
    
    func fetchData() async -> Bool {
        return true
    }
}
