//
//  CipherContent.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit

public class CipherContent {
   private static let uppercaseAlphabetString = NSLocalizedString("A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z", comment: "Ciphertext uppercase alphabet as one string")
    private static let lowercaselphabetString = NSLocalizedString("a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z", comment: "Ciphertext lowercase alphabet as one string")
    public static let ciphertext = NSLocalizedString("HTSLWFYZQFYNTSX, XJJPJW! DTZ MFAJ UFXXJI YMJ KNWXY YJXY. KJB JAJW KNSI YMJ UFYM, FSI KJBJW XYNQQ BFQP ZUTS NY. QTTP YT ‘S’ YT HTSYNSZJ DTZW OTZWSJD. TUJS XJXFRJ.", comment: "Encrypted ciphertext string")
    public static let plaintext = NSLocalizedString("CONGRATULATIONS, SEEKER! YOU HAVE PASSED THE FIRST TEST. FEW EVER FIND THE PATH, AND FEWER STILL WALK UPON IT. LOOK TO ‘N’ TO CONTINUE YOUR JOURNEY. OPEN SESAME.", comment: "Decrypted message string")
    public static let decryptionKey = 5
    
    public static func shift(inputText: String?, by shift: Int) -> String {
        guard let inputText = inputText else { return "" }
        
        var shiftedString = ""
        for char in inputText {
            
            // Figure out if the letter is uppercase or lowercase.
            let alphabetLetterArray: [String]
            if uppercaseAlphabetString.contains(char) {
                alphabetLetterArray = uppercaseAlphabetString.components(separatedBy: "|")
            } else if lowercaselphabetString.contains(char) {
                alphabetLetterArray = lowercaselphabetString.components(separatedBy: "|")
            } else {
                // If the character isn’t in either array, AKA is a punctuation mark or symbol
                // Don’t shift anything.
                shiftedString += String(char)
                continue
            }
            
            // Otherwise it’s in one of the alphabets, so shift it.
            let currentSpot = alphabetLetterArray.index(of: String(char))
            var newSpot = (currentSpot! + shift) % alphabetLetterArray.count
            
            // Modulo it if we’ve gone negative.
            if newSpot < 0 {
                newSpot = newSpot + alphabetLetterArray.count
            }
            
            shiftedString += alphabetLetterArray[newSpot]
        }
        // And return the shifted value.
        return shiftedString
    }
}
