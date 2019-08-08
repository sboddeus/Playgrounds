var escape: String = ""
func foo(number: Int) {
    if number % 2 == 0 {
        defer {
            escape += "1"
            print("1")
        }
        escape += "2"
        print("2")
    } else {
        escape += "3"
        print("3")
    }
    escape += "4"
    print("4")
}

foo(number: 4)
print(escape)

// DEFER is scope based
