import file_streams/file_stream
import gleam/bit_array
import gleeunit
import gleeunit/should
import glox.{run}

pub fn main() {
  gleeunit.main()
}

pub fn can_handle_classes_and_methods_test() {
  let path = "test/resources/class_and_method.lox"
  let assert Ok(stream) = file_stream.open_read(path)
  let assert Ok(byte_content) = stream |> file_stream.read_remaining_bytes()
  let assert Ok(string_content) = byte_content |> bit_array.to_string

  let interpreter_result = run(string_content)
  interpreter_result |> should.be_ok()
}

pub fn can_handle_empty_files_test() {
  let path = "test/resources/empty_file.lox"
  let assert Ok(stream) = file_stream.open_read(path)
  let assert Ok(byte_content) = stream |> file_stream.read_remaining_bytes()
  let assert Ok(string_content) = byte_content |> bit_array.to_string

  let interpreter_result = run(string_content)
  interpreter_result |> should.be_ok()
}

pub fn can_handle_multiline_string_test() {
  let path = "test/resources/multiline.lox"
  let assert Ok(stream) = file_stream.open_read(path)
  let assert Ok(byte_content) = stream |> file_stream.read_remaining_bytes()
  let assert Ok(string_content) = byte_content |> bit_array.to_string

  let interpreter_result = run(string_content)
  interpreter_result |> should.be_ok()
}

pub fn breaks_on_unexpected_char_test() {
  let path = "test/resources/unexpected_character.lox"
  let assert Ok(stream) = file_stream.open_read(path)
  let assert Ok(byte_content) = stream |> file_stream.read_remaining_bytes()
  let assert Ok(string_content) = byte_content |> bit_array.to_string

  let interpreter_result = run(string_content)
  interpreter_result |> should.be_error()
}
