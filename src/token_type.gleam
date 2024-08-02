pub type TokenType {
  // Single character tokens
  LeftParen
  RightParen
  LeftBrace
  RightBrace
  Comma
  Dot
  Minus
  Plus
  Semicolon
  Slash
  Star

  // One or two character tokens
  Bang
  BangEqual
  Equal
  EqualEqual
  Greater
  GreaterEqual
  Less
  LessEqual

  // Literals
  Identifier
  String
  Number

  // Keywords
  And
  Class
  Else
  FALSE
  Fun
  For
  If
  Nil
  Or
  Print
  Return
  Super
  This
  TRUE
  Var
  While

  Eof
}
