import Foundation

// MARK: - Validation Helper
struct ValidationHelper {
    
    // MARK: - Email Validation
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Password Validation
    static func isValidPassword(_ password: String) -> PasswordValidationResult {
        var errors: [String] = []
        
        if password.count < 8 {
            errors.append("Password must be at least 8 characters long")
        }
        
        if password.count > 128 {
            errors.append("Password must be less than 128 characters long")
        }
        
        if !password.contains(where: { $0.isLowercase }) {
            errors.append("Password must contain at least one lowercase letter")
        }
        
        if !password.contains(where: { $0.isUppercase }) {
            errors.append("Password must contain at least one uppercase letter")
        }
        
        if !password.contains(where: { $0.isNumber }) {
            errors.append("Password must contain at least one number")
        }
        
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        if password.rangeOfCharacter(from: specialCharacters) == nil {
            errors.append("Password must contain at least one special character")
        }
        
        return PasswordValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Username Validation
    static func isValidUsername(_ username: String) -> ValidationResult {
        var errors: [String] = []
        
        if username.isEmpty {
            errors.append("Username is required")
        } else if username.count < 3 {
            errors.append("Username must be at least 3 characters long")
        } else if username.count > 30 {
            errors.append("Username must be less than 30 characters long")
        }
        
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_.-"))
        if username.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            errors.append("Username can only contain letters, numbers, underscores, dots, and hyphens")
        }
        
        if username.hasPrefix(".") || username.hasSuffix(".") {
            errors.append("Username cannot start or end with a dot")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Full Name Validation
    static func isValidFullName(_ fullName: String) -> ValidationResult {
        var errors: [String] = []
        
        if fullName.isEmpty {
            errors.append("Full name is required")
        } else if fullName.count < 2 {
            errors.append("Full name must be at least 2 characters long")
        } else if fullName.count > 100 {
            errors.append("Full name must be less than 100 characters long")
        }
        
        let allowedCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: " '-"))
        if fullName.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            errors.append("Full name can only contain letters, spaces, apostrophes, and hyphens")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Phone Number Validation
    static func isValidPhoneNumber(_ phoneNumber: String) -> ValidationResult {
        var errors: [String] = []
        
        // Remove all non-digit characters for validation
        let digitsOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if digitsOnly.isEmpty {
            errors.append("Phone number is required")
        } else if digitsOnly.count < 10 {
            errors.append("Phone number must be at least 10 digits long")
        } else if digitsOnly.count > 15 {
            errors.append("Phone number must be less than 15 digits long")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - URL Validation
    static func isValidURL(_ urlString: String) -> ValidationResult {
        var errors: [String] = []
        
        if urlString.isEmpty {
            errors.append("URL is required")
        } else if URL(string: urlString) == nil {
            errors.append("Please enter a valid URL")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Content Validation
    static func isValidPostContent(_ content: String) -> ValidationResult {
        var errors: [String] = []
        
        if content.isEmpty {
            errors.append("Post content cannot be empty")
        } else if content.count > 2000 {
            errors.append("Post content must be less than 2000 characters")
        }
        
        // Check for inappropriate content (basic check)
        let inappropriateWords = ["spam", "fake", "scam"] // In production, use a more comprehensive list
        for word in inappropriateWords {
            if content.lowercased().contains(word) {
                errors.append("Content contains inappropriate language")
                break
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Bio Validation
    static func isValidBio(_ bio: String) -> ValidationResult {
        var errors: [String] = []
        
        if bio.count > 500 {
            errors.append("Bio must be less than 500 characters")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Age Validation
    static func isValidAge(_ age: Int) -> ValidationResult {
        var errors: [String] = []
        
        if age < 13 {
            errors.append("You must be at least 13 years old to use this app")
        } else if age > 120 {
            errors.append("Please enter a valid age")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Course Title Validation
    static func isValidCourseTitle(_ title: String) -> ValidationResult {
        var errors: [String] = []
        
        if title.isEmpty {
            errors.append("Course title is required")
        } else if title.count < 5 {
            errors.append("Course title must be at least 5 characters long")
        } else if title.count > 100 {
            errors.append("Course title must be less than 100 characters long")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Price Validation
    static func isValidPrice(_ price: Double) -> ValidationResult {
        var errors: [String] = []
        
        if price < 0 {
            errors.append("Price cannot be negative")
        } else if price > 9999.99 {
            errors.append("Price cannot exceed $9,999.99")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

// MARK: - Validation Result Types
struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    
    var firstError: String? {
        return errors.first
    }
    
    var allErrors: String {
        return errors.joined(separator: "\n")
    }
}

struct PasswordValidationResult {
    let isValid: Bool
    let errors: [String]
    
    var strength: PasswordStrength {
        let errorCount = errors.count
        switch errorCount {
        case 0:
            return .strong
        case 1...2:
            return .medium
        default:
            return .weak
        }
    }
    
    var firstError: String? {
        return errors.first
    }
    
    var allErrors: String {
        return errors.joined(separator: "\n")
    }
}

enum PasswordStrength: String, CaseIterable {
    case weak = "Weak"
    case medium = "Medium"
    case strong = "Strong"
    
    var color: Color {
        switch self {
        case .weak:
            return .red
        case .medium:
            return .orange
        case .strong:
            return .green
        }
    }
    
    var progress: Double {
        switch self {
        case .weak:
            return 0.33
        case .medium:
            return 0.66
        case .strong:
            return 1.0
        }
    }
}

// MARK: - Form Validation Extensions
extension ValidationHelper {
    static func validateRegistrationForm(
        username: String,
        email: String,
        fullName: String,
        password: String
    ) -> ValidationResult {
        var allErrors: [String] = []
        
        let usernameResult = isValidUsername(username)
        allErrors.append(contentsOf: usernameResult.errors)
        
        if !isValidEmail(email) {
            allErrors.append("Please enter a valid email address")
        }
        
        let nameResult = isValidFullName(fullName)
        allErrors.append(contentsOf: nameResult.errors)
        
        let passwordResult = isValidPassword(password)
        allErrors.append(contentsOf: passwordResult.errors)
        
        return ValidationResult(isValid: allErrors.isEmpty, errors: allErrors)
    }
    
    static func validateLoginForm(
        username: String,
        password: String
    ) -> ValidationResult {
        var errors: [String] = []
        
        if username.isEmpty {
            errors.append("Username or email is required")
        }
        
        if password.isEmpty {
            errors.append("Password is required")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

import SwiftUI
