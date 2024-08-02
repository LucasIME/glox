import gleam/option.{type Option}
import token_type.{type TokenType}

pub type Token(t) {
  Token(token_type: TokenType, lexeme: String, literal: Option(t), line: Int)
}
// fn to_string(token: Token(some)) -> String {
//   token.token_type <> " " <> token.lexeme <> " " <> token.literal
// }
