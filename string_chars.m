function [out_char] = string_chars(input,length,fill_char)
%STRING_CHARS Generates a character array with a fixed determined length.
%If the input is longer, it is trimmed, if it is shorter, it is filled with
%a filler char.
%   INPUT:
%   input: Input character array
%   length: Desired length of the output character array
%   fill_char: Filler char
%
%   OUTPUT:
%   out_char: Output character array
%
% (L. Ramírez, abril 2013)

if numel(input) < length
    filling(1:(length-numel(input))) = fill_char;
    out_char = [input filling];
else
    out_char = input(1:length);
end
