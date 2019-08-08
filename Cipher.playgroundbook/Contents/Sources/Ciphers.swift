//
//  Ciphers.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit

public class Ciphers {
    
    // MARK: - Public
    
    public static let cipherTwoPlaintext = NSLocalizedString("WELCOME TO CIPHER! YOU ARE PERSISTENT INDEED, PUZZLE SOLVER. YOU HAVE PROVEN YOURSELF WORTHY TO JOIN OUR RANKS. WE ARE A SECRET ORGANIZATION DEDICATED TO SOLVING MYSTERIES AND TO SECRET COMMUNICATION. WHEN WE SENSE THAT YOU ARE READY FOR YOUR FIRST QUEST, WE WILL FIND YOU.", comment: "Cipher 2 plaintext")
    
    public static let uppercaseAlphabet = NSLocalizedString("ABCDEFGHIJKLMNOPQRSTUVWXYZ", comment: "Uppercase alphabet")
    public static let lowercaseAlphabet = NSLocalizedString("abcdefghijklmnopqrstuvwxyz", comment: "lowercase alphabet")
    
    public static let cipherTwoKey = NSLocalizedString("OBSCURE", comment: "Cipher 2 key")
    public static let cipherTwoKeyShuffled = NSLocalizedString("BCESROU", comment: "Cipher 2 key shuffled")
    
    // MARK: Cipher Types
    
    /// An enumeration of the different types of cipher.
    ///
    /// - localizationKey: CipherType
    public enum CipherType: String {
        case none
        case substitution
        case polybius
        case bacon
        case vigenere
        case playfair
        case caesar
        
        var name: String {
            switch self {
            case .none: return NSLocalizedString("No Cipher", comment: "CipherType None")
            case .substitution: return NSLocalizedString("Keyed Substitution Cipher", comment: "CipherType Keyed Substitution")
            case .polybius: return NSLocalizedString("Polybius Square Cipher", comment: "CipherType Polybius Square")
            case .bacon: return NSLocalizedString("Bacon’s Cipher", comment: "CipherType Bacon’s Cipher")
            case .vigenere: return NSLocalizedString("Vigenère Cipher", comment: "CipherType Vigenère Cipher")
            case .playfair: return NSLocalizedString("Playfair Cipher", comment: "CipherType Playfair Cipher")
            case .caesar: return NSLocalizedString("Caesar Cipher", comment: "CipherType Caesar Cipher")
            }
        }
    }
    
    // MARK: Encryption and Decryption.
    
    /// Returns a string that has been encrypted using the specified cipher type.
    ///
    /// - Parameter cipher: The type of cipher to use for encryption.
    /// - Parameter plaintext: The string to be encrypted.
    /// - Parameter key: The encryption key to use.
    /// - Returns: The encrypted string.
    ///
    /// - localizationKey: encrypt(cipher:plaintext:key:)
    public static func encrypt(cipher: CipherType, plaintext: String, key: String) -> String  {
        switch cipher {
        case .none:
            return plaintext
        case .substitution:
            return encryptSimpleSubstitution(plaintext: plaintext, key: key)
        case .polybius:
            return encryptPolybius(plaintext: plaintext, key: key)
        case .bacon:
            return encryptBacon(plaintext: plaintext)
        case .vigenere:
            return encryptVigenère(plaintext: plaintext, key: key)
        case .playfair:
            return encryptPlayfair(plaintext: plaintext, key: key)
        case .caesar:
            return encryptCaesar(plaintext: plaintext, shift: key)
        }
    }
    
    /// Returns a string that has been decrypted using the specified cipher type.
    ///
    /// - Parameter cipher: The type of cipher to use for decryption.
    /// - Parameter ciphertext: The string to be decrypted.
    /// - Parameter key: The decryption key to use.
    /// - Returns: The decrypted string.
    ///
    /// - localizationKey: decrypt(cipher:ciphertext:key:)
    public static func decrypt(cipher: CipherType, ciphertext: String, key: String) -> String  {
        switch cipher {
        case .none:
            // return text as-is
            return ciphertext
        case .substitution:
            return decryptSimpleSubstitution(ciphertext: ciphertext, key: key)
        case .polybius:
            return decryptPolybius(ciphertext: ciphertext, key: key)
        case .bacon:
            return decryptBacon(ciphertext: ciphertext)
        case .vigenere:
            return decryptVigenère(ciphertext: ciphertext, key: key)
        case .playfair:
            return decryptPlayfair(ciphertext: ciphertext, key: key)
        case .caesar:
            return decryptCaesar(ciphertext: ciphertext, shift: key)
        }
    }
    
    // MARK: - Internal
    
    static let cipherTwoCiphertext = encrypt(cipher: .substitution, plaintext: cipherTwoPlaintext, key: cipherTwoKey)
    
    static func allCiphers() -> [CipherType] {
        return [.none, .substitution, .polybius, .bacon, .vigenere, .playfair, .caesar]
    }
    
    // Returns a key that has been uppercased, cleaned of whitespace and duplicate letters and truncated to maxLength.
    static func cleanedText(text: String, maxLength: Int = Int.max, allowableLetters: String? = nil, removeDuplicates: Bool = false) -> String {
        
        // Trim any whitespace.
        var cleanedText = text.uppercased().removingCharacters(in: .whitespacesAndNewlines)
        if cleanedText.isEmpty {
            return cleanedText
        }
        
        // Remove any diacritics.
        cleanedText = cleanedText.removingDiacritics()
        
        // Remove any duplicate letters.
        if removeDuplicates {
            cleanedText = cleanedText.removingDuplicateLetters()
        }
        
        // Remove any letters that aren’t in allowableLetters.
        if let allowableLetters = allowableLetters {
            let disallowedCharacters = CharacterSet(charactersIn: allowableLetters).inverted
            cleanedText = cleanedText.removingCharacters(in: disallowedCharacters)
        }
        
        // Truncate to a maximum of letters
        let index = cleanedText.index(cleanedText.startIndex, offsetBy: min(maxLength, cleanedText.letters.count))
        return String(cleanedText[..<index])
    }
    
    // Returns an alphabet which has been deranged by the insertion of a key at
    // the beginning, and the removal of any letters in the key from the alphabet.
    // e.g. alphabet     : ABCDEFGHIJKLMNOPQRSTUVWXYZ
    //      key          : CIPHER
    //      keyedAlphabet: CIPHERABDFGJKLMNOQSTUVWXYZ
    // Any duplicate letters in the key are removed first:
    // e.g. alphabet     : ABCDEFGHIJKLMNOPQRSTUVWXYZ
    //      key          : APPLE
    //      keyedAlphabet: APLEBCDFGHIJKMNOQRSTUVWXYZ
    static func getKeyedAlphabet(from alphabet: String, with key: String) -> String {
        
        var reducedAlphabet = alphabet
        
        // Extract unique letters from the key
        let uniqueLettersInKey = key.letters.unique()
        
        // Remove all letters in the key
        for letter in uniqueLettersInKey {
            reducedAlphabet = reducedAlphabet.replacingOccurrences(of: letter, with: "")
        }
        
        // Prepend the key
        return uniqueLettersInKey.joined() + reducedAlphabet
    }
    
    static let maxLettersInWord = 32
    static let minLettersInKey = 4
    static let maxLettersInKey = 12
    
    static let plainTextColor = #colorLiteral(red: 0, green: 0.6, blue: 0.6, alpha: 1)
    static let cipherTextColor = #colorLiteral(red: 0, green: 0.4, blue: 0, alpha: 1)
    static let keyColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
    
    // MARK: - Private
    
    private static let baconCipherLetters = "AB".letters
    private static let polybiusSquareSize = 6
    private static let playfairSquareSize = 5
    
    // MARK: Supporting functions
    
    // Returns an alphabet as an n x n array of letters.
    private static func alphabetSquare(alphabet: String, n: Int) -> [[String]] {
        
        // Place the keyed alphabet in n x n grid
        var grid = [[String]]()
        var i = 0
        for _ in 0..<n {
            var gridRow = [String]()
            for _ in 0..<n {
                gridRow.append(i < alphabet.letters.count ? alphabet.letters[i] : "*")
                i += 1
            }
            grid.append(gridRow)
        }
        
        return grid
    }
    
    // MARK: Simple Substitution
    
    private static func encryptSimpleSubstitution(plaintext: String, key: String) -> String  {
        
        let keyedAlphabet = getKeyedAlphabet(from: uppercaseAlphabet, with: key)
        
        return plaintext.monoalphabeticallySubstituting(alphabet: keyedAlphabet.letters, for: uppercaseAlphabet.letters)
    }
    
    private static func decryptSimpleSubstitution(ciphertext: String, key: String) -> String  {
        
        let keyedAlphabet = getKeyedAlphabet(from: uppercaseAlphabet, with: key)
        
        return ciphertext.monoalphabeticallySubstituting(alphabet: uppercaseAlphabet.letters, for: keyedAlphabet.letters)
    }
    
    // MARK: Polybius
    
    // Returns a keyed alphabet as a 6 x 6 array of letters.
    private static func polybiusSquare(key: String) -> [[String]] {
        
        let extendedAlphabet = uppercaseAlphabet + "0123456789"
        
        let keyedAlphabet = getKeyedAlphabet(from: extendedAlphabet, with: key)

        return alphabetSquare(alphabet: keyedAlphabet, n: polybiusSquareSize)
    }
    
    private static func encryptPolybius(plaintext: String, key: String) -> String  {
        
        let grid = polybiusSquare(key: key)
        
        var encryptedText = ""
    
        for letter in plaintext.letters {
            
            var encodedLetter = letter
            
            // Find the letter in the grid and replace it with its coordinates
            for row in 0..<polybiusSquareSize {
                for column in 0..<polybiusSquareSize {
                    if letter == grid[row][column] {
                        encodedLetter = "\(row)\(column)"
                        break
                    }
                }
                if encodedLetter != letter {
                    break
                }
            }
            encryptedText += encodedLetter
        }
        
        return encryptedText
    }
    
    private static func decryptPolybius(ciphertext: String, key: String) -> String  {
        
        let grid = polybiusSquare(key: key)
        let gridSize = grid.count
        
        let numerals = Set("0123456789".letters)
        
        var decryptedText = ""
        var coordinates = [Int]()
        
        // Take each pair of digits and use them (row, column) to locate the decoded letter in the grid.
        for letter in ciphertext.letters {
            
            var decodedLetter = letter
            
            if numerals.contains(letter), let numeral = Int(letter) {
                coordinates.append(numeral)
                guard coordinates.count == 2 else { continue }
                if coordinates[0] < gridSize, coordinates[1] < gridSize {
                    decodedLetter = grid[coordinates[0]][coordinates[1]]
                } else {
                    decodedLetter = "?"
                }
            
                coordinates = []
            }
            
            decryptedText += decodedLetter
        }
        
        return decryptedText
    }
    
    // MARK: Bacon
    
    // Generate substitution letter sequences (rashers e.g. ‘AABABA’) for each letter in alphabet.
    private static func baconRashers(for alphabet: String) -> [String] {
    
        var rashers = [String]()
        
        let maxLength = String(alphabet.letters.count - 1, radix: 2).letters.count
    
        for i in 0..<alphabet.letters.count {
            var rasher = String(i, radix: 2).leftPadding(toLength: maxLength, withPad: "0")
            rasher = rasher.replacingOccurrences(of: "0", with: baconCipherLetters[0])
            rasher = rasher.replacingOccurrences(of: "1", with: baconCipherLetters[1])
            rashers.append(rasher)
        }
    
        return rashers
    }
    
    private static func encryptBacon(plaintext: String) -> String  {
        
        let alphabet = uppercaseAlphabet
        let baconRashers = self.baconRashers(for: alphabet)
        
        return plaintext.monoalphabeticallySubstituting(alphabet: baconRashers, for: alphabet.letters)
    }
    
    private static func decryptBacon(ciphertext: String) -> String  {
        
        var decryptedText = ""
        
        let alphabet = uppercaseAlphabet
        let rashers = baconRashers(for: alphabet)
        let rasherLength = rashers.first?.letters.count ?? 4
        
        let baconLetters = Set(baconCipherLetters)
        
        var rasher = ""
        
        for letter in ciphertext.letters {
            
            var decodedLetter = letter
            
            if baconLetters.contains(letter) {
                
                rasher.append(letter)
                
                guard rasher.letters.count == rasherLength else { continue }
                
                // Lookup rasher and get corresponding letter in alphabet
                if let index = rashers.index(of: rasher), index < alphabet.letters.count {
                    decodedLetter = alphabet.letters[index]
                }
                
                rasher = ""
            }
            
            decryptedText += decodedLetter
        }
        
        return decryptedText
    }
    
    // MARK: Vigenère
    
    private static func encryptVigenère(plaintext: String, key: String) -> String  {
        
        var cipherText = ""
        
        let alphabetLetters = uppercaseAlphabet.letters
        let keyLetters = key.letters
        
        guard keyLetters.count > 0 else { return "" }
        
        for (i, letter) in plaintext.letters.enumerated() {
            
            let keyLetter = keyLetters[i % keyLetters.count]
            
            guard let rowIndex = alphabetLetters.index(of: keyLetter),
                let colIndex = alphabetLetters.index(of: letter)
                else {
                    cipherText.append(letter)
                    continue
            }
            
            let cipherIndex = (colIndex + rowIndex) % alphabetLetters.count
            
            cipherText.append(alphabetLetters[cipherIndex])
        }

        return cipherText
    }
    
    private static func decryptVigenère(ciphertext: String, key: String) -> String  {
        
        var plainText = ""
        
        let alphabetLetters = uppercaseAlphabet.letters
        let keyLetters = key.letters
        
        for (i, cipherLetter) in ciphertext.letters.enumerated() {
            
            let keyLetter = keyLetters[i % keyLetters.count]
            
            guard let rowIndex = alphabetLetters.index(of: keyLetter) else { continue }
            
            let rowLetters = alphabetLetters.shiftedRight(by: alphabetLetters.count - rowIndex)
            
            guard let colIndex = rowLetters.index(of: cipherLetter) else {
                
                plainText.append(cipherLetter)
                continue
            }
            
            plainText.append(alphabetLetters[colIndex])
        }
        
        return plainText
    }
    
    // MARK: Playfair
    
    // Returns a keyed alphabet as a 5 x 5 array of letters.
    private static func playfairSquare(key: String) -> [[String]] {
        
        let jLessAlphabet = uppercaseAlphabet.replacingOccurrences(of: "J", with: "")
        
        let keyedAlphabet = getKeyedAlphabet(from: jLessAlphabet, with: key)

        return alphabetSquare(alphabet: keyedAlphabet, n: playfairSquareSize)
    }
    
    private static func find(_ letter: String, in grid: [[String]]) -> (row: Int, column: Int)? {
        
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                if letter == grid[row][col] {
                    return (row, col)
                }
            }
        }
        return nil
    }
    
    private static func encryptPlayfair(plaintext: String, key: String) -> String  {
        
        let keySquare = playfairSquare(key: key)
        let keySquareSize = keySquare.count
        
        // Remove anything not in the alphabet
        let nonAlphabetic = CharacterSet(charactersIn: uppercaseAlphabet).inverted
        var cleanedText = plaintext.removingCharacters(in: nonAlphabetic)
        
        // Ensure even number of letters
        cleanedText += (cleanedText.letters.count % 2) == 1 ? "X" : ""
        
        var encryptedText = ""
        
        // Loop through the text in 2-letter digrams.
        for digram in cleanedText.digrams() {
            
            var encodedDigram = ""
            
            // If second letter is the same, replace it with X
            let letterA = digram[0]
            let letterB = (digram[1] == letterA) ? "X" : digram[1]
            
            if
                let location1 = find(letterA, in: keySquare),
                let location2 = find(letterB, in: keySquare) {
                
                if location1.row == location2.row {
                    
                    // Same row => replace with next letter in row (wraparound)
                    encodedDigram += keySquare[location1.row][(location1.column + 1) % keySquareSize]
                    encodedDigram += keySquare[location2.row][(location2.column + 1) % keySquareSize]
                    
                } else if location1.column == location2.column {
                    
                    // Same column => replace with next letter in column (wraparound)
                    encodedDigram += keySquare[(location1.row + 1) % keySquareSize][location1.column]
                    encodedDigram += keySquare[(location2.row + 1) % keySquareSize][location2.column]
                    
                } else {
                    // Different row and column => same row and swap column
                    encodedDigram += keySquare[location1.row][location2.column]
                    encodedDigram += keySquare[location2.row][location1.column]
                    
                }
            } else {
                // Should never get in here.
                print("Can’t find digram \(digram) in keySquare")
            }
            
            encryptedText += encodedDigram
        }
        
        return encryptedText
    }
    
    private static func decryptPlayfair(ciphertext: String, key: String) -> String  {
        
        let keySquare = playfairSquare(key: key)
        let keySquareSize = keySquare.count
        
        // Remove anything not in the alphabet
        let nonAlphabetic = CharacterSet(charactersIn: uppercaseAlphabet).inverted
        var cleanedCiphertext = ciphertext.removingCharacters(in: nonAlphabetic)
        
        // Ensure even number of letters
        cleanedCiphertext += (cleanedCiphertext.letters.count % 2) == 1 ? "X" : ""
        
        var decryptedText = ""
        
        // Loop through the text in 2-letter digrams.
        for digram in cleanedCiphertext.digrams() {
            
            var decodedDigram = ""
            
            // If second letter is the same, replace it with X
            let letterA = digram[0]
            let letterB = (digram[1] == letterA) ? "X" : digram[1]
            
            if
                let location1 = find(letterA, in: keySquare),
                let location2 = find(letterB, in: keySquare) {
                
                if location1.row == location2.row {
                    
                    // Same row => replace with previous letter in row (wraparound)
                    decodedDigram += keySquare[location1.row][(location1.column > 0) ? (location1.column - 1) : (keySquareSize - 1)]
                    decodedDigram += keySquare[location2.row][(location2.column > 0) ? (location2.column - 1) : (keySquareSize - 1)]
                    
                } else if location1.column == location2.column {
                    
                    // Same column => replace with previous letter in column (wraparound)
                    decodedDigram += keySquare[(location1.row > 0) ? (location1.row - 1) : (keySquareSize - 1)][location1.column]
                    decodedDigram += keySquare[(location2.row > 0) ? (location2.row - 1) : (keySquareSize - 1)][location2.column]
                    
                } else {
                    // Different row and column => same row and swap column
                    decodedDigram += keySquare[location1.row][location2.column]
                    decodedDigram += keySquare[location2.row][location1.column]
                    
                }
            } else {
                // Should never get in here.
                print("Can’t find digram \(digram) in keySquare")
            }
            
            decryptedText += decodedDigram
        }
        
        return decryptedText
    }
    
    // MARK: Caesar
    
    private static func encryptCaesar(plaintext: String, shift: String) -> String {
        if let shift = Int(shift) {
            // Encrypt
            return caesarShift(plaintext, by: shift)
        } else if shift.count == 0 || (shift.count == 1 && shift.contains("-")) {
            return plaintext
        } else {
            return plaintext
        }
    }
    
    private static func decryptCaesar(ciphertext: String, shift: String) -> String  {
        if let shift = Int(shift) {
            // Decrypt
            return caesarShift(ciphertext, by: (shift * -1))
        } else if shift.count == 0 || (shift.count == 1 && shift.contains("-")) {
            return ciphertext
        } else {
            return ciphertext
        }
    }
    
    private static func caesarShift(_ text: String, by shift: Int) -> String {
        
        var shiftedString = ""
        let alphabeticCharacters = uppercaseAlphabet + lowercaseAlphabet
        
        for character in text {
            
            var shiftedCharacter = String(character)
            
            if alphabeticCharacters.contains(character) {
                
                let alphabet: [String]
                if lowercaseAlphabet.contains(character) {
                    alphabet = lowercaseAlphabet.letters
                } else {
                    alphabet = uppercaseAlphabet.letters
                }
                
                if let index = alphabet.index(of: String(character)) {
                    var newIndex = (index + shift) % alphabet.count
                    newIndex += (newIndex < 0) ? alphabet.count : 0
                    shiftedCharacter = alphabet[newIndex]
                }
            }
            
            shiftedString += shiftedCharacter
        }
        return shiftedString
    }
}   
