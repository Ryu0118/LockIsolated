import SwiftSyntax

extension AttributeSyntax {
    static var objc = AttributeSyntax(atSignToken: .atSignToken(), attributeName: TypeSyntax(stringLiteral: "objc"))
}
