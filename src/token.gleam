import gleam/option.{type Option}
import token_type.{type TokenType}

pub type TokenLiteral {
  NumberLiteral(float: Float)
  StringLiteral(string: String)
}

pub type Token {
  Token(
    token_type: TokenType,
    lexeme: String,
    literal: Option(TokenLiteral),
    line: Int,
  )
}
// fn to_string(token: Token(some)) -> String {
//   token.token_type <> " " <> token.lexeme <> " " <> token.literal
// }
